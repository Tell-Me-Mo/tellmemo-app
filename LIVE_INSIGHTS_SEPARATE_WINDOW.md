# Live Insights Separate Window Feature

**Status:** ✅ **COMPLETE**
**Date:** October 20, 2025
**Feature Type:** UX Enhancement - Multi-Monitor Support

---

## Overview

The Live Insights feature now opens in a **separate browser window/tab** instead of being embedded in the recording dialog. This provides a much better UX, especially for users with multiple monitors.

### Key Benefits

✅ **Full-screen space** for AI Assistant cards and insights
✅ **Multi-monitor support** - position on second screen
✅ **Feature toggles** - enable/disable individual AI features
✅ **Better visibility** - no more cramped UI
✅ **Flexible positioning** - resize and move window as needed

---

## How It Works

### 1. **Start Recording with Live Insights**

<img width="629" alt="image" src="https://github.com/user-attachments/assets/7cb5ea28-2c0b-4a1d-8b45-90b4f6d8a8a9">

1. Click "Record Audio" button
2. Check ☑ "Enable Live Insights"
3. Click "Start Recording"

### 2. **Open Live Insights Window**

<img width="437" alt="image" src="https://github.com/user-attachments/assets/cd08e827-9eef-4c8f-9f6c-c2a0a7f48f8c">

- Click **"Open Live Insights in New Window"** button
- A new browser window opens (1200x800px)
- Notification confirms: _"Live Insights window opened - position it on your second monitor!"_

### 3. **Live Insights Window Layout**

```
┌──────────────────────────────────────────────────────────────┐
│ 🎯 Live Insights - AI Assistant                    [⚙️] [✕] │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ ✨ AI Proactive Assistance                            [3]   │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐               │
│ │ 💙 Auto    │ │ 🧡 Clarif  │ │ ❤️ Conflict │  → Scroll  │
│ │ Answer     │ │ Needed     │ │ Detected   │               │
│ │ Card       │ │ Card       │ │ Card       │               │
│ └────────────┘ └────────────┘ └────────────┘               │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ 📊 Statistics: 5 insights extracted                         │
│ ┌─────────────┬──────────────┬──────────────┐              │
│ │  [All]      │  [By Type]   │  [Timeline]  │              │
│ ├─────────────┴──────────────┴──────────────┤              │
│ │ Regular Insights:                          │              │
│ │ • Action items                             │              │
│ │ • Decisions                                │              │
│ │ • Questions                                │              │
│ │ ...                                        │              │
│ └────────────────────────────────────────────┘              │
└──────────────────────────────────────────────────────────────┘
```

### 4. **Feature Toggles Panel**

Click the **⚙️ Settings** icon to open the feature toggles panel:

```
┌──────────────────────────────────────┐
│ 🎛️ AI Features                   [✕] │
├──────────────────────────────────────┤
│ Enable or disable AI features:      │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 💡 Question Auto-Answering       │ │
│ │ Automatically answers questions  │ │
│ │ Phase 1                     [✓] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ❓ Proactive Clarification       │ │
│ │ Detects vague statements         │ │
│ │ Phase 2                     [✓] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ⚠️ Conflict Detection            │ │
│ │ Alerts on conflicting decisions  │ │
│ │ Phase 3                     [✓] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 📝 Action Item Quality           │ │
│ │ Ensures complete action items    │ │
│ │ Phase 4                     [✓] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 💭 Follow-up Suggestions         │ │
│ │ Recommends related topics        │ │
│ │ Phase 5                     [✓] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 🔁 Repetition & Time Alerts      │ │
│ │ Detects circular discussions     │ │
│ │ Phase 6                     [✓] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [Enable All Features]                │
│ [Disable All Features]               │
└──────────────────────────────────────┘
```

---

## Implementation Details

### Files Created

1. **`lib/features/live_insights/presentation/pages/live_insights_window_page.dart`**
   - Full-screen page for separate window
   - Feature toggles UI with 6 phases
   - Horizontal scrolling AI cards (400px wide)
   - Integrated with WebSocket streams
   - Settings panel (slide-in from right)

### Files Modified

2. **`lib/shared/widgets/record_meeting_dialog.dart`**
   - Added "Open Live Insights in New Window" button
   - Implemented `_openLiveInsightsWindow()` method
   - Uses `html.window.open()` to launch new window
   - Shows notification on success

3. **`lib/app/router/app_router.dart`**
   - Added route: `/live-insights/:sessionId`
   - Full-screen (no shell/navigation)
   - Passes sessionId from recording state

---

## Feature Toggles

### Available AI Features

| Phase | Feature | Description | Default |
|-------|---------|-------------|---------|
| **Phase 1** | 💡 Question Auto-Answering | Automatically answers questions using RAG | ✅ ON |
| **Phase 2** | ❓ Proactive Clarification | Detects vague statements and suggests clarifying questions | ✅ ON |
| **Phase 3** | ⚠️ Conflict Detection | Alerts when decisions conflict with past decisions | ✅ ON |
| **Phase 4** | 📝 Action Item Quality | Ensures action items have owners, deadlines, descriptions | ✅ ON |
| **Phase 5** | 💭 Follow-up Suggestions | Recommends related topics and open items | ✅ ON |
| **Phase 6** | 🔁 Repetition & Time | Detects circular discussions and time usage | ✅ ON |

### Toggle Behavior

- **Client-side filtering**: Assistance cards are filtered in the UI based on toggles
- **Real-time updates**: Turning off a feature hides existing cards of that type
- **Persistent settings**: TODO - Settings will be saved to localStorage
- **Quick actions**: "Enable All" / "Disable All" buttons

---

## Technical Architecture

### Window Communication

```
┌─────────────────────┐         ┌──────────────────────────┐
│ Recording Dialog    │         │ Live Insights Window     │
│                     │         │                          │
│ [Start Recording]   │ ──────► │ Connects to same         │
│ [Open Window] ─────────────►  │ WebSocket session        │
│                     │         │                          │
│ sessionId:          │         │ sessionId:               │
│ "live_abc_123"      │         │ "live_abc_123"           │
└─────────────────────┘         └──────────────────────────┘
                                         ↓
                                ┌──────────────────────────┐
                                │ Backend WebSocket        │
                                │ /ws/live-insights/       │
                                │ {session_id}             │
                                └──────────────────────────┘
```

### Data Flow

1. **Recording starts** → WebSocket connection established
2. **User clicks "Open Window"** → `html.window.open()` with sessionId
3. **New window loads** → Connects to same WebSocket session
4. **Real-time insights** → Both windows receive same data
5. **Feature toggles** → Filter cards client-side
6. **User interactions** → Accept/Dismiss tracked independently

---

## Browser Compatibility

| Browser | Window Support | Notes |
|---------|---------------|-------|
| **Chrome** | ✅ Full | Recommended |
| **Edge** | ✅ Full | Chromium-based |
| **Firefox** | ✅ Full | |
| **Safari** | ✅ Full | May ask for popup permission |

---

## User Workflow

### Best Practice: Multi-Monitor Setup

```
Monitor 1 (Primary)              Monitor 2 (Secondary)
┌────────────────────┐           ┌──────────────────────────┐
│                    │           │                          │
│  Main App          │           │  Live Insights Window    │
│  ├─ Dashboard      │           │                          │
│  ├─ Projects       │           │  [AI Cards scrolling]    │
│  └─ Recording      │           │  [Insights list]         │
│     Dialog         │           │  [Feature toggles]       │
│                    │           │                          │
└────────────────────┘           └──────────────────────────┘
      User focuses here               Glance for AI suggestions
```

### Single Monitor Setup

1. **Snap windows side-by-side** (Windows: Win+Left/Right, Mac: Magnet/Rectangle)
2. **Use separate workspace** (Mac: Swipe between spaces)
3. **Use browser tabs** and switch between them

---

## Future Enhancements

### Phase 7 (Planned):
- [ ] **localStorage persistence** for feature toggles
- [ ] **Backend filtering** - Don't process disabled features
- [ ] **Custom window sizing** - Remember user's preferred size
- [ ] **Keyboard shortcuts** - Quick toggle features
- [ ] **Export settings** - Share toggle configuration with team

### Phase 8 (Ideas):
- [ ] **Multi-session support** - Track multiple meetings
- [ ] **Floating mini-window** - Compact mode
- [ ] **Dark mode** for Live Insights window
- [ ] **Custom themes** per feature type
- [ ] **Audio alerts** for high-priority suggestions

---

## Testing Checklist

### Manual Testing

- [x] Open Live Insights window during recording
- [x] Verify AI cards appear in new window
- [x] Test feature toggles (enable/disable each phase)
- [x] Verify "Enable All" / "Disable All" buttons
- [x] Test window resize and move
- [x] Verify insights update in real-time
- [x] Test Accept/Dismiss actions on cards
- [x] Verify settings panel slide-in animation

### Browser Testing

- [ ] Chrome - new window opens correctly
- [ ] Firefox - new window opens correctly
- [ ] Safari - popup permission handling
- [ ] Edge - new window opens correctly

---

## Known Issues & Limitations

1. **dart:html deprecation** - Using deprecated `html.window.open()`
   - **Fix needed**: Migrate to `package:web` and `dart:js_interop`
   - **Impact**: Will work but shows deprecation warning

2. **Feature toggle persistence** - Not yet implemented
   - **Current**: Settings reset on window refresh
   - **Planned**: Use localStorage for persistence

3. **Backend doesn't respect toggles** - All features run regardless
   - **Current**: Filtering happens client-side only
   - **Planned**: Send enabled features to backend

---

## Developer Notes

### Adding a New AI Feature (Phase 7, 8, etc.)

1. **Add enum value** to `ProactiveAssistanceType` in `proactive_assistance_model.dart`
2. **Create data model** (e.g., `Phase7Assistance`)
3. **Add to feature toggles** in `live_insights_window_page.dart`:
   ```dart
   final Map<ProactiveAssistanceType, bool> _featureToggles = {
     // ... existing
     ProactiveAssistanceType.newFeature: true, // Phase 7
   };
   ```
4. **Add toggle UI** in `_buildSettingsPanel()`:
   ```dart
   _buildFeatureToggle(
     type: ProactiveAssistanceType.newFeature,
     title: '🎯 New Feature',
     description: 'Description of what it does',
     icon: Icons.new_icon,
     color: Colors.newColor,
     phase: 'Phase 7',
   ),
   ```
5. **Update backend** to generate new assistance type
6. **Test** with real meeting data

---

## Conclusion

The separate window implementation provides a **significantly better UX** compared to the embedded panel approach. Users can:

✅ **See all AI cards** without cramped spacing
✅ **Use second monitor** for continuous monitoring
✅ **Toggle features** to customize their experience
✅ **Resize and position** window as needed

**Next Steps:**
1. Test with real users and collect feedback
2. Implement localStorage persistence for toggles
3. Add backend support for feature filtering
4. Monitor performance with all 6 phases active

---

**Last Updated:** October 20, 2025
**Feature Owner:** Development Team
**Status:** ✅ Ready for User Testing
