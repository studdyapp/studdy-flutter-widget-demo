import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui; // for platformViewRegistry on web

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // for iframe

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
    if (jwt != null) json['jwt'] = jwt;
    if (authData != null) json.addAll(authData!);
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

class StuddyWidgetController {
  late WebViewController controller;
  bool _isInitialized = false;
  String _widgetUrl = 'https://storage.googleapis.com/studdy-widget-version0/dist3/index.html';
  html.IFrameElement? _iframe;

  Function(Map<String, dynamic>)? onAuthenticationResponse;
  Function(Map<String, dynamic>)? onWidgetDisplayed;
  Function(Map<String, dynamic>)? onWidgetHidden;
  Function(Map<String, dynamic>)? onWidgetEnlarged;
  Function(Map<String, dynamic>)? onWidgetMinimized;

  String? _widgetPosition;
  int? _zIndex;
  bool _displayOnAuth = false;
  String? _targetLocale;

  DateTime? _lastMessageTime;
  String? _lastMessageType;
  static const _debounceTimeMs = 500; // Minimum time between same message types

  StuddyWidgetController({
    this.onAuthenticationResponse,
    this.onWidgetDisplayed,
    this.onWidgetHidden,
    this.onWidgetEnlarged,
    this.onWidgetMinimized,
    String widgetUrl = 'https://storage.googleapis.com/studdy-widget-version0/dist3/index.html',
  }) {
    _widgetUrl = widgetUrl;
  }

  void initialize(WebViewController webViewController) {
    try {
      controller = webViewController;
      _isInitialized = true;
      _setupMessageHandlers();
      debugPrint('StuddyWidget: Controller successfully initialized');
    } catch (e) {
      debugPrint('StuddyWidget: Error initializing controller: $e');
    }
  }

  void _setupMessageHandlers() {
    if (!_isInitialized) return;
    controller.addJavaScriptChannel(
      'WidgetChannel',
      onMessageReceived: (JavaScriptMessage message) {
        _handleWidgetMessage(message.message);
      },
    );
  }

  void _handleWidgetMessage(String messageString) {
    try {
      final message = jsonDecode(messageString);
      final String type = message['type'] ?? '';
      final dynamic payload = message['payload'];
      print('Receiving a message....');

      // Debounce logic - ignore repeated messages of same type within debounce time
      final now = DateTime.now();
      if (_lastMessageType == type && 
          _lastMessageTime != null && 
          now.difference(_lastMessageTime!).inMilliseconds < _debounceTimeMs) {
        // Skip this message - it's a duplicate within debounce window
        return;
      }
      
      _lastMessageType = type;
      _lastMessageTime = now;
      
      _logEvent('Received message of type: $type with payload: ${jsonEncode(payload ?? {})}');

      switch (type) {
        case 'AUTHENTICATION_RESPONSE':
          if (onAuthenticationResponse != null) onAuthenticationResponse!(payload);
          break;
        case 'WIDGET_DISPLAYED':
          if (onWidgetDisplayed != null) onWidgetDisplayed!(payload ?? {});
          break;
        case 'WIDGET_HIDDEN':
          if (onWidgetHidden != null) onWidgetHidden!(payload ?? {});
          break;
        case 'WIDGET_ENLARGED':
          if (onWidgetEnlarged != null) onWidgetEnlarged!(payload ?? {});
          break;
        case 'WIDGET_MINIMIZED':
          if (onWidgetMinimized != null) onWidgetMinimized!(payload ?? {});
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
    
    if (kIsWeb && _iframe != null) {
      // Direct approach - use the iframe reference we already have
      _iframe!.contentWindow?.postMessage(message, '*');
      _logEvent('Message sent directly to iframe: $type');
    } else {
      controller.runJavaScript('''window.postMessage($jsonMessage, '*');''');
    }
  }


  Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) async {
    final jsonRequest = jsonEncode(authRequest.toJson());
    _logEvent('Starting authentication with payload: $jsonRequest');
    _sendMessageToWidget('AUTHENTICATE', authRequest.toJson());
    _logEvent('Authentication message sent, waiting for response...');
    return {'success': true};
  }

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
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final String viewId = 'studdy-widget-${UniqueKey().toString()}';
      
      ui.platformViewRegistry.registerViewFactory(
        viewId,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = widget.controller._widgetUrl
            ..style.border = 'none'
            ..style.position = 'absolute'
            ..style.bottom = '20px'
            ..style.right = '20px'
            ..style.width = '${widget.width ?? 400}px'
            ..style.height = '${widget.height ?? 600}px';
          
          // Mark controller as initialized on iframe load
          iframe.onLoad.listen((_) {
            debugPrint('StuddyWidget: iframe loaded');
            widget.controller._isInitialized = true;
            widget.controller._iframe = iframe;
          });
          
          return iframe;
        },
      );

      return HtmlElementView(viewType: viewId);
    } else {
      final mobileController = WebViewController();

      mobileController
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) => widget.controller.initialize(mobileController),
          ),
        )
        ..loadRequest(Uri.parse(widget.controller._widgetUrl));

      return SizedBox(
        width: widget.width ?? 400,
        height: widget.height ?? 600,
        child: WebViewWidget(controller: mobileController),
      );
    }
  }
}