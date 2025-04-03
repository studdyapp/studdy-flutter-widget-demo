import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';

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

// Move constants from _StuddyWidgetState to class-level constants for access by the controller
const String WIDGET_MAX_HEIGHT = '95%';
const String WIDGET_MAX_WIDTH = '60%';
const String MINIMIZED_WIDGET_HEIGHT = '120px';
const String MINIMIZED_WIDGET_WIDTH = '120px';
const String ENLARGED_WIDGET_HEIGHT = '95%';
const String ENLARGED_WIDGET_WIDTH = '464px';
const String WIDGET_OFFSET = '10px';
const int DEFAULT_ZINDEX = 9999;
const String DEFAULT_POSITION = 'right';

// For mobile translation (percentage values need to be converted to explicit dimensions)
const double DEFAULT_WIDTH = 400.0;
const double DEFAULT_HEIGHT = 600.0;

// Widget class that can be used to control the StuddyWidget
class StuddyWidgetController {
  late WebViewController controller;
  bool _isInitialized = false;
  String _widgetUrl = 'https://pr-476-widget.dev.studdy.ai';
  
  // Message handler callbacks
  Function(Map<String, dynamic>)? onAuthenticationResponse;
  Function(Map<String, dynamic>)? onWidgetDisplayed;
  Function(Map<String, dynamic>)? onWidgetHidden;
  Function(Map<String, dynamic>)? onWidgetEnlarged;
  Function(Map<String, dynamic>)? onWidgetMinimized;
  
  // Widget configuration properties
  String? _widgetPosition;
  int? _zIndex;
  bool _displayOnAuth = false;
  String? _targetLocale;
  
  // Debounce variables 
  DateTime? _lastMessageTime;
  String? _lastMessageType;
  static const _debounceTimeMs = 500;
  
  // Add this field to the StuddyWidgetController class
  Completer<Map<String, dynamic>>? _lastAuthCompleter;
  
  StuddyWidgetController({
    this.onAuthenticationResponse,
    this.onWidgetDisplayed,
    this.onWidgetHidden,
    this.onWidgetEnlarged,
    this.onWidgetMinimized,
    String widgetUrl = 'https://pr-476-widget.dev.studdy.ai',
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
    
    // Add a message interceptor channel for direct logging
    controller.addJavaScriptChannel(
      'DirectInterceptor',
      onMessageReceived: (JavaScriptMessage message) {
        debugPrint('I RECEIVED A MESSAGE: ${message.message}');
      },
    );
    
    // Keep this message queueing system as it's helping with authentication responses
    controller.runJavaScript('''
      (function() {
        // Function to safely post a message to Flutter
        window.safePostToFlutter = function(data) {
          try {
            if (window.WidgetChannel && typeof window.WidgetChannel.postMessage === 'function') {
              const jsonString = JSON.stringify(data);
              window.WidgetChannel.postMessage(jsonString);
              return true;
            } else {
              // Store for later delivery
              if (!window._pendingMessages) window._pendingMessages = [];
              window._pendingMessages.push(data);
              return false;
            }
          } catch(e) {
            console.error('Error in safePostToFlutter:', e);
            return false;
          }
        };
        
        // Try to process any pending messages
        window.processStoredMessages = function() {
          if (window._pendingMessages && window._pendingMessages.length > 0 && window.WidgetChannel) {
            while (window._pendingMessages.length > 0) {
              const msg = window._pendingMessages.shift();
              window.safePostToFlutter(msg);
            }
          }
        };
        
        // Check periodically if WidgetChannel is available to process stored messages
        setInterval(window.processStoredMessages, 1000);
        
        // Listen for messages - especially those from our target domain
        window.addEventListener('message', function(event) {
          // Check if this is from our domain of interest
          const fromTargetDomain = event.origin.includes('pr-476-widget.dev.studdy.ai');
          
          if (event.data && typeof event.data.type === 'string') {
            // Log all messages received
            if (window.DirectInterceptor) {
              const source = fromTargetDomain ? 'FROM TARGET DOMAIN: ' : '';
              window.DirectInterceptor.postMessage('I RECEIVED A MESSAGE ' + source + JSON.stringify(event.data));
            }
            window.safePostToFlutter(event.data);
          }
        });
      })();
    ''');
  }

  // Handle messages from the widget via JavaScriptChannel
  void _handleWidgetMessage(String messageString) {
    try {
      final message = jsonDecode(messageString);
      final String type = message['type'] ?? '';
      final dynamic payload = message['payload'];
      print('I RECEIVED A MESSAGE: $message');

      // Special handling for authentication responses to resolve the promise
      if (type == 'AUTHENTICATION_RESPONSE' && _lastAuthCompleter != null && !_lastAuthCompleter!.isCompleted) {
        print('EUREKA! Completing auth request via general message handler');
        _lastAuthCompleter!.complete(payload ?? {});
        _lastAuthCompleter = null;
      }

      // Debounce logic
      final now = DateTime.now();
      if (_lastMessageType == type && 
          _lastMessageTime != null && 
          now.difference(_lastMessageTime!).inMilliseconds < _debounceTimeMs) {
        return;
      }
      
      _lastMessageType = type;
      _lastMessageTime = now;
      
      // Call the appropriate callback on the controller
      switch (type) {
        case 'AUTHENTICATION_RESPONSE':
          if (onAuthenticationResponse != null) {
            print('EUREKA! Calling onAuthenticationResponse callback');
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
      }
    } catch (e) {
      debugPrint('StuddyWidget: Error parsing message: $e');
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
  
  // Authenticate with the Studdy platform using a direct promise approach
  Future<Map<String, dynamic>> authenticate(WidgetAuthRequest authRequest) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Widget not initialized'};
    }

    final completer = Completer<Map<String, dynamic>>();
    _lastAuthCompleter = completer;
    
    controller.addJavaScriptChannel(
      'AuthChannel',
      onMessageReceived: (JavaScriptMessage message) {
        // Direct handling of authentication responses
        final data = jsonDecode(message.message);
        if (_lastAuthCompleter != null && !_lastAuthCompleter!.isCompleted) {
          _lastAuthCompleter!.complete(data);
        }
        if (onAuthenticationResponse != null) {
          onAuthenticationResponse!(data);
        }
      },
    );

    controller.runJavaScript('''
      const authData = ${jsonEncode(authRequest.toJson())};
      window.postMessage({ type: 'AUTHENTICATE', payload: authData }, '*');
      
      // Listen for authentication responses and directly send to channel
      const authListener = function(event) {
        if (event.data && event.data.type === 'AUTHENTICATION_RESPONSE') {
          console.log('EUREKA: Auth response received');
          window.AuthChannel.postMessage(JSON.stringify(event.data.payload || {}));
          // Remove listener to prevent memory leaks
          window.removeEventListener('message', authListener);
        }
      };
      window.addEventListener('message', authListener);
    ''');
    
    return completer.future;
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
    return {'success': true};
  }
  
  // Configure widget
  Map<String, dynamic> setWidgetPosition(String position) {
    _widgetPosition = position;
    _sendMessageToWidget('SET_WIDGET_POSITION', {'position': position});
    return {'success': true};
  }
  
  Map<String, dynamic> setZIndex(int zIndex) {
    _zIndex = zIndex;
    _sendMessageToWidget('SET_Z_INDEX', {'zIndex': zIndex});
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
  
  // Define numeric constants for mobile dimensions
  static const double MINIMIZED_WIDTH = 120.0; // Use 120 to match web version
  static const double MINIMIZED_HEIGHT = 120.0;
  static const double ENLARGED_WIDTH_PERCENTAGE = 0.9;
  static const double ENLARGED_HEIGHT_PERCENTAGE = 0.9;
  
  // State variables
  bool _isVisible = true;
  double _currentWidth = DEFAULT_WIDTH;
  double _currentHeight = DEFAULT_HEIGHT;
  String _position = DEFAULT_POSITION;
  bool _isListenerSetup = false;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isListenerSetup) {
      _setupWidgetListeners();
      _isListenerSetup = true;
    }
  }
  
  void _setupWidgetListeners() {
    // Set up the message handlers for the widget controller
    widget.controller.onWidgetMinimized = (_) {
      if (!mounted) return;
      setState(() {
        _currentWidth = MINIMIZED_WIDTH;
        _currentHeight = MINIMIZED_HEIGHT;
        _isVisible = true;
      });
    };
    
    widget.controller.onWidgetEnlarged = (payload) {
      if (!mounted) return;
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        // Make it explicitly larger than the default size
        _currentWidth = screenSize.width * ENLARGED_WIDTH_PERCENTAGE;
        _currentHeight = screenSize.height * ENLARGED_HEIGHT_PERCENTAGE;
        _isVisible = true;
      });
    };
    
    widget.controller.onWidgetDisplayed = (_) {
      if (!mounted) return;
      setState(() {
        _isVisible = true;
        if (_currentWidth == MINIMIZED_WIDTH) {
          _currentWidth = DEFAULT_WIDTH;
          _currentHeight = DEFAULT_HEIGHT;
        }
      });
    };
    
    widget.controller.onWidgetHidden = (_) {
      if (!mounted) return;
      setState(() {
        _isVisible = false;
      });
    };
    
    widget.controller.onAuthenticationResponse = (response) {
      if (!mounted) return;
      
      if (response.containsKey('publicConfigData')) {
        final config = response['publicConfigData'];
        if (config != null) {
          setState(() {
            if (config['defaultWidgetPosition'] != null) {
              _position = config['defaultWidgetPosition'];
            }
            
            if (config['displayOnAuth'] == true) {
              _isVisible = true;
            }
          });
        }
      }
    };
  }
  
  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'WidgetChannel',
        onMessageReceived: (JavaScriptMessage message) {
          widget.controller._handleWidgetMessage(message.message);
        },
      )
      // Add message interceptor channel
      ..addJavaScriptChannel(
        'MessageInterceptor',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('I RECEIVED A MESSAGE: ${message.message}');
        },
      )
      // Only keep the console channel if needed for debugging - remove in production
      ..addJavaScriptChannel(
        'ConsoleChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('WEBVIEW CONSOLE: ${message.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('MOBILE: WebView started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('MOBILE: WebView finished loading: $url');
            
            // Set up global message event listener
            _webViewController.runJavaScript('''
              console.log('Widget WebView loaded');
              
              // Add message event listener to capture all postMessage events
              window.addEventListener('message', function(event) {
                // Check if message is from our domain or wildcard
                if (event.data && typeof event.data.type === 'string') {
                  // Send to Flutter through MessageInterceptor channel
                  MessageInterceptor.postMessage(JSON.stringify(event.data));
                }
              });
            ''');
            
            // Initialize controller
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

    if (_currentWidth == MINIMIZED_WIDTH) {
      // MINIMIZED STATE
      contentWidget = SizedBox(
        width: MINIMIZED_WIDTH,
        height: MINIMIZED_HEIGHT,
        child: WebViewWidget(controller: _webViewController),
      );
    } else {
      // NORMAL OR ENLARGED STATE
      final bool isEnlarged = _currentWidth >= screenSize.width * 0.8;
      
      final double targetWidth = isEnlarged 
          ? screenSize.width * ENLARGED_WIDTH_PERCENTAGE
          : _currentWidth;
      
      final double targetHeight = isEnlarged 
          ? screenSize.height * ENLARGED_HEIGHT_PERCENTAGE
          : _currentHeight;
      
      contentWidget = Container(
        width: targetWidth,
        height: targetHeight,
        child: WebViewWidget(controller: _webViewController),
      );
    }

    // Position the content with proper alignment
    return Align(
      alignment: _position == 'left' ? Alignment.bottomLeft : Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: contentWidget,
        ),
      ),
    );
  }
} 