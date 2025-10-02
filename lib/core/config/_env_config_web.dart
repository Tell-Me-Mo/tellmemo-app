// Web-specific implementation for reading runtime environment config
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as js_util;
import 'dart:html' as html;

/// Get runtime config from window.ENV_CONFIG (injected by Docker entrypoint)
String? getRuntimeConfig(String key) {
  try {
    // Check if window.ENV_CONFIG exists
    if (js_util.hasProperty(html.window, 'ENV_CONFIG')) {
      final envConfig = js_util.getProperty(html.window, 'ENV_CONFIG');
      if (envConfig != null && js_util.hasProperty(envConfig, key)) {
        final value = js_util.getProperty(envConfig, key);
        return value?.toString();
      }
    }
  } catch (e) {
    // Return null if not available
  }
  return null;
}
