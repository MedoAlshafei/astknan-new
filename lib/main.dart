import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'splash_screen.dart';
import 'no_internet_screen.dart';
import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'google_login_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await InAppWebViewController.setWebContentsDebuggingEnabled(true);
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

  // قائمة بالروابط التي يجب فتحها في متصفح خارجي
  final List<String> externalUrlPatterns = [
    'accounts.google.com',
    'social-login.oxiapps.com/auth/google',
    'oauth',
    'login.google.com',
    'google.com/oauth',
  ];

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
              controller.addJavaScriptHandler(
                handlerName: 'oauthHandler',
                callback: (args) {
                  if (args.isNotEmpty) {
                    String url = args[0].toString();
                    if (_shouldOpenExternally(url)) {
                      _launchExternalBrowser(url);
                    }
                  }
                },
              );
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url!;
              String url = uri.toString();

              // فحص إذا كان الرابط يحتاج لفتح في متصفح خارجي
              if (_shouldOpenExternally(url)) {
                // منع التنقل في WebView
                await _launchExternalBrowser(url);
                return NavigationActionPolicy.CANCEL;
              }

              // السماح بالتنقل العادي
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStart: (controller, url) {
              // يمكن إضافة منطق إضافي هنا عند بدء التحميل
              print('بدء تحميل: $url');
            },
            onLoadStop: (controller, url) async {
              // حقن JavaScript لمراقبة الروابط
              await _injectOAuthDetectionScript(controller);
              print('انتهاء تحميل: $url');
            },
            onReceivedError: (controller, request, error) {
              print('خطأ في التحميل: ${error.description}');
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // استدعاء تسجيل الدخول بجوجل
            try {
              await GoogleLoginHandler.launchGoogleLogin(context);
            } catch (e) {
              Fluttertoast.showToast(msg: 'خطأ: $e');
            }
          },
          icon: Icon(Icons.login),
          label: Text('تسجيل دخول جوجل'),
        ),
      ),
    );
  }

  // فحص إذا كان الرابط يحتاج لفتح في متصفح خارجي
  bool _shouldOpenExternally(String url) {
    return externalUrlPatterns.any((pattern) => url.contains(pattern));
  }

  // فتح الرابط في متصفح خارجي
  Future<void> _launchExternalBrowser(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      // محاولة فتح الرابط في متصفح النظام
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // فتح في متصفح خارجي
        );

        // عرض رسالة للمستخدم
        Fluttertoast.showToast(
          msg: "سيتم فتح صفحة تسجيل الدخول في المتصفح",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // print('خطأ في فتح الرابط: $e');
      Fluttertoast.showToast(
        msg: "خطأ في فتح صفحة تسجيل الدخول",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // إنشاء User Agent مخصص
  String _getCustomUserAgent() {
    // إزالة العلامات التي تشير إلى WebView
    if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36';
    } else if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1';
    }
    return 'Mozilla/5.0 (compatible; CustomApp/1.0)';
  }

  // حقن JavaScript لمراقبة الروابط
  Future<void> _injectOAuthDetectionScript(
    InAppWebViewController controller,
  ) async {
    await controller.evaluateJavascript(
      source: '''
      (function() {
        // مراقبة النقرات على الروابط
        document.addEventListener('click', function(e) {
          var target = e.target;
          var url = '';
          
          // البحث عن الرابط في العنصر أو العناصر الأب
          while (target && target !== document) {
            if (target.tagName === 'A' && target.href) {
              url = target.href;
              break;
            }
            target = target.parentNode;
          }
          
          // فحص إذا كان الرابط يحتوي على OAuth
          if (url && (url.includes('accounts.google.com') || 
                     url.includes('social-login.oxiapps.com/auth/google') ||
                     url.includes('oauth'))) {
            e.preventDefault();
            e.stopPropagation();
            
            // إرسال الرابط إلى Flutter
            window.flutter_inappwebview.callHandler('oauthHandler', url);
            
            return false;
          }
        }, true);
        
        // مراقبة تغييرات الـ URL
        var originalPushState = history.pushState;
        var originalReplaceState = history.replaceState;
        
        history.pushState = function() {
          originalPushState.apply(history, arguments);
          checkCurrentUrl();
        };
        
        history.replaceState = function() {
          originalReplaceState.apply(history, arguments);
          checkCurrentUrl();
        };
        
        window.addEventListener('popstate', checkCurrentUrl);
        
        function checkCurrentUrl() {
          var currentUrl = window.location.href;
          if (currentUrl.includes('accounts.google.com') || 
              currentUrl.includes('social-login.oxiapps.com/auth/google') ||
              currentUrl.includes('oauth')) {
            window.flutter_inappwebview.callHandler('oauthHandler', currentUrl);
          }
        }
        
        // فحص الـ URL الحالي
        checkCurrentUrl();
      })();
    ''',
    );
  }
}

// إضافة معالج للعودة من المتصفح الخارجي
class AppLifecycleHandler extends WidgetsBindingObserver {
  final VoidCallback onResumed;

  AppLifecycleHandler({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
