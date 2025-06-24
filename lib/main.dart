import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'splash_screen.dart';
import 'no_internet_screen.dart';
import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  runApp(const AstknanApp());
}

class AstknanApp extends StatefulWidget {
  const AstknanApp({super.key});

  @override
  State<AstknanApp> createState() => _AstknanAppState();
}

class _AstknanAppState extends State<AstknanApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Timer? _timer;
  // bool _hasInternet = true;
  bool _overlayShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetAndShowOverlay();
    });
    _startInternetCheckTimer();
  }

  void _checkInternetAndShowOverlay() async {
    bool connected = await _hasRealInternet();
    if (!connected && !_overlayShown) {
      _showNoInternetOverlay();
    }
  }

  void _startInternetCheckTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      bool connected = await _hasRealInternet();
      if (!connected && !_overlayShown) {
        _showNoInternetOverlay();
      } else if (connected && _overlayShown) {
        _removeNoInternetOverlay();
      }
    });
  }

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _showNoInternetOverlay() {
    _overlayShown = true;
    navigatorKey.currentState?.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const NoInternetScreen(),
        settings: const RouteSettings(name: 'no_internet'),
      ),
    );
  }

  void _removeNoInternetOverlay() {
    _overlayShown = false;
    navigatorKey.currentState?.popUntil(
      (route) => route.settings.name != 'no_internet',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Astknan',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  InAppWebViewController? webViewController;
  static const String mainUrl = "https://astknan.com/";
  DateTime? lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (webViewController != null) {
          bool canGoBack = await webViewController!.canGoBack();
          var url = (await webViewController!.getUrl())?.toString() ?? "";

          if (canGoBack) {
            webViewController!.goBack();
            return false;
          }

          if (url.contains("ERR_CLEARTEXT_NOT_PERMITTED") ||
              url.contains("not-available") ||
              url.contains("about:blank")) {
            return true;
          }
        }

        DateTime now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;

          Fluttertoast.showToast(
            msg: "اضغط مرة أخرى للخروج من التطبيق",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          return false;
        }

        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(mainUrl)),
            initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
            // initialOptions: InAppWebViewGroupOptions(
            //   crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
            // ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
          ),
        ),
      ),
    );
  }
}
