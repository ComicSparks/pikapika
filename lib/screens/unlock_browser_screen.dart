import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pikapika/basic/config/passed.dart';

class UnlockBrowserScreen extends StatefulWidget {
  const UnlockBrowserScreen({super.key});

  @override
  State<UnlockBrowserScreen> createState() => _UnlockBrowserScreenState();
}

class _UnlockBrowserScreenState extends State<UnlockBrowserScreen> {
  static const _activationScheme = 'pk://start';
  static const _defaultUrl = 'https://www.bing.com/';

  final TextEditingController _addressController =
      TextEditingController(text: _defaultUrl);
  final FocusNode _addressFocusNode = FocusNode();

  InAppWebViewController? _webViewController;
  String _currentUrl = _defaultUrl;
  double _progress = 0;

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  bool _isActivationUrl(String url) {
    final normalized = url.trim().toLowerCase();
    return normalized == _activationScheme ||
        normalized == '$_activationScheme/' ||
        normalized.startsWith('$_activationScheme?') ||
        normalized.startsWith('$_activationScheme#');
  }

  Uri _toUri(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return Uri.parse('about:blank');
    final uri = Uri.tryParse(raw);
    if (uri == null) return Uri.parse('about:blank');
    if (uri.hasScheme) return uri;
    return Uri.parse('https://$raw');
  }

  Future<void> _activate() async {
    await firstPassed();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _loadFromAddressBar(String value) async {
    if (_isActivationUrl(value)) {
      await _activate();
      return;
    }
    final uri = _toUri(value);
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(uri.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 8,
          title: TextField(
            controller: _addressController,
            focusNode: _addressFocusNode,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            enableSuggestions: false,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '输入网址',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onSubmitted: (value) async {
              await _loadFromAddressBar(value);
            },
          ),
          actions: [
            if (!Platform.isLinux) ...[
              IconButton(
                tooltip: '后退',
                onPressed: () async {
                  if (await _webViewController?.canGoBack() == true) {
                    await _webViewController?.goBack();
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
              IconButton(
                tooltip: '前进',
                onPressed: () async {
                  if (await _webViewController?.canGoForward() == true) {
                    await _webViewController?.goForward();
                  }
                },
                icon: const Icon(Icons.arrow_forward),
              ),
              IconButton(
                tooltip: '刷新',
                onPressed: () => _webViewController?.reload(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            if (_progress > 0 && _progress < 1)
              LinearProgressIndicator(value: _progress),
            Expanded(
              child: Platform.isLinux
                  ? const ColoredBox(color: Colors.white)
                  : InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: true,
                  allowsInlineMediaPlayback: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                shouldOverrideUrlLoading: (controller, action) async {
                  final url = action.request.url?.toString() ?? '';
                  if (_isActivationUrl(url)) {
                    unawaited(_activate());
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStart: (controller, url) {
                  final next = url?.toString() ?? '';
                  if (next.isEmpty || !mounted) return;
                  setState(() {
                    _currentUrl = next;
                    _addressController.text = next;
                  });
                },
                onLoadStop: (controller, url) {
                  final next = url?.toString() ?? '';
                  if (!mounted) return;
                  setState(() {
                    if (next.isNotEmpty) {
                      _currentUrl = next;
                      _addressController.text = next;
                    }
                    _progress = 0;
                  });
                },
                onProgressChanged: (controller, progress) {
                  if (!mounted) return;
                  setState(() {
                    _progress = progress / 100.0;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
