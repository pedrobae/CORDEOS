import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late WebViewController _controller;
  bool _isLoading = false;
  WebResourceError? _webResourceError;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _webResourceError = error;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse("https://newheartbrasil.org/"));
  }

  Future<bool> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return true;
    }
    return false;
  }

  Widget _buildWebView() {
    if (_webResourceError != null) {
      return _buildErrorState();
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Positioned(
            top: 24,
            left: 24,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: [
          Text(l10n.error, style: textTheme.titleMedium),
          Text(_webResourceError!.description, style: textTheme.bodyMedium),
          FilledTextButton(
            icon: Icons.loop,
            text: l10n.tryAgain,
            isDark: true,
            isDiscrete: true,
            onPressed: () {
              setState(() {
                _webResourceError = null;
                _isLoading = false;
              });
              _initializeWebViewController();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopScope(Widget child) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final canGoBack = await _handleBackNavigation();
        if (!canGoBack && mounted) {
          context.read<NavigationProvider>().attemptPop(context);
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPopScope(_buildWebView());
  }
}
