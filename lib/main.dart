import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'استكنان',
      theme: ThemeData(primarySwatch: Colors.green),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => WebViewContainer()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset('assets/logo.png', width: 150)),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  @override
  _WebViewContainerState createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://t3gyfa-vi.sp-seller.webkul.com'))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isOffline
          ? Center(child: Text('No Internet Connection'))
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading) Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
