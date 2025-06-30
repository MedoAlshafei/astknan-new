import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GoogleLoginHandler {
  static Future<void> launchGoogleLogin(BuildContext context) async {
    const String googleLoginUrl =
        "https://astknan.com/pages/oauth-google-login"
        "?response_type=code"
        "&client_id=793551045613-8a8kgbu7g8ujsl8m1fuu25ff58b0h2ma.apps.googleusercontent.com"
        "&redirect_uri=https://astknan.com/pages/oauth-google-callback"
        "&scope=profile email";
    const String callbackScheme = 'com.astknan.store';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: googleLoginUrl,
        callbackUrlScheme: callbackScheme,
      );

      print('Result: ' + result); // Debug: print the result URL

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        print("✅ Google OAuth Code: $code");
        // يمكنك هنا إرسال الكود لسيرفرك لاستبداله بـ access_token
      } else {
        Fluttertoast.showToast(
          msg: "❌ لم يتم استلام كود من Google",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "⚠️ حصل خطأ أثناء تسجيل الدخول: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
