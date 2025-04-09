import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/widget_models.dart';
import '../utils/widget_constants.dart';

// Mobile StuddyWidget class that can be used for controlling the StuddyWidget
class StuddyWidgetController {
  // Static fields for auth response handling
  static Map<String, dynamic>? _latestAuthResponse;
  static final _authResponseNotifier = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get authResponseStream => _authResponseNotifier.stream;

  late WebViewController controller;
  bool _isInitialized = false;
  String _widgetUrl = '';
  
  // Widget state variables
  String _position = DEFAULT_POSITION;  // Track the current position
  int _zIndex = DEFAULT_ZINDEX;  // Track the current z-index
  
  
  StuddyWidgetController({
    required String widgetUrl,
  }) {
    _widgetUrl = widgetUrl;
  }
  
  // Initialize the controller with the WebView
  void initialize(WebViewController webViewController) {
    controller = webViewController;
    _isInitialized = true;
    
    // Send initial configuration to widget if needed
    if (_position != DEFAULT_POSITION) {
      _sendMessageToWidget('SET_WIDGET_POSITION', {'position': _position});
    }
    
    if (_zIndex != DEFAULT_ZINDEX) {
      _sendMessageToWidget('SET_Z_INDEX', {'zIndex': _zIndex});
    }
  }
  

  void _logEvent(String message) {
    debugPrint('StuddyWidget: $message');
  }

  // Simplified message sending
  void _sendMessageToWidget(String type, [Map<String, dynamic>? payload]) {
    if (!_isInitialized) return;

    final message = {
      'type': type,
      if (payload != null) 'payload': payload,
    };

    final String jsonMessage = jsonEncode(message);
    controller.runJavaScript('''
      try {
        const message = $jsonMessage;
        window.postMessage(message, '*');
      } catch(e) {
        console.error('Error posting message:', e);
      }
    ''');
  }
  

  /*
  CLIENT API
  */
  Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Widget not initialized'};
    }

    final completer = Completer<Map<String, dynamic>>();
    
    // Create a subscription to listen for auth responses via the static stream
    final subscription = authResponseStream.listen((response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });
    
    
    // Send authentication request
    _sendMessageToWidget('AUTHENTICATE', authRequest.toJson());
    
    // Set a timeout
    Future.delayed(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        completer.complete({'success': false, 'error': 'Authentication timed out'});
      }
      // Clean up subscription
      subscription.cancel();
    });
    
    return completer.future;
  }
  
  // Control widget display
  Map<String, dynamic> display() {
    _sendMessageToWidget('DISPLAY_WIDGET');
    return {'success': true};
  }
  
  Map<String, dynamic> hide() {
    _sendMessageToWidget('HIDE_WIDGET');
    return {'success': true};
  }
  
  Map<String, dynamic> enlarge([String? screen]) {
    _sendMessageToWidget('ENLARGE_WIDGET', {'screen': screen ?? 'solver'});
    return {'success': true};
  }
  
  Map<String, dynamic> minimize() {
    _sendMessageToWidget('MINIMIZE_WIDGET');
    return {'success': true};
  }
  
  // Configure widget
  Map<String, dynamic> setWidgetPosition(String position) {
    if (position != 'left' && position != 'right') {
      return {'success': false, 'error': 'Position must be "left" or "right"'};
    }
    
    // Update internal position state
    _position = position;
    
    // Send message to the widget
    _sendMessageToWidget('SET_WIDGET_POSITION', {'position': position});
    
    return {'success': true};
  }
  
  Map<String, dynamic> setZIndex(int zIndex) {
    // Validate zIndex
    if (zIndex < 0) {
      return {'success': false, 'error': 'Z-index cannot be negative'};
    }
    
    // Update internal z-index state
    _zIndex = zIndex;
    
    // Send message to widget
    _sendMessageToWidget('SET_Z_INDEX', {'zIndex': zIndex});
    
    return {'success': true};
  }
  
  Map<String, dynamic> setTargetLocale(String locale) {
    _sendMessageToWidget('SET_TARGET_LOCALE', {'locale': locale});
    return {'success': true};
  }
  
  Map<String, dynamic> setPageData(PageData pageData) {
    _sendMessageToWidget('SET_PAGE_DATA', pageData.toJson());
    return {'success': true};
  }
}
//
//END OF CLIENT API
//





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
  
  // VARIABLES FOR ADJUSTING SIZING
  
  // State variables
  bool _isVisible = true;
  double _currentWidth = MOBILE_DEFAULT_WIDTH;
  double _currentHeight = MOBILE_DEFAULT_HEIGHT;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  

  
  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      
      // Add message interceptor channel
      ..addJavaScriptChannel(
        'MessageInterceptor',
        onMessageReceived: (JavaScriptMessage message) {
          //handle message affects here
          final messageData = jsonDecode(message.message);
          final String type = messageData['type'];
          final dynamic payload = messageData['payload'];

          if (type == 'AUTHENTICATION_RESPONSE') {
            // Process authentication response
            final authData = payload as Map<String, dynamic>;
            
            // Update the static response data
            StuddyWidgetController._latestAuthResponse = authData;
            
            // Notify any listeners via the static stream
            StuddyWidgetController._authResponseNotifier.add(authData);
            
          }

          if (type == 'SET_WIDGET_POSITION') {
            // Update position from widget if it sends a position update
            if (payload is Map && payload.containsKey('position')) {
              final position = payload['position'] as String;
              setState(() {
                widget.controller._position = position;
              });
            }
          }

          if (type == 'SET_Z_INDEX') {
            // Update z-index from widget if it sends a z-index update
            if (payload is Map && payload.containsKey('zIndex')) {
              final zIndex = payload['zIndex'] as int;
              setState(() {
                widget.controller._zIndex = zIndex;
              });
            }
          }

          if (type == 'WIDGET_DISPLAYED') {
            setState(() {
              _isVisible = true;
            });
          }
          
          if (type == 'WIDGET_HIDDEN') {
            setState(() {
              _isVisible = false;
            });
          }

          if (type == 'WIDGET_ENLARGED') {
            setState(() {
              final screenSize = MediaQuery.of(context).size;
              _currentWidth = screenSize.width * MOBILE_ENLARGED_WIDTH_PERCENTAGE;
              _currentHeight = screenSize.height * MOBILE_ENLARGED_HEIGHT_PERCENTAGE;
            });
          }

          if(type == 'WIDGET_MINIMIZED') {
            setState(() {
              _currentWidth = MOBILE_MINIMIZED_WIDTH;
              _currentHeight = MOBILE_MINIMIZED_HEIGHT;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('MOBILE: WebView started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('MOBILE: WebView finished loading: $url');
            
            _webViewController.runJavaScript('''              
              window.addEventListener('message', function(event) {
                // Check if message is from our domain or wildcard
                if (event.data && typeof event.data.type === 'string') {
                  MessageInterceptor.postMessage(JSON.stringify(event.data));
                }
              });
            ''');
            
            widget.controller.initialize(_webViewController);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('MOBILE: WebView error: ${error.description}');
          },
        ),
      );
    
    _webViewController.loadRequest(Uri.parse(widget.controller._widgetUrl));
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink(); // Hidden state
    }

    final screenSize = MediaQuery.of(context).size;

    // Choose the correct widget based on state
    Widget contentWidget;

    if (_currentWidth == MOBILE_MINIMIZED_WIDTH) {
      // MINIMIZED STATE
      contentWidget = SizedBox(
        width: MOBILE_MINIMIZED_WIDTH,
        height: MOBILE_MINIMIZED_HEIGHT,
        child: WebViewWidget(controller: _webViewController),
      );
    } else {
      // NORMAL OR ENLARGED STATE
      final bool isEnlarged = _currentWidth >= screenSize.width * 0.8;
      
      final double targetWidth = isEnlarged 
          ? screenSize.width * MOBILE_ENLARGED_WIDTH_PERCENTAGE
          : _currentWidth;
      
      final double targetHeight = isEnlarged 
          ? screenSize.height * MOBILE_ENLARGED_HEIGHT_PERCENTAGE
          : _currentHeight;
      
      contentWidget = Container(
        width: targetWidth,
        height: targetHeight,
        child: WebViewWidget(controller: _webViewController),
      );
    }

    final position = widget.controller._position;
    return Align(
      alignment: position == 'left' ? Alignment.bottomLeft : Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          child: contentWidget,
        ),
      ),
    );
  }
} 