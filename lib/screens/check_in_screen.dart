import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

class CheckInScreen extends StatefulWidget {
  final String employeeId;
  final String workerId;
  final List<String> selectedPlanIds; 
  final String selectedPlanTitle;
  final String userToken;
  final int attendanceId;

  const CheckInScreen({
    super.key,
    required this.employeeId,
    required this.workerId,
    required this.selectedPlanIds, 
    required this.selectedPlanTitle,
    required this.userToken,
    this.attendanceId = 0,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _locationStatus = "Obtaining GPS location...";
  XFile? _selfieFile;
  Uint8List? _selfieImageBytes; 
  double? _latitude;
  double? _longitude;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initiateLocationFetch();
  }

  Future<void> _initiateLocationFetch() async {
    Position? pos = await _determinePosition();
    if (pos != null) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationStatus = "Lat: ${_latitude!.toStringAsFixed(5)}, Lon: ${_longitude!.toStringAsFixed(5)}";
      });
    } else {
      setState(() {
        _locationStatus = "Location acquisition error.";
      });
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    ).catchError((e) {
      debugPrint("Location error: $e");
      return null;
    });
  }

  Future<void> _captureSelfie() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes(); 
        setState(() {
          _selfieFile = pickedFile;
          _selfieImageBytes = bytes; 
        });
      }
    } catch (e) {
      _showErrorDialog("Image Capture Error: $e");
    }
  }

  Future<void> _submitCheckInOut() async {
    if (_selfieFile == null || _selfieImageBytes == null) {
      await _showErrorDialog("Capture image verification first.");
      return;
    }
    if (_latitude == null || _longitude == null) {
      await _showErrorDialog("GPS lock required before submitting.");
      return;
    }

    setState(() => _isProcessing = true);

    const String submitUrl = "https://dev.relkselectricpower.com/api/attendance/check-in";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(submitUrl));

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer ${widget.userToken}",
      });

      request.fields['attendance_id'] = widget.attendanceId.toString();
      request.fields['employee_id'] = widget.employeeId;
      request.fields['worker_id'] = widget.workerId;
      request.fields['latitude'] = _latitude.toString();
      request.fields['longitude'] = _longitude.toString();

      for (int i = 0; i < widget.selectedPlanIds.length; i++) {
        request.fields['planning_id[$i]'] = widget.selectedPlanIds[i];
      }

      var multipartFile = http.MultipartFile.fromBytes(
        'selfie',
        _selfieImageBytes!,
        filename: 'selfie_${widget.employeeId}.jpg',
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final Map<String, dynamic> dataPayload = jsonResponse['data'] ?? {};

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Success"),
              content: Text(widget.attendanceId > 0 ? "Check-Out complete!" : "Check-In complete!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, dataPayload); 
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        await _showErrorDialog(errorData['message'] ?? "Error processing submission.");
      }
    } catch (e) {
      await _showErrorDialog("Network action error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showErrorDialog(String msg) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Alert"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCheckingOut = widget.attendanceId > 0;
    final Color themeColor = isCheckingOut ? const Color(0xFFD9222A) : const Color(0xFF1E6FD9);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          isCheckingOut ? "Check Out Verification" : "Check In Verification",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: themeColor,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Reporting Project Selection:",
                      style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.selectedPlanTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1F21)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _captureSelfie,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeColor,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                          image: _selfieImageBytes != null
                              ? DecorationImage(
                                  image: kIsWeb
                                      ? MemoryImage(_selfieImageBytes!)
                                      : FileImage(io.File(_selfieFile!.path)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selfieImageBytes == null
                            ? Icon(
                                Icons.add_a_photo_rounded,
                                size: 40,
                                color: themeColor,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Tap preview circle to record confirmation photo",
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFD9222A), size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationStatus,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: isCheckingOut
                        ? [const Color(0xFFD9222A), const Color(0xFF99181E)]
                        : [const Color(0xFF1E6FD9), const Color(0xFF0F4C99)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitCheckInOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isCheckingOut ? "CONFIRM SHIFT CHECK-OUT" : "CONFIRM SHIFT CHECK-IN",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}