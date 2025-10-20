# Audio Streaming Fix - Solid Solution

**Date:** October 20, 2025
**Status:** ✅ Implemented

## Problem Identified

The live insights feature was receiving tiny audio chunks (512 bytes, ~0.016 seconds) instead of the expected ~10 second chunks, causing:

1. **Transcription Failures**: Whisper model receiving insufficient audio data
2. **Hallucinations**: Model outputting "you", "Thank you" for empty/short audio
3. **API Waste**: Sending hundreds of tiny chunks instead of proper 10-second chunks

### Root Cause

**FlutterSoundRecorder** emits audio data continuously in small fragments (default behavior). The `AudioStreamingService` was passing these fragments directly to the WebSocket without buffering, resulting in:

```
Chunk 0: Received 0.50 KB audio, duration: 0.016s  ❌
Expected: Received 320 KB audio, duration: 10.0s   ✅
```

## Solid Solution Implemented

### 1. Audio Buffering in AudioStreamingService

Added proper audio buffering to accumulate small fragments into 10-second chunks:

```dart
// Configuration
static const int sampleRate = 16000; // 16kHz for speech
static const int chunkDurationSeconds = 10; // Buffer 10 seconds
static const int bytesPerSample = 2; // 16-bit PCM
static const int targetChunkSize = sampleRate * chunkDurationSeconds * bytesPerSample; // ~320KB

// Buffering
final List<int> _audioBuffer = [];
```

### 2. Two-Stream Architecture

**Internal Stream** → **Buffer** → **Output Stream**

```dart
// Internal stream receives raw fragments from FlutterSound
final StreamController<Uint8List> _internalStreamController;

// Buffer accumulates fragments
void _handleAudioFragment(Uint8List fragment) {
  _audioBuffer.addAll(fragment);

  // Emit when we have 10 seconds of audio
  if (_audioBuffer.length >= targetChunkSize) {
    final chunkBytes = Uint8List.fromList(_audioBuffer.sublist(0, targetChunkSize));
    _audioBuffer.removeRange(0, targetChunkSize);
    _audioChunkController.add(chunkBytes);  // Emit buffered chunk
  }
}

// FlutterSound writes to internal stream
await _recorder.startRecorder(
  toStream: _internalStreamController.sink,  // Internal buffering stream
  codec: Codec.pcm16,
  sampleRate: sampleRate,
  numChannels: 1,
);
```

### 3. PCM16 to WAV Conversion (Backend)

Flutter sends raw PCM16 data, but Whisper needs proper audio format. Backend now converts PCM16 to WAV with proper headers:

```python
# AudioStreamingService sends raw PCM16 data (16kHz, mono, 16-bit)
import wave
import io

# Create WAV file with proper header
wav_buffer = io.BytesIO()
with wave.open(wav_buffer, 'wb') as wav_file:
    wav_file.setnchannels(1)  # Mono
    wav_file.setsampwidth(2)   # 16-bit = 2 bytes
    wav_file.setframerate(16000)  # 16kHz sample rate
    wav_file.writeframes(audio_bytes)

wav_bytes = wav_buffer.getvalue()

# Save as .wav for Whisper
with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
    temp_audio_path = temp_file.name
    temp_file.write(wav_bytes)
```

### 4. Final Chunk Flushing

When recording stops, flush any remaining audio (if >= 1 second):

```dart
// Flush remaining buffered audio
if (_audioBuffer.isNotEmpty && _audioBuffer.length >= sampleRate * bytesPerSample) {
  final remainingBytes = Uint8List.fromList(_audioBuffer);
  _audioChunkController.add(remainingBytes);
  _audioBuffer.clear();
}
```

## Architecture Diagram

```
FlutterSoundRecorder
       ↓
  (512 bytes fragments every 16ms)
       ↓
_internalStreamController
       ↓
  _handleAudioFragment()
       ↓
   Buffer accumulates
       ↓
  (320KB / 10 seconds)
       ↓
_audioChunkController  ←  Application listens here
       ↓
  Base64 encode
       ↓
  WebSocket send
       ↓
  Backend receives
       ↓
  Convert PCM16 → WAV
       ↓
  Replicate Whisper API
       ↓
  Transcription ✅
```

## Why This Is NOT a Workaround

### ❌ Workaround Approaches (NOT used):
- Hardcoded timers to wait before sending
- Ignoring small chunks and hoping for larger ones
- Reducing sample rate to make chunks "seem" longer
- Sending incomplete/corrupt audio data

### ✅ Solid Solution (Used):
1. **Proper Buffering**: Accumulates audio data correctly based on sample rate and duration
2. **Stream Transformation**: Clean separation between raw input and buffered output
3. **Format Conversion**: Proper PCM → WAV conversion with correct headers
4. **Resource Management**: Proper cleanup and flushing of buffers
5. **Configurable**: Easy to adjust chunk duration via constants

## Expected Behavior After Fix

### Before Fix:
```
[AudioStreamingService] Sent audio chunk: 512 bytes, ~0.0s duration
Chunk 0: Received 0.50 KB audio, duration: 0.016s
Transcription: "you" (hallucination)
```

### After Fix:
```
[AudioStreamingService] Buffered 512 bytes, total: 512/320000 bytes (0.2%)
[AudioStreamingService] Buffered 1024 bytes, total: 1024/320000 bytes (0.3%)
... (continues buffering)
[AudioStreamingService] Buffered 319488 bytes, total: 319488/320000 bytes (99.8%)
[AudioStreamingService] Buffered 320000 bytes, total: 320000/320000 bytes (100.0%)
[AudioStreamingService] Emitting chunk: 320000 bytes (~10.0s)
[RecordingProvider] Sent audio chunk: 320000 bytes, ~10.0s duration
Chunk 0: Received 312.50 KB audio, duration: 10.0s
Transcription: "In today's meeting we discussed the quarterly roadmap..." ✅
```

## Configuration

Adjust chunk duration if needed:

```dart
class AudioStreamingService {
  static const int chunkDurationSeconds = 10;  // Change to 5, 15, 20, etc.
  static const int targetChunkSize = sampleRate * chunkDurationSeconds * bytesPerSample;
}
```

**Trade-offs:**
- **Shorter chunks (5s)**: Lower latency, more API calls, less context
- **Longer chunks (15s)**: Higher latency, fewer API calls, more context
- **Current (10s)**: Balanced approach ✅

## Testing

Test the fix by:

1. Enable live insights in the recording dialog
2. Start recording and speak for at least 10 seconds
3. Check logs for buffering progress and chunk emission
4. Verify transcription contains actual speech, not "you" hallucinations

Expected logs:
```
[AudioStreamingService] Initialized successfully (chunk size: 312KB for 10s)
[AudioStreamingService] Started streaming audio with buffering (target: 10s chunks)
[AudioStreamingService] Buffered ... bytes, total: .../320000 bytes
[AudioStreamingService] Emitting chunk: 320000 bytes (~10.0s)
```

## Files Modified

1. **`lib/features/audio_recording/domain/services/audio_streaming_service.dart`**
   - Added audio buffering logic
   - Two-stream architecture (internal + output)
   - Buffer accumulation and chunk emission
   - Final chunk flushing on stop

2. **`backend/routers/websocket_live_insights.py`**
   - PCM16 to WAV conversion
   - Proper audio file headers
   - Enhanced logging for audio size and duration

3. **`backend/services/transcription/replicate_transcription_service.py`**
   - Audio quality diagnostics (no_speech_prob)
   - Enhanced logging for debugging

## Performance Impact

- **Memory**: ~320KB buffer per active recording session (negligible)
- **CPU**: Minimal (just list operations and array copying)
- **Latency**: 10 seconds (by design - waiting for full chunk)
- **API Calls**: Reduced by 600x (1 call per 10s instead of 600+ calls per 10s)

## Monitoring

Key metrics to track:

1. **Buffer Fill Rate**: Should reach 100% before emitting
2. **Chunk Size**: Should be ~320KB for 10-second chunks
3. **Transcription Length**: Should be > 50 characters for good discussions
4. **no_speech_prob**: Should be < 0.5 for actual speech

---

**Summary**: Solid buffering solution that properly accumulates audio fragments into 10-second chunks, converts to WAV format, and sends to transcription API. No workarounds, just proper audio streaming architecture.
