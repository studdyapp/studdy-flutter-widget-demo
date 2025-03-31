
# Studdy Widget for Flutter

This package allows you to seamlessly integrate the Studdy learning widget into your Flutter applications. The Studdy widget provides interactive educational assistance that can be embedded directly within your app.

## Table of Contents
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Authentication](#authentication)
- [Widget Customization](#widget-customization)
- [API Reference](#api-reference)
- [Event Callbacks](#event-callbacks)
- [Example Implementation](#example-implementation)
- [Troubleshooting](#troubleshooting)

## Installation

Add the Studdy Widget package to your `pubspec.yaml`:

```yaml
dependencies:
  studdy_widget: ^1.0.0
  webview_flutter: ^4.0.0
```

Run the following command to install:

```bash
flutter pub get
```

## Quick Start

Here's how to add the Studdy Widget to your application:

```dart
import 'package:flutter/material.dart';
import 'package:studdy_widget/studdy_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StuddyWidgetController widgetController;

  @override
  void initState() {
    super.initState();
    
    // Initialize the widget controller
    widgetController = StuddyWidgetController(
      onAuthenticationResponse: (response) {
        print('Authentication response: $response');
      },
    );
    
    // Authenticate with your tenant ID
    widgetController.authenticate(WidgetAuthRequest(
      tenantId: 'YOUR_TENANT_ID',
      authMethod: 'anonymous',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('My App with Studdy')),
        body: Stack(
          children: [
            // Your regular app content here
            
            // Add the Studdy Widget on top
            Positioned(
              bottom: 0,
              right: 0,
              width: 350,
              height: 600,
              child: StuddyWidget(controller: widgetController),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Authentication

The Studdy Widget requires authentication before it can be used:

```dart
// Simple anonymous authentication
widgetController.authenticate(WidgetAuthRequest(
  tenantId: 'YOUR_TENANT_ID',
  authMethod: 'anonymous',
));

// JWT-based authentication
widgetController.authenticate(WidgetAuthRequest(
  tenantId: 'YOUR_TENANT_ID',
  authMethod: 'jwt',
  jwt: 'YOUR_JWT_TOKEN',
));
```

Contact your Studdy account representative to obtain your tenant ID.

## Widget Customization

### Setting Problem Data

You can customize the educational content displayed in the widget:

```dart
// Set problem data
widgetController.setPageData(PageData(
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
));
```

### Widget Positioning

You can control the widget's position on screen:

```dart
// Set widget position to right or left side
widgetController.setWidgetPosition('right');  // or 'left'

// Control Z-index to adjust overlay behavior
widgetController.setZIndex(999);
```

## API Reference

### StuddyWidgetController

The main controller for interacting with the widget:

| Method | Description | Parameters |
|--------|-------------|------------|
| `authenticate(WidgetAuthRequest)` | Authenticate with the Studdy platform | `WidgetAuthRequest` object |
| `setPageData(PageData)` | Set the educational content | `PageData` object |
| `display()` | Show the widget | None |
| `hide()` | Hide the widget | None |
| `enlarge([String?])` | Open the widget in full view | Optional screen name (`'solver'` or `'tutor'`) |
| `minimize()` | Minimize the widget | None |
| `setWidgetPosition(String)` | Set widget position | `'right'` or `'left'` |
| `setZIndex(int)` | Set the CSS z-index | Z-index value |
| `setTargetLocale(String)` | Set the language locale | Locale code (e.g., `'en-US'`) |

## Event Callbacks

The widget emits events that you can listen to:

```dart
widgetController = StuddyWidgetController(
  // Authentication response with token and user info
  onAuthenticationResponse: (response) {
    print('Auth response: $response');
  },
  
  // Widget visibility events
  onWidgetDisplayed: (data) {},
  onWidgetHidden: (data) {},
  onWidgetEnlarged: (data) {},
  onWidgetMinimized: (data) {},
);
```

## Example Implementation

Here's a complete example of integrating the widget with user interaction:

```dart
class MyEducationApp extends StatefulWidget {
  @override
  _MyEducationAppState createState() => _MyEducationAppState();
}

class _MyEducationAppState extends State<MyEducationApp> {
  late StuddyWidgetController widgetController;
  bool isWidgetVisible = false;

  @override
  void initState() {
    super.initState();
    
    widgetController = StuddyWidgetController(
      onWidgetDisplayed: (_) {
        setState(() => isWidgetVisible = true);
      },
      onWidgetHidden: (_) {
        setState(() => isWidgetVisible = false);
      },
    );
    
    // Authenticate
    widgetController.authenticate(WidgetAuthRequest(
      tenantId: 'YOUR_TENANT_ID',
      authMethod: 'anonymous',
    ));
    
    // Set initial problem
    _setCurrentProblem();
  }
  
  void _setCurrentProblem() {
    widgetController.setPageData(PageData(
      problems: [
        {
          'problemId': 'prob-123',
          'referenceTitle': 'Current Homework Problem',
          'problemStatement': [
            {
              'text': 'Find the derivative of f(x) = x² + 3x - 5'
            }
          ],
          'metaData': {
            'type': 'math',
            'topic': 'calculus'
          }
        }
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Math Homework')),
      body: Stack(
        children: [
          // Main content
          Center(
            child: Text('Your homework application content goes here'),
          ),
          
          // Studdy Widget
          Positioned.fill(
            child: StuddyWidget(controller: widgetController),
          ),
          
          // Toggle button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (isWidgetVisible) {
                  widgetController.hide();
                } else {
                  widgetController.display();
                }
              },
              child: Icon(
                isWidgetVisible ? Icons.close : Icons.question_mark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Troubleshooting

If you encounter issues with the Studdy Widget:

1. Ensure you're using the correct tenant ID
2. Verify that you've initialized the WebView properly
3. Check that your authentication method is correctly configured
4. Ensure your app has internet permissions

For further assistance, contact Studdy support at support@studdy.com.

---

For more information or to request a demo, please contact our development team.
