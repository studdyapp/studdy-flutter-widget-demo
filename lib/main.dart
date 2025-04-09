import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer';
import 'studdy_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'utils/widget_models.dart';

import 'package:webview_flutter_web/webview_flutter_web.dart'
    if (dart.library.io) 'stub_web_package.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-specific WebView initialization
  if (kIsWeb) {
    // Web platform initialization
    WebViewPlatform.instance = WebWebViewPlatform();
  } else {
    // Mobile platform initialization
    late final PlatformWebViewControllerCreationParams params;
    if (defaultTargetPlatform == TargetPlatform.android) {
      params = AndroidWebViewControllerCreationParams();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      params = WebKitWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    WebViewController.fromPlatformCreationParams(params);
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
  String consoleOutput = '';

  @override
  void initState() {
    super.initState();
  }

  void log(String message) {
    setState(() => consoleOutput += '$message\n');
    print('StuddyWidget: $message');
  }

  void _authenticate() {
    final tenantIdController = TextEditingController(text: 'leshko-test');
    final authMethodController = TextEditingController(text: 'jwt');
    final jwtController = TextEditingController(text: 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXItMSIsImlzcyI6Imh0dHBzOi8vc3R1ZGR5LmFpIiwiYXVkIjoic3R1ZGR5IiwidGVuYW50SWQiOiJsZXNoa28tdGVzdCIsInRpZXIiOiJwcmVtaXVtIiwiaWF0IjoxNzQzODIyMDM0LCJleHAiOjE3NzUzNTgwMzR9.TUwZcHuy2-gQjlgML4DeVr_VqUtD7InK1k4LlSuQ0TgdZCee4S6MSjbIz6j2ljQXVoiT8G5fvrWDzhkCHrCgFNbYpoXmF8Z_FXxuV-jhnmhuLCFlhUqhpDKSulHuqQMBwen47lLgE9qtdIFLO2z2s6HKlZr5A92lJZMLj5HO9waqC2K_zybR_EHAyLbtoTaH5Xty_44NHKWtUtBxzYbOPshol3nysjXgvffjINkFh5CVKNfuxOpQEmZx9spufAVoz2Hr73m-njxjZffXQxjikC3MEopENRud0T3K8RoF-K2ylcx9998W8G4eHkouooUlwZNBsFiFMHCKIdtgYNhr5A');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Authentication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tenantIdController,
                  decoration: const InputDecoration(labelText: 'Tenant ID'),
                ),
                TextField(
                  controller: authMethodController,
                  decoration: const InputDecoration(labelText: 'Auth Method'),
                ),
                TextField(
                  controller: jwtController,
                  decoration: const InputDecoration(labelText: 'JWT'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Authenticate'),
              onPressed: () async {
                final authRequest = WidgetAuthRequest(
                  tenantId: tenantIdController.text,
                  authMethod: authMethodController.text,
                  jwt: jwtController.text,
                );
                log('Authentication request sent');
                final response = await StuddyWidget.authenticate(authRequest);
                log('Authentication response: ${json.encode(response)}');
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _setPageData() {
    final problemJsonController = TextEditingController(text: jsonEncode([
      {
        'problemId': 'prob-123',
        'referenceTitle': 'Algebra Problem',
        'problemStatement': [
          {
            'text': 'Solve for x: 2x + 3 = 7',
            'type': 'text'
          }
        ],
        'metaData': {
          'type': 'math',
          'topic': 'algebra'
        }
      }
    ]));
    final localeController = TextEditingController(text: 'en-US');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Page Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: problemJsonController,
                  decoration: const InputDecoration(labelText: 'Problems JSON'),
                  maxLines: 10,
                ),
                TextField(
                  controller: localeController,
                  decoration: const InputDecoration(labelText: 'Target Locale'),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Set Page Data'),
              onPressed: () {
                try {
                  // Try to parse JSON directly
                  final jsonData = problemJsonController.text;
                  
                  // Create page data with simple parsing and validation
                  PageData pageData;
                  
                  try {
                    // Use the helper method to parse and validate JSON
                    pageData = PageData.fromJsonString(jsonData);
                    
                    // Override targetLocale if provided in UI
                    if (localeController.text.isNotEmpty) {
                      pageData = PageData(
                        problems: pageData.problems,
                        targetLocale: localeController.text,
                      );
                    }
                  } catch (e) {
                    // Show validation error
                    throw WidgetDataException('Invalid JSON format: ${e.toString()}');
                  }
                  
                  // Send the data to the widget
                  final response = StuddyWidget.setPageData(pageData);
                  log('Page data set successfully');
                  log('Response: ${json.encode(response)}');
                  Navigator.of(context).pop();
                } catch (e) {
                  log('Error setting page data: $e');
                  // Show error to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _setZIndex() {
    final zIndexController = TextEditingController(text: '2000');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Z-Index'),
          content: TextField(
            controller: zIndexController,
            decoration: const InputDecoration(labelText: 'Z-Index Value'),
            keyboardType: TextInputType.number,
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Set Z-Index'),
              onPressed: () {
                try {
                  final zIndex = int.parse(zIndexController.text);
                  final response = StuddyWidget.setZIndex(zIndex);
                  log('Z-Index set to $zIndex');
                  log('Response: ${json.encode(response)}');
                  Navigator.of(context).pop();
                } catch (e) {
                  log('Error setting Z-Index: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    // Check if the screen width indicates a mobile device (less than 600 pixels)
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Control panel widget to be reused in both layouts
    Widget controlPanel = Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      width: isMobile ? double.infinity : 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Authenticate'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final response = StuddyWidget.display();
                      log('Widget display command sent');
                      log('Response: ${json.encode(response)}');
                    },
                    child: const Text('Display')
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final response = StuddyWidget.hide();
                      log('Widget hide command sent');
                      log('Response: ${json.encode(response)}');
                    },
                    child: const Text('Hide')
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final response = StuddyWidget.enlarge('solver');
                      log('Widget enlarge (solver) command sent');
                      log('Response: ${json.encode(response)}');
                    },
                    child: const Text('Enlarge (Solver)')
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final response = StuddyWidget.enlarge('tutor');
                      log('Widget enlarge (tutor) command sent');
                      log('Response: ${json.encode(response)}');
                    },
                    child: const Text('Enlarge (Tutor)')
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final response = StuddyWidget.minimize();
                      log('Widget minimize command sent');
                      log('Response: ${json.encode(response)}');
                    },
                    child: const Text('Minimize')
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final response = StuddyWidget.setWidgetPosition('right');
                      log('Widget position (right) command sent');
                      log('Response: ${json.encode(response)}');
                    },
                    child: const Text('Position Right')
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final response = StuddyWidget.setWidgetPosition('left');
                      log('Widget position (left) command sent');
                      log('Response: ${json.encode(response)}');
                    },
                    child: const Text('Position Left')
                  ),
                  ElevatedButton(
                    onPressed: _setZIndex,
                    child: const Text('Set Z-Index'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: _setPageData,
                    child: const Text('Set Page Data'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: isMobile ? 100 : 200, // Smaller console on mobile
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Text(consoleOutput, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );

    // Widget display area
    Widget displayArea = Expanded(
      child: StuddyWidget(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Studdy Widget Control Panel')),
      body: isMobile
          ? Column(
              children: [
                // Top widget display area for mobile
                displayArea,
                // Bottom control panel for mobile (height constrained)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
                  child: controlPanel,
                ),
              ],
            )
          : Row(
              children: [
                // Left side control panel for web
                controlPanel,
                // Right side widget display area for web
                displayArea,
              ],
            ),
    );
  }
}