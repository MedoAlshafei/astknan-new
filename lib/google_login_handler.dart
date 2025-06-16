import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GoogleLoginHandler {
  static Future<void> launchGoogleLogin(BuildContext context) async {
    const String googleLoginUrl = 'https://astknan.com/auth/google';

    try {
      final Uri url = Uri.parse(googleLoginUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $googleLoginUrl';
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "حدث خطأ في فتح صفحة تسجيل الدخول",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
