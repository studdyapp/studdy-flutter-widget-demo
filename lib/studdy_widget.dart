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
  
  // Add widget configuration properties
  String? _widgetPosition;
  int? _zIndex;
  bool _displayOnAuth = false;
  String? _targetLocale;
  
  StuddyWidgetController({
    this.onAuthenticationResponse,
    this.onWidgetDisplayed,
    this.onWidgetHidden,
    this.onWidgetEnlarged,
    this.onWidgetMinimized,
    String widgetUrl = 'https://storage.googleapis.com/studdy-widget-version0/dist/index.html',
  }) {
    _widgetUrl = widgetUrl;
  }
  
  // Initialize the controller with the WebView
  void initialize(WebViewController webViewController) {
    controller = webViewController;
    _isInitialized = true;
    _setupMessageHandlers();
  }
  
  // Set up handlers for messages from the widget
  void _setupMessageHandlers() {
    if (!_isInitialized) return;
    
    controller.addJavaScriptChannel(
      'WidgetChannel',
      onMessageReceived: (JavaScriptMessage message) {
        _handleWidgetMessage(message.message);
      },
    );
  }
  
  // Handle messages from widget
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
  
  // Authenticate with the Studdy platform
  Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) async {
    _sendMessageToWidget('AUTHENTICATE', authRequest.toJson());
    _logEvent('Authentication sent');
    return {'success': true};
  }
  
  // Control widget display
  Map<String, dynamic> display() {
    _sendMessageToWidget('DISPLAY_WIDGET');
    _logEvent('Widget displayed');
    return {'success': true};
  }
  
  Map<String, dynamic> hide() {
    _sendMessageToWidget('HIDE_WIDGET');
    _logEvent('Widget hidden');
    return {'success': true};
  }
  
  Map<String, dynamic> enlarge([String? screen]) {
    _sendMessageToWidget('ENLARGE_WIDGET', {'screen': screen ?? 'solver'});
    _logEvent('Widget enlarged to ${screen ?? "solver"} screen');
    return {'success': true};
  }
  
  Map<String, dynamic> minimize() {
    _sendMessageToWidget('MINIMIZE_WIDGET');
    _logEvent('Widget minimized');
    return {'success': true};
  }
  
  // Configure widget
  Map<String, dynamic> setWidgetPosition(String position) {
    _widgetPosition = position;
    _sendMessageToWidget('SET_WIDGET_POSITION', {'position': position});
    _logEvent('Widget position set to $position');
    return {'success': true};
  }
  
  Map<String, dynamic> setZIndex(int zIndex) {
    _zIndex = zIndex;
    _sendMessageToWidget('SET_Z_INDEX', {'zIndex': zIndex});
    _logEvent('Widget zIndex set to $zIndex');
    return {'success': true};
  }
  
  Map<String, dynamic> setTargetLocale(String locale) {
    _targetLocale = locale;
    _sendMessageToWidget('SET_TARGET_LOCALE', {'locale': locale});
    _logEvent('Widget target locale set to $locale');
    return {'success': true};
  }
  
  Map<String, dynamic> setPageData(PageData pageData) {
    _sendMessageToWidget('SET_PAGE_DATA', pageData.toJson());
    _logEvent('Page data set');
    return {'success': true};
  }
}

// The actual widget implementation
class StuddyWidget extends StatefulWidget {
  final StuddyWidgetController controller;
  final double? width;
  final double? height;
  
  const StuddyWidget({
    Key? key,
    required this.controller,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  _StuddyWidgetState createState() => _StuddyWidgetState();
}

class _StuddyWidgetState extends State<StuddyWidget> {
  late WebViewController _webViewController;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse(widget.controller._widgetUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Initialize controller when page is loaded
            widget.controller.initialize(_webViewController);
          },
        ),
      );
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: WebViewWidget(controller: _webViewController),
    );
  }
} 