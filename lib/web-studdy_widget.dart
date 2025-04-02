import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'dart:async';

// Replace dart:ui with dart:ui_web for platformViewRegistry
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

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
  String _widgetUrl = 'https://pr-468-widget.dev.studdy.ai';
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
    String widgetUrl = 'https://pr-468-widget.dev.studdy.ai',
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
    
    // Add a global window message listener
    html.window.addEventListener('message', (html.Event event) {
      final html.MessageEvent messageEvent = event as html.MessageEvent;
      
      // Check if this is a message from our widget
      if (_iframe != null && messageEvent.source != _iframe!.contentWindow) {
        return; // Ignore messages not from our iframe
      }
      
      try {
        final message = messageEvent.data;
        final String type = message['type'] ?? '';
        final dynamic payload = message['payload'];
        
        print('DIRECT! Message received from widget: type=$type');
        
        // Process the message directly
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
            print('EUREUKA! Minimized widget');
            if (onWidgetMinimized != null) onWidgetMinimized!(payload ?? {});
            break;
          default:
            _logEvent('Unknown message type: $type');
        }
      } catch (e) {
        _logEvent('Error processing message: $e');
      }
    });
    
    // Original JavaScript channel setup
    controller.addJavaScriptChannel(
      'WidgetChannel',
      onMessageReceived: (JavaScriptMessage message) {
        print('JS CHANNEL: Message received: ${message.message}');
        _handleWidgetMessage(message.message);
      },
    );
    
    // Add JavaScript to forward window messages to our channel
    controller.runJavaScript('''
      window.addEventListener('message', function(event) {
        console.log('WIDGET RECEIVED A MESSAGE HOLY FUCK:', JSON.stringify(event.data));
        try {
          if (event.data && event.data.type) {
            window.WidgetChannel.postMessage(JSON.stringify(event.data));
          }
        } catch(e) {
          console.error('Error forwarding message:', e);
        }
      });
    ''');
  }

  void _handleWidgetMessage(String messageString) {
    try {
      final message = jsonDecode(messageString);
      final String type = message['type'] ?? '';
      final dynamic payload = message['payload'];
      print('EUREUKA! Receiving a message via JS channel, type: $type');

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
          print('EUREUKA! Minimized widget');
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
      try {
        // Direct approach - use the iframe reference we already have
        print('SENDING DIRECTLY: Message to iframe: $type');
        _iframe!.contentWindow?.postMessage(message, '*');
        _logEvent('Message sent directly to iframe: $type');
      } catch (e) {
        print('ERROR sending direct message: $e');
      }
    } else {
      print('SENDING VIA JS: Message to WebView: $type');
      // Use JavaScript to send the message via window.postMessage
      controller.runJavaScript('''
        try {
          const message = $jsonMessage;
          console.log('Sending message from Flutter:', message);
          window.postMessage(message, '*');
        } catch(e) {
          console.error('Error posting message:', e);
        }
      ''');
    }
  }


  Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) async {
    final jsonRequest = jsonEncode(authRequest.toJson());
    print('type of jsonRequest: ${jsonRequest.runtimeType}');
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
  late final String viewId;
  // Add constants for widget dimensions
  static const String MINIMIZED_WIDGET_WIDTH = '80px';
  static const String MINIMIZED_WIDGET_HEIGHT = '80px';
  static const String ENLARGED_WIDGET_WIDTH = '90vw';
  static const String ENLARGED_WIDGET_HEIGHT = '90vh';
  static const String WIDGET_OFFSET = '20px';
  
  @override
  void initState() {
    super.initState();
    // Create a stable viewId that doesn't change on rebuilds
    viewId = 'studdy-widget-${DateTime.now().millisecondsSinceEpoch}';
    
    if (kIsWeb) {
      // Register the view factory only once during initState
      _registerViewFactory();
    }
  }
  
  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(
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
          
          // Set up direct message listeners for iframe style adjustments
          html.window.addEventListener('message', (html.Event event) {
            final html.MessageEvent messageEvent = event as html.MessageEvent;
            
            try {
              print('IFRAME STYLE: Message received from widget iframe');
              final message = messageEvent.data;
              final String type = message['type'] ?? '';
              
              switch (type) {
                case 'WIDGET_MINIMIZED':
                  print('IFRAME STYLE: Minimizing widget iframe');
                  iframe.style.width = MINIMIZED_WIDGET_WIDTH;
                  iframe.style.height = MINIMIZED_WIDGET_HEIGHT;
                  break;
                  
                case 'WIDGET_ENLARGED':
                  print('IFRAME STYLE: Enlarging widget iframe');
                  iframe.style.width = ENLARGED_WIDGET_WIDTH;
                  iframe.style.height = ENLARGED_WIDGET_HEIGHT;
                  break;
                  
                case 'WIDGET_DISPLAYED':
                  print('IFRAME STYLE: Displaying widget iframe');
                  iframe.style.display = 'block';
                  break;
                  
                case 'WIDGET_HIDDEN':
                  print('IFRAME STYLE: Hiding widget iframe');
                  iframe.style.display = 'none';
                  break;
                
                case 'AUTHENTICATION_RESPONSE':
                  print('IFRAME STYLE: Auth response received, adjusting styles');
                  final payload = message['payload'];
                  if (payload != null && payload['publicConfigData'] != null) {
                    final config = payload['publicConfigData'];
                    if (config['defaultZIndex'] != null) {
                      iframe.style.zIndex = config['defaultZIndex'].toString();
                    }
                    
                    if (config['defaultWidgetPosition'] != null) {
                      iframe.style.left = config['defaultWidgetPosition'] == 'left' ? WIDGET_OFFSET : 'auto';
                      iframe.style.right = config['defaultWidgetPosition'] == 'right' ? WIDGET_OFFSET : 'auto';
                    }
                    
                    if (config['displayOnAuth'] == true) {
                      iframe.style.display = 'block';
                    }
                  }
                  break;
              }
            } catch (e) {
              debugPrint('StuddyWidget: Error processing message for iframe style: $e');
            }
          });
        });
        
        // Add a resize listener to maintain widget state
        html.window.onResize.listen((_) {
          // Only update necessary styles, don't recreate the iframe
          if (widget.controller._isInitialized && widget.controller._iframe != null) {
            iframe.style.width = '${widget.width ?? 400}px';
            iframe.style.height = '${widget.height ?? 600}px';
          }
        });
        
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
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