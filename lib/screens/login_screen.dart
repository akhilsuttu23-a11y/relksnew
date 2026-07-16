import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'worksite_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isProcessing = false;

  final String loginUrl = "https://dev.relkselectricpower.com/api/login";
  final String getPlansUrl = "https://dev.relkselectricpower.com/api/detailsProduct";

  Future<void> _handleLogin() async {
    final String email = _usernameController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMsg("Please enter both email and password.", isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authResponse = await http.post(
        Uri.parse(loginUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 10));
  

      if (authResponse.statusCode != 200) {
        final Map<String, dynamic> err = jsonDecode(authResponse.body);
        _showMsg(err['message'] ?? "Authentication failed.", isError: true);
        setState(() => _isProcessing = false);
        return;
      }

      final authData = jsonDecode(authResponse.body);
      final String token = authData['token'];
      final String employeeId = authData['employee_id']?.toString() ?? email;
      final String workerId = authData['worker_id']?.toString() ?? email;
      final String workerName = authData['name']?.toString() ?? email;

      final planningsResponse = await http.post(
        Uri.parse(getPlansUrl),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

     
      if (planningsResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(planningsResponse.body);
        final Map<String, dynamic> dataPayload = responseData['data'] ?? {};

        final List<dynamic> planningsList = dataPayload['plannings'] ?? [];
        List<Map<String, dynamic>> parsedPlans = planningsList.map((item) {
          return {"id": item['id'].toString(), "title": item['title'] ?? "Unnamed Plan"};
        }).toList();

        final List<dynamic> markingsList = dataPayload['today_markings'] ?? [];
        List<Map<String, dynamic>> parsedMarkings = markingsList.map((item) {
          return {
            "title": item['title'] ?? "Work Plan",
            "in_time": item['in_time'],
            "out_time": item['out_time'],
          };
        }).toList();

        // Safe extraction of persistence indicators across system crashes
        int activeAttendanceId = int.tryParse(dataPayload['attendance_id']?.toString() ?? '0') ?? 0;
        List<String> activePlanningIds = List<String>.from(
          (dataPayload['active_planning_ids'] as List? ?? []).map((e) => e.toString())
        );

        _showMsg("Login Successful!");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SelectWorksiteScreen(
                employeeId: employeeId,
                workerId: workerId,
                workerName:workerName,
                userToken: token,
                availablePlans: parsedPlans,
                todayMarkings: parsedMarkings,
                initialAttendanceId: activeAttendanceId,
                initialActivePlanningIds: activePlanningIds,
              ),
            ),
          );
        }
      } else {
        _showMsg("Server error (${planningsResponse.statusCode}) loading details.", isError: true);
      }
    } catch (e) {
      _showMsg("Network connection error.", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMsg(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? const Color(0xFFD9222A) : const Color(0xFF1E6FD9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage("https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcRH4OEi_Emj-a-5QfKY4wDjyd6DAm1hsUxf1KY2KfEKwSrkAN_9fyfN7yUVlhiOqFb8HQkcl1bFzwYY1mw"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 35),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: "Employee ID / Email",
                            prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF1E6FD9)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF1E6FD9)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _isProcessing
                            ? const Center(child: CircularProgressIndicator())
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(colors: [Color(0xFF1E6FD9), Color(0xFF0F4C99)]),
                                ),
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                  ),
                                  child: const Text("SIGN IN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}