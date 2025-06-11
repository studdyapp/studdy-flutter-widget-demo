//Not to be tampered with

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../utils/widget_models.dart';
import '../utils/widget_constants.dart';

// Replace dart:ui with dart:ui_web for platformViewRegistry
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // for iframe

// Central position manager with static access
class WidgetPositionManager {
  static String position = 'right';
}

class StuddyWidgetController {
  late WebViewController controller;
  bool _isInitialized = false;
  String _widgetUrl = '';
  html.IFrameElement? _iframe;

  // Public getter for initialization state
  bool get isInitialized => _isInitialized;

  static final _authResponseNotifier = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get authResponseStream => _authResponseNotifier.stream;

  StuddyWidgetController({
    required String widgetUrl,
  }) {
    _widgetUrl = widgetUrl;
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
    
    if (_iframe != null) {
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
    // Update the static position directly
    WidgetPositionManager.position = position;
    
    // Still send the message for external compatibility
    _sendMessageToWidget('SET_WIDGET_POSITION', {'position': position});
    _logEvent('Widget position set to $position');
    
    return {'success': true};
  }

  Map<String, dynamic> setZIndex(int zIndex) {
    _sendMessageToWidget('SET_Z_INDEX', {'zIndex': zIndex});
    _logEvent('Widget zIndex set to $zIndex');
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
  final String viewId = 'studdy-widget-iframe';
  html.EventListener? _messageListener;
  bool _isVisible = false;
  bool _isEnlarged = false;
  
  @override
  void initState() {
    super.initState();
    _registerViewFactory();
  }
  
  @override
  void dispose() {
    // Remove event listener when widget is disposed
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener!);
      _messageListener = null;
    }
    super.dispose();
  }
  
  void _registerViewFactory() {
    print('Factory registered');
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.controller._widgetUrl
          ..style.border = 'none'
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
                  print('WIDGET_MINIMIZED');
                  setState(() {
                    _isEnlarged = false;
                  });
                  break;
                  
                case 'WIDGET_ENLARGED':
                  print('WIDGET_ENLARGED');
                  setState(() {
                    _isEnlarged = true;
                  });
                  break;
                  
                case 'WIDGET_DISPLAYED':
                  print('WIDGET_DISPLAYED');
                  setState(() {
                    _isVisible = true;
                  });
                  break;
                  
                case 'WIDGET_HIDDEN':
                  print('WIDGET_HIDDEN');
                  setState(() {
                    _isVisible = false;
                  });
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
    // Calculate width and height based on visibility and size state
    final double widgetWidth = _isVisible ? (_isEnlarged ? WEB_ENLARGED_WIDTH : WEB_MINIMIZED_WIDTH) : 1;
    final double widgetHeight = _isVisible ? (_isEnlarged ? WEB_ENLARGED_HEIGHT : WEB_MINIMIZED_HEIGHT) : 1;
    //regular container
    return Align(
      alignment: WidgetPositionManager.position == 'left' ? Alignment.bottomLeft : Alignment.bottomRight,
      child: Container(
        width: widgetWidth,
        height: widgetHeight,
        margin: EdgeInsets.only(
          left: WidgetPositionManager.position == 'left' ? WEB_WIDGET_OFFSET : 0,
          right: WidgetPositionManager.position == 'right' ? WEB_WIDGET_OFFSET : 0,
          bottom: WEB_WIDGET_OFFSET,
        ),
        child: HtmlElementView(viewType: viewId),
      ),
    );
  }
}