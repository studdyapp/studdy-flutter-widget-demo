// This file conditionally exports either web or mobile implementation
export 'web-studdy_widget.dart' if (dart.library.io) 'mobile-studdy_widget.dart';