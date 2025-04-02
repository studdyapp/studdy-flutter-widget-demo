import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import the platform-specific implementations
import 'web-studdy_widget.dart' if (dart.library.io) 'mobile-studdy_widget.dart' as platform;

// Export the controller and data models
export 'web-studdy_widget.dart' if (dart.library.io) 'mobile-studdy_widget.dart' 
    show StuddyWidgetController, WidgetAuthRequest, PageData;

/// Main wrapper for the StuddyWidget that selects the appropriate
/// implementation based on the current platform
class StuddyWidget extends StatelessWidget {
  final platform.StuddyWidgetController controller;
  final double? width;
  final double? height;
  
  const StuddyWidget({
    Key? key,
    required this.controller,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // The actual implementation is imported from the platform-specific file
    return platform.StuddyWidget(
      controller: controller,
      width: width,
      height: height,
    );
  }
}