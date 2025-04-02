import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

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
  String _widgetUrl = 'https://pr-468-widget.dev.studdy.ai';
  
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
    String widgetUrl = 'https://pr-468-widget.dev.studdy.ai',
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
        print('MOBILE JS CHANNEL: Message received: ${message.message}');
        // Note: Message handling is now done in the _StuddyWidgetState class
      },
    );
    
    // Inject JavaScript to intercept window.postMessage calls
    controller.runJavaScript('''
      (function() {
        console.log('Preparing to set up message listener...');
        
        // Wait a short time to ensure the channel is registered
        setTimeout(function() {
          console.log('Setting up message listener on WebView');
          
          // Check if channel exists before adding listener
          if (typeof window.WidgetChannel !== 'undefined') {
            console.log('WidgetChannel is available!');
          } else {
            console.error('WidgetChannel is NOT available yet!');
          }
          
          // Function to safely post a message to Flutter
          window.safePostToFlutter = function(data) {
            try {
              if (window.WidgetChannel && typeof window.WidgetChannel.postMessage === 'function') {
                const jsonString = JSON.stringify(data);
                window.WidgetChannel.postMessage(jsonString);
                return true;
              } else {
                console.log('WidgetChannel not available, storing message for later');
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
              console.log('Processing ' + window._pendingMessages.length + ' stored messages');
              while (window._pendingMessages.length > 0) {
                const msg = window._pendingMessages.shift();
                window.safePostToFlutter(msg);
              }
            }
          };
          
          // Check every second if WidgetChannel is available to process stored messages
          setInterval(window.processStoredMessages, 1000);
          
          window.addEventListener('message', function(event) {
            console.log('WIDGET RECEIVED MESSAGE:', JSON.stringify(event.data));
            
            // Check if it has a valid message format
            if (event.data && typeof event.data.type === 'string') {
              // Send to Flutter via JavaScriptChannel
              const success = window.safePostToFlutter(event.data);
              if (success) {
                console.log('Successfully forwarded message to Flutter: ' + event.data.type);
              } else {
                console.log('Message saved for later delivery: ' + event.data.type);
              }
            } else {
              console.log('Ignored message with invalid format');
            }
          });
          
          // Let Flutter know the listener is set up
          window.safePostToFlutter({
            type: 'INIT_COMPLETE',
            payload: { success: true }
          });
          
          console.log('Message listener setup complete on WebView');
        }, 500); // Wait 500ms for the channel to be registered
      })();
    ''');
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
    print('MOBILE SENDING: $type message to widget');
    controller.runJavaScript('''
      (function() {
        try {
          const message = $jsonMessage;
          console.log('FLUTTER -> WIDGET: Sending message:', JSON.stringify(message));
          
          // Create an event to dispatch
          const msgEvent = new MessageEvent('message', {
            data: message,
            origin: window.location.origin,
            source: window
          });
          
          // First try direct window.postMessage
          window.postMessage(message, '*');
          
          // Then also try direct dispatch method for better compatibility
          window.dispatchEvent(msgEvent);
          
          console.log('Message sent via two methods');
        } catch(e) {
          console.error('Error posting message:', e);
        }
      })();
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
  
  // Define constants for widget dimensions
  static const double MINIMIZED_WIDTH = 80;
  static const double MINIMIZED_HEIGHT = 80;
  static const double DEFAULT_WIDTH = 400;
  static const double DEFAULT_HEIGHT = 600;
  
  // State variables for widget dimensions and visibility
  bool _isVisible = true;
  double _currentWidth = DEFAULT_WIDTH;
  double _currentHeight = DEFAULT_HEIGHT;
  String _position = 'right'; // default position
  bool _isListenerSetup = false;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
    // We'll set up listeners after the first frame when context is available
    
    // Schedule a connectivity check after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkWebViewConnectivity();
      }
    });
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
        _isVisible = true; // Ensure it's visible when minimized
      });
      print('MOBILE UI: Widget minimized, size set to $_currentWidth x $_currentHeight');
    };
    
    widget.controller.onWidgetEnlarged = (payload) {
      if (!mounted) return;
      
      // Get current screen size for enlarged dimensions
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _currentWidth = screenSize.width * 0.9;
        _currentHeight = screenSize.height * 0.9;
        _isVisible = true; // Ensure it's visible when enlarged
        
        // Check if screen type is specified in payload
        if (payload.containsKey('screen')) {
          print('Enlarging to screen type: ${payload['screen']}');
        }
      });
      print('MOBILE UI: Widget enlarged, size set to $_currentWidth x $_currentHeight');
    };
    
    widget.controller.onWidgetDisplayed = (_) {
      if (!mounted) return;
      setState(() {
        _isVisible = true;
        // Reset to default size if not already minimized
        if (_currentWidth != MINIMIZED_WIDTH) {
          _currentWidth = DEFAULT_WIDTH;
          _currentHeight = DEFAULT_HEIGHT;
        }
      });
      print('MOBILE UI: Widget displayed, visibility set to $_isVisible, size: $_currentWidth x $_currentHeight');
    };
    
    widget.controller.onWidgetHidden = (_) {
      if (!mounted) return;
      setState(() {
        _isVisible = false;
      });
      print('MOBILE UI: Widget hidden, visibility set to $_isVisible');
    };
    
    widget.controller.onAuthenticationResponse = (response) {
      if (!mounted) return;
      print('Processing auth response: ${jsonEncode(response)}');
      
      if (response.containsKey('publicConfigData')) {
        final config = response['publicConfigData'];
        if (config != null) {
          setState(() {
            if (config['defaultWidgetPosition'] != null) {
              _position = config['defaultWidgetPosition'];
              print('Setting position to: $_position');
            }
            
            if (config['displayOnAuth'] == true) {
              _isVisible = true;
              print('Setting visible due to displayOnAuth');
            }
          });
          print('MOBILE UI: Authentication response processed, position=$_position, visible=$_isVisible');
        }
      }
    };
  }
  
  Future<void> _initializeWebView() async {
    print('MOBILE: Initializing WebView controller with URL: ${widget.controller._widgetUrl}');
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      // Add JavaScript channels first, before any page loads
      ..addJavaScriptChannel(
        'WidgetChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('MOBILE JS CHANNEL: Message received: ${message.message}');
          _handleWidgetMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'ConsoleChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('WEBVIEW CONSOLE: ${message.message}');
        },
      )
      // Set up navigation delegate
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('MOBILE: WebView started loading: $url');
          },
          onPageFinished: (String url) {
            print('MOBILE: WebView finished loading: $url');
            
            // Inject console.log interceptor AFTER page is loaded
            _webViewController.runJavaScript('''
              (function() {
                console.log('Setting up console interceptor');
                const originalLog = console.log;
                const originalError = console.error;
                const originalWarn = console.warn;
                
                console.log = function() {
                  if (window.ConsoleChannel) {
                    const args = Array.from(arguments).map(a => String(a)).join(' ');
                    window.ConsoleChannel.postMessage('LOG: ' + args);
                  }
                  return originalLog.apply(console, arguments);
                };
                
                console.error = function() {
                  if (window.ConsoleChannel) {
                    const args = Array.from(arguments).map(a => String(a)).join(' ');
                    window.ConsoleChannel.postMessage('ERROR: ' + args);
                  }
                  return originalError.apply(console, arguments);
                };
                
                console.warn = function() {
                  if (window.ConsoleChannel) {
                    const args = Array.from(arguments).map(a => String(a)).join(' ');
                    window.ConsoleChannel.postMessage('WARN: ' + args);
                  }
                  return originalWarn.apply(console, arguments);
                };
                
                // Add a message listener using the WidgetChannel pattern
                window.addEventListener('message', function(event) {
                  if (event.data && typeof event.data.type === 'string') {
                    console.log('Message received:', event.data.type);
                    // Send to Flutter via the JavaScriptChannel
                    window.WidgetChannel.postMessage(JSON.stringify(event.data));
                  }
                });
                
                console.log('Console interceptor and message listeners ready');
              })();
            ''');
            
            // Now initialize controller after page is loaded and scripts injected
            widget.controller.initialize(_webViewController);
            
            // Test channel communication
            _webViewController.runJavaScript('''
              console.log('Testing channel communication...');
              if (window.WidgetChannel) {
                window.WidgetChannel.postMessage(JSON.stringify({
                  type: 'INIT_COMPLETE',
                  payload: { success: true }
                }));
                console.log('Test message sent successfully');
              } else {
                console.error('WidgetChannel not available!');
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            print('MOBILE: WebView error: ${error.description}');
          },
        ),
      );
    
    // Load the URL last
    _webViewController.loadRequest(Uri.parse(widget.controller._widgetUrl));
  }
  
  // Add a method to check connectivity and run diagnostic tests
  Future<void> _checkWebViewConnectivity() async {
    if (!widget.controller._isInitialized || _webViewController == null) {
      print('WebView not initialized yet');
      return;
    }
    
    print('Running WebView connectivity test...');
    try {
      // Check if JavaScript is enabled
      _webViewController.runJavaScript('''
        (function() {
          console.log('======== CONNECTIVITY TEST STARTING ========');
          
          // Check if our channel exists
          if (typeof window.WidgetChannel !== 'undefined') {
            console.log('✅ WidgetChannel is defined');
            
            // Check if postMessage exists
            if (typeof window.WidgetChannel.postMessage === 'function') {
              console.log('✅ window.WidgetChannel.postMessage is a function');
              
              // Try to send a test message
              try {
                window.WidgetChannel.postMessage(JSON.stringify({
                  type: 'CONNECTIVITY_TEST',
                  payload: { timestamp: Date.now() }
                }));
                console.log('✅ Test message sent successfully');
              } catch(e) {
                console.error('❌ Failed to send test message:', e);
              }
            } else {
              console.error('❌ window.WidgetChannel.postMessage is NOT a function');
            }
          } else {
            console.error('❌ WidgetChannel is NOT defined');
            
            // Check what channels are available
            const propertyNames = Object.getOwnPropertyNames(window);
            console.log('Available window properties:', propertyNames.join(', '));
          }

          // Check message event listener
          try {
            const testEvent = new MessageEvent('message', {
              data: {type: 'TEST_EVENT', payload: {}},
              origin: window.location.origin,
              source: window
            });
            
            window.dispatchEvent(testEvent);
            console.log('✅ Test event dispatched');
          } catch(e) {
            console.error('❌ Error dispatching test event:', e);
          }
          
          console.log('======== CONNECTIVITY TEST COMPLETE ========');
        })();
      ''');
    } catch (e) {
      print('Error running connectivity test: $e');
    }
  }
  
  // Handle messages from the widget JavaScriptChannel
  void _handleWidgetMessage(String messageString) {
    try {
      print('MOBILE PROCESSING: Raw message: $messageString');
      final message = jsonDecode(messageString);
      
      if (!message.containsKey('type')) {
        print('Invalid message format, missing type field');
        return;
      }
      
      final String type = message['type'];
      final dynamic payload = message['payload'];
      
      print('MOBILE SUCCESS: Received message of type: $type');
      
      // Call the appropriate callback on the controller
      switch (type) {
        case 'AUTHENTICATION_RESPONSE':
          print('AUTH RESPONSE received with payload: ${jsonEncode(payload)}');
          if (widget.controller.onAuthenticationResponse != null) {
            widget.controller.onAuthenticationResponse!(payload);
          }
          break;
        case 'WIDGET_DISPLAYED':
          print('WIDGET_DISPLAYED event received');
          if (widget.controller.onWidgetDisplayed != null) {
            widget.controller.onWidgetDisplayed!(payload ?? {});
          }
          break;
        case 'WIDGET_HIDDEN':
          print('WIDGET_HIDDEN event received');
          if (widget.controller.onWidgetHidden != null) {
            widget.controller.onWidgetHidden!(payload ?? {});
          }
          break;
        case 'WIDGET_ENLARGED':
          print('WIDGET_ENLARGED event received');
          if (widget.controller.onWidgetEnlarged != null) {
            widget.controller.onWidgetEnlarged!(payload ?? {});
          }
          break;
        case 'WIDGET_MINIMIZED':
          print('WIDGET_MINIMIZED event received');
          if (widget.controller.onWidgetMinimized != null) {
            widget.controller.onWidgetMinimized!(payload ?? {});
          }
          break;
        case 'INIT_COMPLETE':
          print('Widget initialization complete');
          break;
        default:
          print('Unknown message type: $type');
      }
    } catch (e) {
      print('ERROR parsing message: $e');
      print('Message that failed: $messageString');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print('MOBILE: Building widget with visibility: $_isVisible, width: $_currentWidth, height: $_currentHeight');
    return Stack(
      children: [
        // The main widget
        Visibility(
          visible: _isVisible,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: widget.width ?? _currentWidth,
            height: widget.height ?? _currentHeight,
            alignment: _position == 'left' ? Alignment.bottomLeft : Alignment.bottomRight,
            margin: const EdgeInsets.all(20),
            child: WebViewWidget(controller: _webViewController),
          ),
        ),
        
        // Add a debug button overlay for testing
        if (widget.controller._isInitialized)
          Positioned(
            top: 10,
            right: 10,
            child: Opacity(
              opacity: 0.7,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        print('Testing widget communication...');
                        // Run a test script that verifies communication
                        _webViewController.runJavaScript('''
                          console.log('TEST: Sending test messages to Flutter...');
                          
                          // Test minimize
                          window.postMessage({
                            type: 'WIDGET_MINIMIZED',
                            payload: {}
                          }, '*');
                          
                          // Wait 2 seconds then test enlarge
                          setTimeout(() => {
                            window.postMessage({
                              type: 'WIDGET_ENLARGED',
                              payload: { screen: 'solver' }
                            }, '*');
                            console.log('TEST: Sent enlarge message');
                          }, 2000);
                        ''');
                      },
                      tooltip: 'Test Widget Communication',
                    ),
                    const Text('Test', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
} 