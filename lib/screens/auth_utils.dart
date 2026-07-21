import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import '../constatnts/api_constants.dart';


class AuthUtils {
  static Future<void> logout(BuildContext context, String userToken) async {
    final String logoutUrl =  ApiConstants.logout;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await http.post(
        Uri.parse(logoutUrl),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $userToken",
        },
      ).timeout(const Duration(seconds: 7));
    } catch (e) {
      debugPrint("Backend logout failed: $e");
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}