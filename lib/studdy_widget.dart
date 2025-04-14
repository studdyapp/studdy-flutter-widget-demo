//Not to be tampered with

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
  // Widget URL
  static String widgetUrl = 'https://widget.dev.studdy.ai'; // TODO: Change this to https://widget.studdy.ai when ready
  
  // Initialization status
  static bool _initialized = false;
  
  // Widget state tracking
  static bool _isAuthenticated = false;
  static bool _isPageDataSet = false;
  
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
  
  static void initialize() {
    StuddyWidget.widgetUrl = widgetUrl;
    // Reset the controller so it will be recreated with the new URL
    _instance = platform.StuddyWidgetController(
      widgetUrl: widgetUrl,
    );
    _initialized = true;
  }
  
  /// Validate widget state before performing actions
  static void _validateWidgetState(String action) {
    if (!_isAuthenticated || !_isPageDataSet) {
      String errorMessage;
      if (!_isAuthenticated && !_isPageDataSet) {
        errorMessage = 'Authentication and page data must be set before the widget can be $action';
      } else if (!_isAuthenticated) {
        errorMessage = 'Authentication must be completed before the widget can be $action';
      } else {
        errorMessage = 'Page data must be set before the widget can be $action';
      }
      
      throw WidgetDataException(errorMessage);
    }
  }
  
  /// Authenticate with the Studdy platform
  static Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) async {
    final response = await _controller.authenticate(authRequest);
    // Update authentication state based on response
    _isAuthenticated = response['success'] == true;
    return response;
  }
  
  /// Set the page data for context-aware assistance
  static Map<String, dynamic> setPageData(PageData pageData) {
    final response = _controller.setPageData(pageData);
    // Update page data state
    _isPageDataSet = response['success'] == true;
    return response;
  }
  
  /// Display the widget
  static Map<String, dynamic> display() {
    // Validate widget is ready to be displayed
    _validateWidgetState('displayed');
    return _controller.display();
  }
  
  /// Hide the widget
  static Map<String, dynamic> hide() {
    // Validate widget is ready to be hidden
    _validateWidgetState('hidden');
    return _controller.hide();
  }
  
  /// Enlarge the widget with optional screen type
  static Map<String, dynamic> enlarge([String? screen]) {
    // Validate widget is ready to be enlarged
    _validateWidgetState('enlarged');
    return _controller.enlarge(screen);
  }
  
  /// Minimize the widget
  static Map<String, dynamic> minimize() {
    // Validate widget is ready to be minimized
    _validateWidgetState('minimized');
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