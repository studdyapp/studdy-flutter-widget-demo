# Studdy Flutter Widget Demo

> **IMPORTANT**: In the future, the Studdy widget will be hosted on pub.dev for easier integration. For now, to use this widget, you'll need to manually copy the necessary files into your project.

This repository demonstrates how to implement the Studdy learning widget in a Flutter application that works seamlessly across both web and mobile platforms.

## Overview

This demo showcases a cross-platform Flutter implementation of the Studdy Widget, allowing developers to integrate interactive educational features in their apps. The implementation automatically adapts to work correctly on both web and mobile platforms.

The main.dart file provides an example control panel where you can test all widget functionality, with proper error handling and validation.

## Key Features

- **Cross-Platform Support**: Works on both web and mobile (iOS, Android) with a single codebase
- **Interactive Demo**: Control panel to test authentication, content display, and widget features
- **Error Handling**: Graceful validation that ensures proper usage sequence (authentication → page data → display)
- **Responsive Design**: Adapts to different screen sizes while maintaining functionality

## Project Structure

- **lib/main.dart**: Example implementation with interactive control panel (free to edit)
- **lib/studdy_widget.dart**: Main widget API that handles cross-platform compatibility (don't recommend editing)
- **lib/platform/web-studdy_widget.dart**: Web-specific implementation (don't recommend editing)
- **lib/platform/mobile-studdy_widget.dart**: Mobile-specific implementation (don't recommend editing)
- **lib/utils/**: Contains models, constants, and helper functions (don't recommend editing)

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run on your desired platform:
   - For web: `flutter run -d chrome`
   - For Android: `flutter run -d android`
   - For iOS: `flutter run -d ios`

## Using the Widget

To integrate the Studdy Widget in your own Flutter application, you'll need to:

1. Copy the necessary files (see repository structure)
2. Import the widget in your application
3. Follow the authentication and content setting sequence

### Basic Integration Example

```dart
import 'package:your_app/studdy_widget.dart';

// 1. Authenticate
await StuddyWidget.authenticate(WidgetAuthRequest(
  tenantId: 'YOUR_TENANT_ID',
  authMethod: 'jwt',
  jwt: 'YOUR_JWT_TOKEN',
));

// 2. Set page data
StuddyWidget.setPageData(PageData(
  problems: [
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
  ],
  targetLocale: 'en-US'
));

// 3. Display the widget
StuddyWidget.display();
```

## Widget API Reference

| Method | Description | Required Authentication | Required Page Data |
|--------|-------------|-------------------------|-------------------|
| `authenticate(WidgetAuthRequest)` | Authenticate with the Studdy platform | No | No |
| `setPageData(PageData)` | Set the educational content | No | No |
| `display()` | Show the widget | Yes | Yes |
| `hide()` | Hide the widget | Yes | Yes |
| `enlarge([String?])` | Open the widget in full view | Yes | Yes |
| `minimize()` | Minimize the widget | Yes | Yes |
| `setWidgetPosition(String)` | Set widget position (left/right) | No | No |
| `setZIndex(int)` | Control widget layer | No | No |
| `setTargetLocale(String)` | Set the language locale | No | No |

## Notes for Implementation

- Authentication and page data must be set before displaying, enlarging, minimizing, or hiding the widget
- The widget handles proper error feedback when methods are called out of sequence
- For detailed problem representation and metadata format, refer to the [API documentation](https://studdy.notion.site/Studdy-Widget-Documentation-1be5d54640d3801ea6c6f0db84cfba4a)
