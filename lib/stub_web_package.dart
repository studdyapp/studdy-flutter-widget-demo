// This stub file is imported on non-web platforms
// to satisfy the conditional import requirements

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class WebWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    throw UnimplementedError('Not supported on this platform');
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    throw UnimplementedError('Not supported on this platform');
  }

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    throw UnimplementedError('Not supported on this platform');
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    throw UnimplementedError('Not supported on this platform');
  }
} 