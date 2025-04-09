import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import the platform-specific implementations
import 'platform/web-studdy_widget.dart' if (dart.library.io) 'platform/mobile-studdy_widget.dart' as platform;

// Import shared models
import 'utils/widget_models.dart';

// Export the data models
export 'utils/widget_models.dart';

/// Main wrapper for the StuddyWidget that provides an easy-to-use API
/// and handles platform-specific implementation details
class StuddyWidget extends StatefulWidget {
  // Widget URL - Public but only modified through initialize()
  static String widgetUrl = 'https://pr-482-widget.dev.studdy.ai';
  
  // Initialization status
  static bool _initialized = false;
  
  // Singleton controller instance - lazily initialized
  static platform.StuddyWidgetController get _controller {
    _instance ??= platform.StuddyWidgetController(
      widgetUrl: widgetUrl,
    );
    return _instance!;
  }
  static platform.StuddyWidgetController? _instance;
  
  // Optional size parameters
  final double? width;
  final double? height;
  
  /// Creates a StuddyWidget with optional dimensions
  const StuddyWidget({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);
  
  /// Initialize the widget with a custom URL (call before creating widget)
  static void initialize() {
    StuddyWidget.widgetUrl = widgetUrl;
    // Reset the controller so it will be recreated with the new URL
    _instance = platform.StuddyWidgetController(
      widgetUrl: widgetUrl,
    );
    _initialized = true;
  }
  
  /// Authenticate with the Studdy platform
  static Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) {
    return _controller.authenticate(authRequest);
  }
  
  /// Set the page data for context-aware assistance
  static Map<String, dynamic> setPageData(PageData pageData) {
    return _controller.setPageData(pageData);
  }
  
  /// Display the widget
  static Map<String, dynamic> display() {
    return _controller.display();
  }
  
  /// Hide the widget
  static Map<String, dynamic> hide() {
    return _controller.hide();
  }
  
  /// Enlarge the widget with optional screen type
  static Map<String, dynamic> enlarge([String? screen]) {
    return _controller.enlarge(screen);
  }
  
  /// Minimize the widget
  static Map<String, dynamic> minimize() {
    return _controller.minimize();
  }
  
  /// Set the widget position (left or right)
  static Map<String, dynamic> setWidgetPosition(String position) {
    return _controller.setWidgetPosition(position);
  }
  
  /// Set the widget z-index
  static Map<String, dynamic> setZIndex(int zIndex) {
    return _controller.setZIndex(zIndex);
  }
  
  /// Set the target locale
  static Map<String, dynamic> setTargetLocale(String locale) {
    return _controller.setTargetLocale(locale);
  }
  
  @override
  State<StuddyWidget> createState() => _StuddyWidgetState();
}

class _StuddyWidgetState extends State<StuddyWidget> {
  @override
  Widget build(BuildContext context) {
    // The actual implementation is delegated to the platform-specific file
    return platform.StuddyWidget(
      controller: StuddyWidget._controller,
      width: widget.width,
      height: widget.height,
    );
  }
}