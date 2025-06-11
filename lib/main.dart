//Example implementation of the Studdy Widget - Scrolling Test
//---Works for both mobile and web

import 'package:flutter/material.dart';
import 'dart:convert';
import 'studdy_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:webview_flutter_web/webview_flutter_web.dart'
    if (dart.library.io) 'platform/stub_web_package.dart';

// EXAMPLE IMPLEMENTAION OF HOW ONE SPECIFIES A CUSTOM WIDGET URL
const STUDDY_WIDGET_URL = 'https://widget.dev.studdy.ai';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Web platform initialization only
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studdy Widget Scrolling Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StuddyWidgetControlPanel(),
    );
  }
}

// Scrolling test panel for the Studdy Widget
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
    final problemJsonController = TextEditingController(
      text: jsonEncode([
      {
          "problemId": "da31c501-a71d-48d5-8035-b7db11c1a9bc",
          "referenceTitle": "Calculate math simple math",
          "problemStatement": [
            {"type": "text", "text": "3 + 7 + 5 + 2 + 4 + 1 + 6 ="},
          ],
          "solutionOptions": [
            {
              "label": "0",
              "contents": [
                {"type": "text", "text": "28"},
              ],
            },
            {
              "label": "1",
              "contents": [
                {"type": "text", "text": "29"},
              ],
            },
            {
              "label": "2",
              "contents": [
                {"type": "text", "text": "30"},
              ],
            },
            {
              "label": "3",
              "contents": [
                {"type": "text", "text": "27"},
              ],
            },
          ],
          "contextModifiers": {
            "solution": [
              {
                "type": "text",
                "text":
                    "{\"scoring_type\": \"exactMatch\", \"valid_response\": {\"score\": 1, \"value\": []}}",
              },
            ],
            "solutionSteps": [
              {
                "type": "text",
                "text":
                    "<strong>This is Instruction: Just plus it</strong>\n3 + 7 + 5 + 2 + 4 + 1 + 6 =<br>\n10 + 5 + 2 +4 + 1 +6 =<br>\n15 + 2 + 4 + 1 +6 =<br>\n17 + 4 + 1 +6 =<br>\n21 + 1 + 6 =<br>\n22 +6 =<br>\n28",
              },
            ],
          },
        },
        {
          "problemId": "85027d5a-625e-4182-ace8-289cd12c53af",
          "referenceTitle": "Calculate math simple math",
          "problemStatement": [
            {"type": "text", "text": "What is capital of VietNam?"},
          ],
          "solutionOptions": [
            {
              "label": "0",
              "contents": [
                {"type": "text", "text": "Ho Chi Minh"},
              ],
            },
            {
              "label": "1",
              "contents": [
                {"type": "text", "text": "Da Nang"},
              ],
            },
            {
              "label": "2",
              "contents": [
                {"type": "text", "text": "Ha Noi"},
              ],
            },
          ],
          "contextModifiers": {
            "solution": [
              {
                "type": "text",
                "text":
                    "{\"scoring_type\": \"exactMatch\", \"valid_response\": {\"score\": 1, \"value\": []}}",
              },
            ],
            "solutionSteps": [
              {"type": "text", "text": ""},
            ],
          },
        },
        {
          "problemId": "df84706e-6e1d-4885-9709-815a4ef485d0",
          "referenceTitle": "Calculate math simple math",
          "problemStatement": [
            {
              "type": "text",
              "text":
                  "Calculate multiple math\n3 + 3 =blank<br>\n3 * 3 =blank<br>\n3 / 3 =blank",
            },
          ],
          "contextModifiers": {
            "solution": [
              {
                "type": "text",
                "text":
                    "{\"scoring_type\": \"exactMatch\", \"valid_response\": {\"score\": 1, \"value\": [6, 9, 1]}, \"enable_fullwidth_scoring\": true}",
              },
            ],
            "solutionSteps": [
              {"type": "text", "text": ""},
            ],
          },
        },
      ]),
    );

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

  void _setTargetLocale() {
    final localeController = TextEditingController(text: 'en-US');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Target Locale'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              child: const Text('Set Locale'),
              onPressed: () {
                try {
                  final locale = localeController.text;
                  if (locale.isEmpty) {
                    throw WidgetDataException('Locale cannot be empty');
                  }
                  
                  final response = StuddyWidget.setTargetLocale(locale);
                  log('Target locale set successfully: $locale');
                  log('Response: ${json.encode(response)}');
                  Navigator.of(context).pop();
                } catch (e) {
                  log('Error setting target locale: $e');
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

  // Creates scrollable content with many items
  Widget _buildScrollableContent() {
    return ListView.builder(
      itemCount: 50,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scrollable Content #${index + 1}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is content to test if scrolling works when the Studdy Widget is displayed. '
                  'Try scrolling on this area with your cursor on the right side of the screen where the widget appears. '
                  'Item ${index + 1} of 50.',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget build(BuildContext context) {
    // Check if the screen width indicates a mobile device (less than 600 pixels)
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Control panel widget same as the original file
    Widget controlPanel = Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      width: isMobile ? double.infinity : 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Testing Scrolling with Studdy Widget', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Basic widget controls - with only the ones we need for testing
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.start,
                    children: [
                      // Add a new button to check widget readiness
                      ElevatedButton(
                        onPressed: () {
                          final isReady = StuddyWidget.isReady();
                          log('Widget ready status: $isReady');
                          
                          // Show visual feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Widget is ${isReady ? 'READY' : 'NOT READY'}'),
                              backgroundColor: isReady ? Colors.green : Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Check Ready'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _authenticate,
                        child: const Text('Authenticate'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                      ElevatedButton(
                        onPressed: _setPageData,
                        child: const Text('Set Page Data'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      ),
                      ElevatedButton(
                        onPressed: _setTargetLocale,
                        child: const Text('Set Locale'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          try {
                            final response = StuddyWidget.display();
                            log('Widget display command sent');
                            log('Response: ${json.encode(response)}');
                          } catch (e) {
                            log('Error displaying widget: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Display'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          try {
                            final response = StuddyWidget.hide();
                            log('Widget hide command sent');
                            log('Response: ${json.encode(response)}');
                          } catch (e) {
                            log('Error hiding widget: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Hide'),
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
                        onPressed: () {
                          try {
                            final response = StuddyWidget.minimize();
                            log('Widget minimize command sent');
                            log('Response: ${json.encode(response)}');
                          } catch (e) {
                            log('Error minimizing widget: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Minimize')
                      ),
                                        ElevatedButton(
                    onPressed: () {
                      try {
                        final response = StuddyWidget.enlarge('solver');
                        log('Widget enlarge (solver) command sent');
                        log('Response: ${json.encode(response)}');
                      } catch (e) {
                        log('Error enlarging widget: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Enlarge (Solver)')
                  ),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        final response = StuddyWidget.enlarge('tutor');
                        log('Widget enlarge (tutor) command sent');
                        log('Response: ${json.encode(response)}');
                      } catch (e) {
                        log('Error enlarging widget: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Enlarge (Tutor)')
                  ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: isMobile ? 100 : 200,
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

    // This layout combines scrollable content with the widget
    // The widget is placed using the exact same mechanism as main.dart
    Widget combinedDisplayArea = Expanded(
      child: Stack(
        children: [
          // Scrollable content underneath
          _buildScrollableContent(),
          
          // The StuddyWidget - will be visible when showWidget is true
          //put int
          StuddyWidget(customWidgetUrl: STUDDY_WIDGET_URL),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Studdy Widget Scrolling Test')),
      body: isMobile
          ? Column(
              children: [
                // Top control panel for mobile
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4, 
                  child: controlPanel,
                ),
                // Bottom combined display area
                combinedDisplayArea,
              ],
            )
          : Row(
              children: [
                // Left side control panel for web
                controlPanel,
                // Right side combined display area
                combinedDisplayArea,
              ],
            ),
    );
  }
} 