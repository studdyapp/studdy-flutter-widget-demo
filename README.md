# Studdy Flutter Widget Demo

> **IMPORTANT**: In the future, the Studdy widget will be hosted on pub.dev for easier integration. For now, to use this widget, you'll need to manually copy the following files into your repo: `mobile-studdy_widget.dart`, `stub_web_package.dart`, `studdy_widget.dart`, and `web-studdy_widget.dart`.

This repository demonstrates how to implement the Studdy learning widget in a Flutter application that works seamlessly across both web and mobile platforms using conditional imports.

## Key Features

- **Cross-Platform Implementation**: Uses conditional imports to automatically select the appropriate implementation for web or mobile platforms
- **WebView Integration**: Demonstrates proper WebView initialization for different platforms
- **Platform-Specific Code**: Shows how to handle platform-specific features while maintaining a unified API
- **Interactive Demo**: Includes a control panel to test all widget functionality

## How It Works

### Conditional Imports

The core mechanism for platform detection uses Dart's conditional exports:

```dart
// studdy_widget.dart
export 'web-studdy_widget.dart' if (dart.library.io) 'mobile-studdy_widget.dart';
```

This automatically exports the web implementation when running in a browser context, and the mobile implementation when running on iOS, Android, or other mobile platforms.

### Platform-Specific Initialization

The main application initializes the WebView differently based on the platform:

```dart
if (kIsWeb) {
  // Web-specific initialization
  WebViewPlatform.instance = WebWebViewPlatform();
} else {
  // Mobile-specific initialization
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
```

### Stubbing Web Dependencies for Mobile

For mobile platforms, we provide a stub implementation of web-specific dependencies to prevent compilation errors:

```dart
// stub_web_package.dart - used only on mobile
class WebWebViewPlatform implements WebViewPlatform {
  // Stub implementation
}
```

## Project Structure

- **lib/main.dart**: The unified entry point that works for both web and mobile
- **lib/studdy_widget.dart**: The conditional export hub that selects the right implementation
- **lib/web-studdy_widget.dart**: Web-specific implementation using dart:html
- **lib/mobile-studdy_widget.dart**: Mobile-specific implementation
- **lib/stub_web_package.dart**: Stubs for web dependencies when running on mobile

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run on your desired platform:
   - For web: `flutter run -d chrome`
   - For Android: `flutter run -d android`
   - For iOS: `flutter run -d ios`

## Widget API Reference

The StuddyWidgetController provides a unified API for interacting with the widget:

| Method | Description | Parameters |
|--------|-------------|------------|
| `authenticate(WidgetAuthRequest)` | Authenticate with the Studdy platform | `WidgetAuthRequest` object with `tenantId` and `authMethod` |
| `display()` | Show the widget | None |
| `hide()` | Hide the widget | None |
| `enlarge([String?])` | Open the widget in full view | Optional screen name (`'solver'` or `'tutor'`) |
| `minimize()` | Minimize the widget | None |
| `setWidgetPosition(String)` | Set widget position | `'right'` or `'left'` |
| `setZIndex(int)` | Control widget layer | Z-index value |
| `setPageData(PageData)` | Set the educational content | `PageData` object with problems and optional locale |
| `setTargetLocale(String)` | Set the language locale | Locale code (e.g., `'en-US'`) |

### Authentication Example

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

### Setting Problem Data

```dart
widgetController.setPageData(PageData(
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
```

## Notes for Developers

- Test on various different screen sizes to ensure consistent behavior
- Be aware of platform capabilities and provide appropriate fallbacks when needed
- For detailed problem representation and metadata format, refer to the [API documentation](https://studdy.notion.site/Studdy-Widget-Documentation-1be5d54640d3801ea6c6f0db84cfba4a)
