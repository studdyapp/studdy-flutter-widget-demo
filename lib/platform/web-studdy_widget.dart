//Not to be tampered with

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'dart:async';
import '../utils/widget_models.dart';
import '../utils/widget_constants.dart';

// Replace dart:ui with dart:ui_web for platformViewRegistry
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // for iframe

class StuddyWidgetController {
  late WebViewController controller;
  bool _isInitialized = false;
  String _widgetUrl = '';
  html.IFrameElement? _iframe;

  static Map<String, dynamic>? _latestAuthResponse;
  static final _authResponseNotifier = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get authResponseStream => _authResponseNotifier.stream;

  StuddyWidgetController({
    required String widgetUrl,
  }) {
    _widgetUrl = widgetUrl;
  }

  void initialize(WebViewController webViewController) {
    try {
      controller = webViewController;
      _isInitialized = true;
      // debugPrint('StuddyWidget: Controller successfully initialized');
    } catch (e) {
      // debugPrint('StuddyWidget: Error initializing controller: $e');
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
        _iframe!.contentWindow?.postMessage(message, '*');
        _logEvent('Message sent directly to iframe: $type');
      } catch (e) {
        print('ERROR sending direct message: $e');
      }
    }
  }


  Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Widget not initialized'};
    }

    final completer = Completer<Map<String, dynamic>>();
    html.EventListener? authListener;
    authListener = (html.Event event) {
      final messageEvent = event as html.MessageEvent;
      final data = messageEvent.data;
      if (data != null && data is Map && data['type'] == 'AUTHENTICATION_RESPONSE') {
        html.window.removeEventListener('message', authListener);
        
        // More robust handling of the payload
        final payload = data['payload'] is Map 
            ? Map<String, dynamic>.from(data['payload'] as Map) 
            : <String, dynamic>{};
        
        // Safely handle publicConfigData
        final publicConfigData = payload['publicConfigData'] is Map 
            ? Map<String, dynamic>.from(payload['publicConfigData'] as Map)
            : <String, dynamic>{};
        
        // Update iframe styles based on config if it exists
        if (_iframe != null) {
          if (publicConfigData.containsKey('defaultZIndex')) {
            _iframe!.style.zIndex = publicConfigData['defaultZIndex'].toString();
          }
          
          if (publicConfigData.containsKey('defaultWidgetPosition')) {
            _iframe!.style.left = publicConfigData['defaultWidgetPosition'] == 'left' ? WEB_WIDGET_OFFSET : 'auto';
            _iframe!.style.right = publicConfigData['defaultWidgetPosition'] == 'right' ? WEB_WIDGET_OFFSET : 'auto';
          }
          
          if (publicConfigData.containsKey('displayOnAuth') && publicConfigData['displayOnAuth'] == true) {
            _iframe!.style.display = 'block';
          }
        }

        completer.complete(payload);
      }
    };
    
    // Add the temporary listener
    html.window.addEventListener('message', authListener);
    
    // Send authentication request directly to iframe
    _iframe!.contentWindow?.postMessage({
      'type': 'AUTHENTICATE',
      'payload': authRequest.toJson()
    }, '*');
    
    // Set a timeout
    Future.delayed(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        // Remove listener on timeout
        html.window.removeEventListener('message', authListener);
        completer.complete({'success': false, 'error': 'Authentication timed out'});
      }
    });
    
    return completer.future;
  }

  Map<String, dynamic> setPageData(PageData pageData) {
    _sendMessageToWidget('SET_PAGE_DATA', pageData.toJson());
    _logEvent('Page data set');
    return {'success': true};
  }

  Map<String, dynamic> display() {
    _sendMessageToWidget('DISPLAY_WIDGET');
    _logEvent('Widget displayed');
    if (_iframe != null) {
      _iframe!.style.display = 'block';
    }
    return {'success': true};
  }

  Map<String, dynamic> hide() {
    _sendMessageToWidget('HIDE_WIDGET');
    _logEvent('Widget hidden');
    if (_iframe != null) {
      _iframe!.style.display = 'none';
    }
    return {'success': true};
  }

  Map<String, dynamic> enlarge([String? screen]) {
    _sendMessageToWidget('ENLARGE_WIDGET', {'screen': screen ?? 'solver'});
    _logEvent('Widget enlarged to ${screen ?? "solver"} screen');
    if (_iframe != null) {
      _iframe!.style.width = WEB_ENLARGED_WIDGET_WIDTH;
      _iframe!.style.height = WEB_ENLARGED_WIDGET_HEIGHT;
    }
    return {'success': true};
  }

  Map<String, dynamic> minimize() {
    _sendMessageToWidget('MINIMIZE_WIDGET');
    _logEvent('Widget minimized');
    if (_iframe != null) {
      _iframe!.style.width = WEB_MINIMIZED_WIDGET_WIDTH;
      _iframe!.style.height = WEB_MINIMIZED_WIDGET_HEIGHT;
    }
    return {'success': true};
  }

  Map<String, dynamic> setWidgetPosition(String position) {
    _sendMessageToWidget('SET_WIDGET_POSITION', {'position': position});
    _logEvent('Widget position set to $position');
    if (_iframe != null) {
      _iframe!.style.left = position == 'left' ? WEB_WIDGET_OFFSET : 'auto';
      _iframe!.style.right = position == 'right' ? WEB_WIDGET_OFFSET : 'auto';
    }
    return {'success': true};
  }

  Map<String, dynamic> setZIndex(int zIndex) {
    _sendMessageToWidget('SET_Z_INDEX', {'zIndex': zIndex});
    _logEvent('Widget zIndex set to $zIndex');
    if (_iframe != null) {
      _iframe!.style.zIndex = zIndex.toString();
    }
    return {'success': true};
  }

  Map<String, dynamic> setTargetLocale(String locale) {
    _sendMessageToWidget('SET_TARGET_LOCALE', {'targetLocale': locale});
    _logEvent('Widget target locale set to $locale');
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
  html.EventListener? _messageListener;
  
  @override
  void initState() {
    super.initState();
    viewId = 'studdy-widget-${DateTime.now().millisecondsSinceEpoch}';
    
    if (kIsWeb) {
      _registerViewFactory();
    }
  }
  
  @override
  void dispose() {
    // Clean up event listener when widget is disposed
    if (kIsWeb && _messageListener != null) {
      html.window.removeEventListener('message', _messageListener!);
      _messageListener = null;
    }
    super.dispose();
  }
  
  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.controller._widgetUrl
          ..style.border = 'none'
          ..style.position = 'fixed'
          ..style.bottom = WEB_WIDGET_OFFSET
          ..style.right = DEFAULT_POSITION == 'right' ? WEB_WIDGET_OFFSET : 'auto'
          ..style.left = DEFAULT_POSITION == 'left' ? WEB_WIDGET_OFFSET : 'auto'
          ..style.width = WEB_MINIMIZED_WIDGET_WIDTH
          ..style.height = WEB_MINIMIZED_WIDGET_HEIGHT
          ..style.maxHeight = WEB_WIDGET_MAX_HEIGHT
          ..style.maxWidth = WEB_WIDGET_MAX_WIDTH
          ..style.zIndex = DEFAULT_ZINDEX.toString()
          ..style.display = 'none'  // Hidden initially until authenticated
          ..allow = 'microphone; camera'
          ..title = 'Studdy Widget';
        
        // Mark controller as initialized on iframe load
        iframe.onLoad.listen((_) {
          widget.controller._isInitialized = true;
          widget.controller._iframe = iframe;
          
          // Remove any existing listener before adding a new one
          if (_messageListener != null) {
            html.window.removeEventListener('message', _messageListener!);
          }
          
          // Store reference to the listener function
          _messageListener = (html.Event event) {
            final html.MessageEvent messageEvent = event as html.MessageEvent;
            
            try {
              final message = messageEvent.data;
              final String type = message['type'] ?? '';
              
              switch (type) {
                case 'WIDGET_MINIMIZED':
                  iframe.style.width = WEB_MINIMIZED_WIDGET_WIDTH;
                  iframe.style.height = WEB_MINIMIZED_WIDGET_HEIGHT;
                  break;
                  
                case 'WIDGET_ENLARGED':
                  iframe.style.width = WEB_ENLARGED_WIDGET_WIDTH;
                  iframe.style.height = WEB_ENLARGED_WIDGET_HEIGHT;
                  break;
                  
                case 'WIDGET_DISPLAYED':
                  iframe.style.display = 'block';
                  break;
                  
                case 'WIDGET_HIDDEN':
                  iframe.style.display = 'none';
                  break;
              }
            } catch (e) {
              debugPrint('StuddyWidget: Error processing message for iframe style: $e');
            }
          };
          
          // Add the listener with the stored reference
          html.window.addEventListener('message', _messageListener!);
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