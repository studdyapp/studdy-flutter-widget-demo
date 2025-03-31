import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

// Types to match integration implementation
class WidgetAuthRequest {
  final String tenantId;
  final String authMethod;
  final Map<String, dynamic>? authData;
  final String? jwt;
  final String? version;

  WidgetAuthRequest({
    required this.tenantId,
    required this.authMethod,
    this.authData,
    this.jwt,
    this.version = "1.0",
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'tenantId': tenantId,
      'authMethod': authMethod,
      'version': version,
    };
    
    // Add jwt if it exists
    if (jwt != null) {
      json['jwt'] = jwt;
    }
    
    // Add all authData entries if they exist
    if (authData != null) {
      json.addAll(authData!);
    }
    
    return json;
  }
}

class PageData {
  final List<Map<String, dynamic>> problems;
  final String? targetLocale;

  PageData({required this.problems, this.targetLocale});

  Map<String, dynamic> toJson() {
    return {
      'problems': problems,
      if (targetLocale != null) 'targetLocale': targetLocale,
    };
  }
}

// Widget class that can be used to control the StuddyWidget
class StuddyWidgetController {
  late WebViewController controller;
  bool _isInitialized = false;
  String _widgetUrl = 'https://storage.googleapis.com/studdy-widget-version0/dist/index.html';
  
  // Add message handler callbacks
  Function(Map<String, dynamic>)? onAuthenticationResponse;
  Function(Map<String, dynamic>)? onWidgetDisplayed;
  Function(Map<String, dynamic>)? onWidgetHidden;
  Function(Map<String, dynamic>)? onWidgetEnlarged;
  Function(Map<String, dynamic>)? onWidgetMinimized;

  StuddyWidgetController({
    String? widgetUrl,
    this.onAuthenticationResponse,
    this.onWidgetDisplayed,
    this.onWidgetHidden,
    this.onWidgetEnlarged,
    this.onWidgetMinimized,
  }) {
    if (widgetUrl != null) {
      _widgetUrl = widgetUrl;
    }

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _logEvent('Widget loaded successfully');
            _isInitialized = true;
          },
          onWebResourceError: (error) {
            _logEvent('Error loading widget: ${error.description}');
          },
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'StuddyWidgetChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _logEvent('Message from widget: ${message.message}');
          _handleWidgetMessage(message.message);
        },
      )
      ..enableZoom(false)
      ..loadRequest(Uri.parse(_widgetUrl));
  }

  // Add handler for widget messages
  void _handleWidgetMessage(String messageString) {
    try {
      final message = jsonDecode(messageString);
      final String type = message['type'];
      final dynamic payload = message['payload'];
      
      _logEvent('Received message of type: $type');
      
      switch (type) {
        case 'AUTHENTICATION_RESPONSE':
          if (onAuthenticationResponse != null) {
            onAuthenticationResponse!(payload);
          }
          break;
        case 'WIDGET_DISPLAYED':
          if (onWidgetDisplayed != null) {
            onWidgetDisplayed!(payload ?? {});
          }
          break;
        case 'WIDGET_HIDDEN':
          if (onWidgetHidden != null) {
            onWidgetHidden!(payload ?? {});
          }
          break;
        case 'WIDGET_ENLARGED':
          if (onWidgetEnlarged != null) {
            onWidgetEnlarged!(payload ?? {});
          }
          break;
        case 'WIDGET_MINIMIZED':
          if (onWidgetMinimized != null) {
            onWidgetMinimized!(payload ?? {});
          }
          break;
        default:
          _logEvent('Unknown message type: $type');
      }
    } catch (e) {
      _logEvent('Error parsing message from widget: $e');
    }
  }

  void _logEvent(String message) {
    debugPrint('StuddyWidget: $message');
  }

  void _sendMessageToWidget(String type, [Map<String, dynamic>? payload]) {
    if (!_isInitialized) {
      _logEvent('Widget not initialized yet');
      return;
    }

    final message = {
      'type': type,
      if (payload != null) 'payload': payload,
    };

    final String jsonMessage = jsonEncode(message);
    controller.runJavaScript('''
      window.postMessage($jsonMessage, '*');
    ''');
  }


  // Auth methods matching integration implementation
  Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) {
    _sendMessageToWidget('AUTHENTICATE', authRequest.toJson());
    _logEvent('Authentication sent');
    return Future.value({'success': true});
  }

  // Set page data
  Map<String, dynamic> setPageData(PageData pageData) {
    _sendMessageToWidget('SET_PAGE_DATA', pageData.toJson());
    _logEvent('Page data set');
    return {'success': true};
  }

  // Show widget
  Map<String, dynamic> display() {
    _sendMessageToWidget('DISPLAY_WIDGET');
    _logEvent('Widget displayed');
    return {'success': true};
  }

  // Hide widget
  Map<String, dynamic> hide() {
    _sendMessageToWidget('HIDE_WIDGET');
    _logEvent('Widget hidden');
    return {'success': true};
  }

  // Enlarge widget (open)
  Map<String, dynamic> enlarge([String? screenOnShow]) {
    _sendMessageToWidget('ENLARGE_WIDGET', {'screen': screenOnShow ?? 'solver'});
    _logEvent('Widget enlarged to ${screenOnShow ?? "solver"} screen');
    return {'success': true};
  }

  // Minimize widget
  Map<String, dynamic> minimize() {
    _sendMessageToWidget('MINIMIZE_WIDGET');
    _logEvent('Widget minimized');
    return {'success': true};
  }

  // Set target locale
  Map<String, dynamic> setTargetLocale(String targetLocale) {
    _sendMessageToWidget('SET_TARGET_LOCALE', {'targetLocale': targetLocale});
    _logEvent('Target locale set to $targetLocale');
    return {'success': true};
  }

  // Set widget position
  Map<String, dynamic> setWidgetPosition(String position) {
    if (position != 'right' && position != 'left') {
      throw ArgumentError('Position must be either "right" or "left"');
    }
    
    _sendMessageToWidget('SET_WIDGET_POSITION', {'position': position});
    _logEvent('Widget position set to $position');
    return {'success': true};
  }

  // Set Z-Index directly through the iframe
  Map<String, dynamic> setZIndex(int zIndex) {
    _sendMessageToWidget('SET_ZINDEX', {'zIndex': zIndex});
    _logEvent('Z-index set to $zIndex');
    return {'success': true};
  }
}

// The actual widget implementation
class StuddyWidget extends StatelessWidget {
  final StuddyWidgetController controller;
  final double width;
  final double height;
  
  const StuddyWidget({
    Key? key,
    required this.controller,
    this.width = double.infinity,
    this.height = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: WebViewWidget(controller: controller.controller),
    );
  }
} 