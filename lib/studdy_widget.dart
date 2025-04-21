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
  // Default widget URL
  static String defaultWidgetUrl = 'https://widget.studdy.ai';
  
  // Widget state tracking
  static bool _isAuthenticated = false;
  static bool _isPageDataSet = false;
  
  final String? customWidgetUrl;
  
  // Registry to track all widget instances and their controllers
  static final Map<String, platform.StuddyWidgetController> _controllerRegistry = {};
  static String _activeWidgetId = 'default';
  
  // Global controller for shared usage
  static platform.StuddyWidgetController get _controller {
    if (!_controllerRegistry.containsKey('default')) {
      _controllerRegistry['default'] = platform.StuddyWidgetController(
        widgetUrl: defaultWidgetUrl,
      );
    }
    return _controllerRegistry['default']!;
  }
  
  static set widgetUrl(String url) {
    defaultWidgetUrl = url;
    // Update the default controller
    _controllerRegistry['default'] = platform.StuddyWidgetController(
      widgetUrl: url,
    );
  }
  
  // ID for this specific widget instance
  final String _widgetId = DateTime.now().millisecondsSinceEpoch.toString();
  
  // Optional size parameters
  final double? width;
  final double? height;
  
  StuddyWidget({
    Key? key,
    this.width,
    this.height,
    this.customWidgetUrl,
  }) : super(key: key) {
    if (customWidgetUrl != null) {
      _controllerRegistry[_widgetId] = platform.StuddyWidgetController(
        widgetUrl: customWidgetUrl!,
      );
    }
  }
  
  static void setActiveWidget(StuddyWidget widget) {
    if (widget.customWidgetUrl != null) {
      _activeWidgetId = widget._widgetId;
    } else {
      _activeWidgetId = 'default';
    }
  }
  
  /// Get the currently active controller
  static platform.StuddyWidgetController get activeController {
    return _controllerRegistry[_activeWidgetId] ?? _controller;
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
    final response = await activeController.authenticate(authRequest);
    // Update authentication state based on response
    _isAuthenticated = response['success'] == true;
    return response;
  }
  
  /// Set the page data for context-aware assistance
  static Map<String, dynamic> setPageData(PageData pageData) {
    final response = activeController.setPageData(pageData);
    // Update page data state
    _isPageDataSet = response['success'] == true;
    return response;
  }
  
  /// Display the widget
  static Map<String, dynamic> display() {
    // Validate widget is ready to be displayed
    _validateWidgetState('displayed');
    return activeController.display();
  }
  
  /// Hide the widget
  static Map<String, dynamic> hide() {
    // Validate widget is ready to be hidden
    _validateWidgetState('hidden');
    return activeController.hide();
  }
  
  /// Enlarge the widget with optional screen type
  static Map<String, dynamic> enlarge([String? screen]) {
    // Validate widget is ready to be enlarged
    _validateWidgetState('enlarged');
    return activeController.enlarge(screen);
  }
  
  /// Minimize the widget
  static Map<String, dynamic> minimize() {
    // Validate widget is ready to be minimized
    _validateWidgetState('minimized');
    return activeController.minimize();
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
  
  // Create a way to authenticate with custom controllers
  static Future<Map<String, dynamic>> authenticateWithController(
    platform.StuddyWidgetController controller, 
    WidgetAuthRequest authRequest
  ) async {
    final response = await controller.authenticate(authRequest);
    return response;
  }
  
  // Method to set page data with a custom controller
  static Map<String, dynamic> setPageDataWithController(
    platform.StuddyWidgetController controller,
    PageData pageData
  ) {
    return controller.setPageData(pageData);
  }
  
  /// Check if the widget is ready for API calls
  /// Returns true if the underlying controller is initialized and ready to receive commands
  static bool isReady() {
    return activeController.isInitialized;
  }

  
  @override
  State<StuddyWidget> createState() => _StuddyWidgetState();
}

class _StuddyWidgetState extends State<StuddyWidget> {
  late platform.StuddyWidgetController _controller;
  
  @override
  void initState() {
    super.initState();
    
    // Get the controller for this widget
    if (widget.customWidgetUrl != null) {
      _controller = StuddyWidget._controllerRegistry[widget._widgetId]!;
      // Set this as the active widget
      StuddyWidget.setActiveWidget(widget);
    } else {
      _controller = StuddyWidget._controller;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // The actual implementation is delegated to the platform-specific file
    return platform.StuddyWidget(
      controller: _controller,
      width: widget.width,
      height: widget.height,
    );
  }
}