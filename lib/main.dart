import 'package:flutter/material.dart';
import 'dart:convert';
import 'studdy_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  // Initialize WebView Platform
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize platform-specific implementations
  if (WebViewPlatform.instance == null) {
    // This is a simplified initialization that works cross-platform
    WebViewController();
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studdy Widget Control Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StuddyWidgetControlPanel(),
    );
  }
}

class StuddyWidgetControlPanel extends StatefulWidget {
  const StuddyWidgetControlPanel({super.key});

  @override
  State<StuddyWidgetControlPanel> createState() => _StuddyWidgetControlPanelState();
}

class _StuddyWidgetControlPanelState extends State<StuddyWidgetControlPanel> {
  late final StuddyWidgetController widgetController;
  String consoleOutput = '';

  @override
  void initState() {
    super.initState();
    
    // Initialize the widget controller with callbacks
    widgetController = StuddyWidgetController(
      onAuthenticationResponse: (response) {
        log('Authentication response received: ${json.encode(response)}');
      },
      onWidgetDisplayed: (_) {
        log('Widget displayed event received');
      },
      onWidgetHidden: (_) {
        log('Widget hidden event received');
      },
      onWidgetEnlarged: (_) {
        log('Widget enlarged event received');
      },
      onWidgetMinimized: (_) {
        log('Widget minimized event received');
      },
    );
    log('Widget controller initialized');
    
    // Initialize with default data
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    final defaultPageData = PageData(
      problems: [
        {
          'problemId': 'prob-123',
          'referenceTitle': 'Algebra Problem',
          'problemStatement': [
            {
              'text': 'Solve for x: 2x + 3 = 7'
            }
          ],
          'metaData': {
            'type': 'math',
            'topic': 'algebra'
          }
        }
      ],
      targetLocale: 'en-US'
    );
    
    widgetController.setPageData(defaultPageData);
    log('Default page data set');
  }

  void _authenticate() {
    // Sample authentication parameters based on the integration code
    String tenantId = 'studdy';
    String authMethod = 'jwt';
    String jwt = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3N0dWRkeS5haSIsImF1ZCI6Imh0dHBzOi8vc3R1ZGR5LmFpIiwic3ViIjoiYmlnU3RldmUiLCJpYXQiOjE3NDMyMjQzNzk3NzAsImV4cCI6MTc0MzI0MjM3OTc3MH0.ZrjgCJRQ5CXSxAdpgFFzYOUtAh1oFWJ2djVC-JHTLgTnehip8dbsVd4sWAVr3FfW8oNFy-U2gTh3DsSeeJ-lwBf3l5nWXBDZ0x7yNHLmAL8tOLS7_-jViL4M0vqGSPYUmJOO7cPVXd3NBICzGPQYD5RbqioDawc9W2DFYaQTgUFNXGNEu4ZAiUXTMtVx9kgcPgZPbnga3J6ox2ZYJsTP4l7hpqYcDgeIaXnhNEmdH5kNz6-EK8A_9lKoPu6MoaDScJ2ApSUck1ahCz1R7Qf9pUySrTGguDWvr5yYjUcr-ywHLa-5fgrzJsUv3AfhAzciPpVzgm3G_VUeglCRfjuzAw';
    
    // Create text editing controllers for the form fields
    final tenantIdController = TextEditingController(text: tenantId);
    final authMethodController = TextEditingController(text: authMethod);
    final jwtController = TextEditingController(text: jwt);
    //print out the jwt
    print('JWT: $jwt');
    
    // Show a dialog with the form
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Authentication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: tenantIdController,
                  decoration: const InputDecoration(
                    labelText: 'Tenant ID',
                    hintText: 'Required - your tenant identifier',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: authMethodController,
                  decoration: const InputDecoration(
                    labelText: 'Auth Method',
                    hintText: 'Should be "jwt" for JWT authentication',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: jwtController,
                  decoration: const InputDecoration(
                    labelText: 'JWT',
                    hintText: 'Your JWT token',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Authenticate'),
              onPressed: () {
                // Get the values from the text controllers
                tenantId = tenantIdController.text;
                authMethod = authMethodController.text;
                jwt = jwtController.text;
                
                // Create the auth request object with the user-provided values
                final authRequest = WidgetAuthRequest(
                  tenantId: tenantId,
                  authMethod: authMethod,
                  jwt: jwt,
                  version: '1.0',
                );
                
                // Send the authentication request
                widgetController.authenticate(authRequest);
                log('Authentication request sent:');
                log('- Tenant ID: $tenantId');
                log('- Auth Method: $authMethod');
                log('- JWT: ${jwt.isNotEmpty ? jwt.substring(0, 3) + "..." + jwt.substring(jwt.length - 3) : "empty"}');
                
                // Close the dialog
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void log(String message) {
    setState(() {
      consoleOutput += '$message\n';
    });
    print('StuddyWidget: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studdy Widget Control Panel'),
      ),
      body: Stack(
        children: [
          // Widget display takes the full screen (FIRST = bottom layer)
          Positioned.fill(
            bottom: 200, // Make room for the control panel
            child: StuddyWidget(controller: widgetController),
          ),
          
          // Control panel at the bottom (LAST = top layer)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Control buttons
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _authenticate,
                        child: const Text('Authenticate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.display(),
                        child: const Text('Display'),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.hide(),
                        child: const Text('Hide'),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.enlarge('solver'),
                        child: const Text('Enlarge (Solver)'),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.enlarge('tutor'),
                        child: const Text('Enlarge (Tutor)'),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.minimize(),
                        child: const Text('Minimize'),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.setWidgetPosition('right'),
                        child: const Text('Position Right'),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.setWidgetPosition('left'),
                        child: const Text('Position Left'),
                      ),
                      ElevatedButton(
                        onPressed: () => widgetController.setZIndex(2000),
                        child: const Text('Set zIndex: 2000'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Console output (mini log view)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Text(
                        consoleOutput,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}