import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'check_in_screen.dart';
import 'auth_utils.dart';
import '../constatnts/api_constants.dart';

class SelectWorksiteScreen extends StatefulWidget {
  final String employeeId;
  final String workerId;
  final String workerName;
  final String userToken;
  final List<Map<String, dynamic>> availablePlans;
  final List<Map<String, dynamic>> todayMarkings;
  final int initialAttendanceId;
  final List<String> initialActivePlanningIds;

  const SelectWorksiteScreen({
    super.key,
    required this.employeeId,
    required this.workerId,
    required this.workerName,
    required this.userToken,
    required this.availablePlans,
    required this.todayMarkings,
    this.initialAttendanceId = 0,
    this.initialActivePlanningIds = const [],
  });

  @override
  State<SelectWorksiteScreen> createState() => _SelectWorksiteScreenState();
}

class _SelectWorksiteScreenState extends State<SelectWorksiteScreen> {
  late int _attendanceId;
  late List<String> _selectedPlanIds;
  late List<Map<String, dynamic>> _allLogs;
  late List<String> _globallyActiveIds;

  @override
  void initState() {
    super.initState();
    _attendanceId = widget.initialAttendanceId;
    _allLogs = List<Map<String, dynamic>>.from(widget.todayMarkings);
    _globallyActiveIds = widget.initialActivePlanningIds
        .map((e) => e.toString())
        .toList();

    if (_globallyActiveIds.isNotEmpty) {
      _selectedPlanIds = [_globallyActiveIds.first];
    } else {
      _selectedPlanIds = [];
    }
  }

  bool get _isCurrentActionSignOut {
    if (_selectedPlanIds.isEmpty) return false;
    return _globallyActiveIds.contains(_selectedPlanIds.first);
  }

  List<Map<String, dynamic>> get _todayLogs {
    final now = DateTime.now();
    return _allLogs.where((log) {
      if (log['in_time'] == null) return false;
      try {
        DateTime logDate = DateTime.parse(log['in_time'].toString()).toLocal();
        return logDate.year == now.year &&
               logDate.month == now.month &&
               logDate.day == now.day;
      } catch (_) {
        return true;
      }
    }).toList();
  }

  String _formatDateTimeString(dynamic timeString) {
    if (timeString == null) return "--/--/---- --:-- --";
    try {
      DateTime parsed = DateTime.parse(timeString.toString()).toLocal();
      String day = parsed.day.toString().padLeft(2, '0');
      String month = parsed.month.toString().padLeft(2, '0');
      String year = parsed.year.toString();

      int hourInt = parsed.hour;
      String period = hourInt >= 12 ? 'PM' : 'AM';
      
      hourInt = hourInt % 12;
      if (hourInt == 0) hourInt = 12;

      String hour = hourInt.toString().padLeft(2, '0');
      String minute = parsed.minute.toString().padLeft(2, '0');

      return "$day/$month/$year $hour:$minute $period";
    } catch (_) {
      return timeString.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSignOutAction = _isCurrentActionSignOut;
    final displayLogs = _todayLogs;
    final bool hasActiveShift = _globallyActiveIds.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          isSignOutAction ? "Active Shift Detail" : "Select Work Plan",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => AuthUtils.logout(context, widget.userToken),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: const Color(0xFF1E6FD9),
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle_rounded, color: Color(0xFF1E6FD9), size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Employee Name: ${widget.workerName}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1F21)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSignOutAction ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSignOutAction ? Colors.red.shade300 : Colors.blue.shade300, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSignOutAction ? Icons.logout_rounded : Icons.check_circle_outline_rounded,
                      color: isSignOutAction ? Colors.red.shade800 : Colors.blue.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isSignOutAction
                            ? "STATUS: ACTIVE SHIFT (Sign-Out Required)"
                            : "STATUS: READY TO SIGN-IN",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSignOutAction ? Colors.red.shade900 : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSignOutAction
                    ? "You must sign out of your current project before starting another:"
                    : "Select the project allocation list you are checking into today:",
                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              
              Container(
                height: 250, 
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: widget.availablePlans.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "No projects assigned today.",
                            style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: widget.availablePlans.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final plan = widget.availablePlans[index];
                          final String planId = plan['id'].toString();

                          final bool isChecked = _selectedPlanIds.contains(planId);
                          final bool isAlreadyCheckedIn = _globallyActiveIds.contains(planId);

                          return CheckboxListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan['title'].toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isAlreadyCheckedIn ? const Color(0xFFD9222A) : const Color(0xFF1E1F21),
                                  ),
                                ),
                                if (isAlreadyCheckedIn)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      "Active Shift (Sign-Out Required)",
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            activeColor: isAlreadyCheckedIn ? const Color(0xFFD9222A) : const Color(0xFF1E6FD9),
                            value: isChecked,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? checked) {
                              if (hasActiveShift && !isAlreadyCheckedIn) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Action Blocked: Please sign out of your current active work first."),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                if (checked == true) {
                                  _selectedPlanIds = [planId];
                                } else {
                                  if (!hasActiveShift) {
                                    _selectedPlanIds.clear();
                                  }
                                }
                              });
                            },
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: isSignOutAction
                        ? [const Color(0xFFD9222A), const Color(0xFF99181E)]
                        : [const Color(0xFF1E6FD9), const Color(0xFF0F4C99)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedPlanIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Action Denied: You must select a project layout from the list before proceeding."),
                          backgroundColor: Colors.amberAccent,
                        ),
                      );
                      return;
                    }

                    final String currentSelectedId = _selectedPlanIds.first;
                    final bool handlingSignOut = _globallyActiveIds.contains(currentSelectedId);

                    if (hasActiveShift && !handlingSignOut) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Action Denied: You must complete sign-out of your active work first."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final dynamic result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckInScreen(
                          employeeId: widget.employeeId,
                          workerId: widget.workerId,
                          selectedPlanIds: [currentSelectedId],
                          attendanceId: handlingSignOut ? _attendanceId : 0,
                          selectedPlanTitle: widget.availablePlans.firstWhere(
                            (p) => p['id'].toString() == currentSelectedId,
                            orElse: () => {'title': 'Project Plan'},
                          )['title'],
                          userToken: widget.userToken,
                        ),
                      ),
                    );

                    if (result != null && result is Map<String, dynamic>) {
                      if (!mounted) return;
                      
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final String getPlansUrl = ApiConstants.detailsProduct;
                        final planningsResponse = await http.post(
                          Uri.parse(getPlansUrl),
                          headers: {
                            "Accept": "application/json",
                            "Authorization": "Bearer ${widget.userToken}",
                          },
                        ).timeout(const Duration(seconds: 10));

                        if (mounted) Navigator.pop(context);

                        if (planningsResponse.statusCode == 200) {
                          final Map<String, dynamic> responseData = jsonDecode(planningsResponse.body);
                          final Map<String, dynamic> dataPayload = responseData['data'] ?? {};

                          final List<dynamic> markingsList = dataPayload['today_markings'] ?? [];
                          List<Map<String, dynamic>> parsedMarkings = markingsList.map((item) {
                            return {
                              "title": item['title'] ?? "Work Plan",
                              "in_time": item['in_time'],
                              "out_time": item['out_time'],
                            };
                          }).toList();

                          int activeAttendanceId = int.tryParse(dataPayload['attendance_id']?.toString() ?? '0') ?? 0;
                          List<String> activePlanningIds = List<String>.from(
                            (dataPayload['active_planning_ids'] as List? ?? []).map((e) => e.toString())
                          );

                          setState(() {
                            _attendanceId = activeAttendanceId;
                            _globallyActiveIds = activePlanningIds;
                            _allLogs = parsedMarkings;
                            
                            if (_globallyActiveIds.isNotEmpty) {
                              _selectedPlanIds = [_globallyActiveIds.first];
                            } else {
                              _selectedPlanIds.clear();
                            }
                          });
                        }
                      } catch (e) {
                        if (mounted) Navigator.pop(context);
                        debugPrint("Error updating layout: $e");
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSignOutAction ? "PROCEED TO SYSTEM SIGN-OUT" : "PROCEED TO SYSTEM SIGN-IN",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      Icon(isSignOutAction ? Icons.logout_rounded : Icons.login_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(color: Colors.black26),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF1E6FD9), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Shift Log History (${displayLogs.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1F21)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              displayLogs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Text(
                        "No matching attendance logs recorded.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black45, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayLogs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final marking = displayLogs[index];
                        final bool isActiveLog = marking['out_time'] == null || marking['out_time'].toString().isEmpty;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                marking['title'] ?? "Worksite Plan",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Text(
                                      "IN: ${_formatDateTimeString(marking['in_time'])}",
                                      style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActiveLog ? Colors.red.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isActiveLog ? Colors.red.shade200 : Colors.orange.shade200),
                                    ),
                                    child: Text(
                                      isActiveLog ? "ACTIVE SHIFT" : "OUT: ${_formatDateTimeString(marking['out_time'])}",
                                      style: TextStyle(color: isActiveLog ? Colors.red.shade800 : Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}