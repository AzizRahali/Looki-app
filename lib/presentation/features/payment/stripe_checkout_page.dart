import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/payment/payment_event.dart';
import '../../core/theme/app_theme.dart';

/// Hosts Stripe Checkout in a WebView (Android / iOS) and pops with a
/// [CheckoutResult] as soon as Stripe redirects to the success or cancel URL.
/// Card details are typed into Stripe's page — they never reach the app.
class StripeCheckoutPage extends StatefulWidget {
  const StripeCheckoutPage({super.key, required this.url});

  final String url;

  @override
  State<StripeCheckoutPage> createState() => _StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final result = _resultFor(request.url);
          if (result == null) return NavigationDecision.navigate;
          _close(result);
          return NavigationDecision.prevent;
        },
        // Some redirects bypass onNavigationRequest (e.g. on iOS).
        onUrlChange: (change) {
          final result = change.url == null ? null : _resultFor(change.url!);
          if (result != null) _close(result);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Matches the backend's default return page and the legacy URLs.
  CheckoutResult? _resultFor(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.path.endsWith('/api/payments/return')) {
      return uri.queryParameters['result'] == 'cancel'
          ? CheckoutResult.cancel
          : CheckoutResult.success;
    }
    if (uri.path.endsWith('/payment/success')) return CheckoutResult.success;
    if (uri.path.endsWith('/payment/cancel')) return CheckoutResult.cancel;
    return null;
  }

  void _close(CheckoutResult result) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(CheckoutResult.dismissed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: tr('close'),
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _close(CheckoutResult.dismissed),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                tr('payment_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: _loading
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
