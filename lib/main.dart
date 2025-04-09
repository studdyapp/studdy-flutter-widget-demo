import 'package:flutter/material.dart';
import 'dart:convert';
import 'studdy_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

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

  // Initialize the StuddyWidget (optional)
  // StuddyWidget.initialize(); // Not needed as it will use the default URL
  
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
              onPressed: () {
                final authRequest = WidgetAuthRequest(
                  tenantId: tenantIdController.text,
                  authMethod: authMethodController.text,
                  jwt: jwtController.text,
                  version: '1.0',
                );
                StuddyWidget.authenticate(authRequest);
                log('Authentication request sent');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  void log(String message) {
    setState(() => consoleOutput += '$message\n');
    print('StuddyWidget: $message');
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
                  final problems = jsonDecode(problemJsonController.text) as List;
                  final pageData = PageData(
                    problems: List<Map<String, dynamic>>.from(problems),
                    targetLocale: localeController.text,
                  );
                  StuddyWidget.setPageData(pageData);
                  log('Page data set');
                  Navigator.of(context).pop();
                } catch (e) {
                  log('Error setting page data: $e');
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
                  StuddyWidget.setZIndex(zIndex);
                  log('Z-Index set to $zIndex');
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

  void _setWidgetUrl() {
    // Get the current widget URL from StuddyWidget
    final urlController = TextEditingController(text: StuddyWidget.widgetUrl);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Widget URL'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(labelText: 'Widget URL'),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Set URL'),
              onPressed: () {
                // Update the widget URL
                StuddyWidget.initialize(widgetUrl: urlController.text);
                log('Widget URL set to ${urlController.text}');
                Navigator.of(context).pop();
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
                    onPressed: _setWidgetUrl,
                    child: const Text('Set Widget URL'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Authenticate'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () => StuddyWidget.display(),
                    child: const Text('Display')
                  ),
                  ElevatedButton(
                    onPressed: () => StuddyWidget.hide(),
                    child: const Text('Hide')
                  ),
                  ElevatedButton(
                    onPressed: () => StuddyWidget.enlarge('solver'),
                    child: const Text('Enlarge (Solver)')
                  ),
                  ElevatedButton(
                    onPressed: () => StuddyWidget.enlarge('tutor'),
                    child: const Text('Enlarge (Tutor)')
                  ),
                  ElevatedButton(
                    onPressed: () => StuddyWidget.minimize(),
                    child: const Text('Minimize')
                  ),
                  ElevatedButton(
                    onPressed: () => StuddyWidget.setWidgetPosition('right'),
                    child: const Text('Position Right')
                  ),
                  ElevatedButton(
                    onPressed: () => StuddyWidget.setWidgetPosition('left'),
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
      child: StuddyWidget(
        onAuthenticationResponse: (response) => log('MAIN.dart: Authentication response received: ${json.encode(response)}'),
        onWidgetDisplayed: (_) => log('MAIN.dart: Widget displayed event received'),
        onWidgetHidden: (_) => log('MAIN.dart: Widget hidden event received'),
        onWidgetEnlarged: (_) => log('MAIN.dart: Widget enlarged event received'),
        onWidgetMinimized: (_) => log('MAIN.dart: Widget minimized event received'),
      ),
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