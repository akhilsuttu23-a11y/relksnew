import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'check_in_screen.dart';
import 'auth_utils.dart';
import '../constatnts/api_constants.dart';

class SelectWorksiteScreen extends StatefulWidget {
  final String employeeId;
  final String workerId;
  final String workerName;
  final int userRole;
  final String userToken;
  final List<Map<String, dynamic>> availablePlans;
  final List<Map<String, dynamic>> todayMarkings;
  final int initialAttendanceId;
  final List<String> initialActivePlanningIds;
  final int pendingPreviousSignoutsCount;

  const SelectWorksiteScreen({
    super.key,
    required this.employeeId,
    required this.workerId,
    required this.workerName,
    required this.userRole,
    required this.userToken,
    required this.availablePlans,
    required this.todayMarkings,
    this.initialAttendanceId = 0,
    this.initialActivePlanningIds = const [],
    this.pendingPreviousSignoutsCount = 0,
  });

  @override
  State<SelectWorksiteScreen> createState() => _SelectWorksiteScreenState();
}

class _SelectWorksiteScreenState extends State<SelectWorksiteScreen> {
  late int _attendanceId;
  late List<String> _selectedPlanIds;
  late List<Map<String, dynamic>> _allLogs;
  late List<String> _globallyActiveIds;
  late int _pendingSignoutsCount;

  @override
  void initState() {
    super.initState();
    _attendanceId = widget.initialAttendanceId;
    _allLogs = List<Map<String, dynamic>>.from(widget.todayMarkings);
    _pendingSignoutsCount = widget.pendingPreviousSignoutsCount;
    _globallyActiveIds = widget.initialActivePlanningIds
        .map((e) => e.toString())
        .toList();

    if (_globallyActiveIds.isNotEmpty) {
      _selectedPlanIds = [_globallyActiveIds.first];
    } else {
      _selectedPlanIds = [];
    }
  }

  bool get _hasTaskAccess {
    return widget.userRole == 3 || widget.userRole == 4;
  }

  bool get _isWorker {
    return widget.userRole == 4;
  }

  String get _roleName {
    switch (widget.userRole) {
      case 1:
        return "Admin";
      case 3:
        return "Manager";
      case 4:
        return "Worker";
      case 5:
        return "Store Manager";
      default:
        return "Employee";
    }
  }

  bool get _isCurrentActionSignOut {
    // 1. Worker (Role 4) Case
    if (_isWorker) {
      if (_selectedPlanIds.isEmpty) {
        return false;
      }
      return _globallyActiveIds.contains(_selectedPlanIds.first);
    }

    // 2. Manager (Role 3) Case
    if (_selectedPlanIds.isEmpty) {
      bool hasActiveGeneralDuty = _allLogs.any((log) {
        bool isUnclosed = log['out_time'] == null || log['out_time'].toString().trim().isEmpty;
        dynamic pId = log['planning_id'];
        String t = (log['title'] ?? '').toString().trim();
        
        bool isGeneralDuty = (pId == null || pId.toString() == '0' || pId.toString().isEmpty) || t == "General Duty";
        return isUnclosed && isGeneralDuty;
      });

      return hasActiveGeneralDuty;
    }

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

  String _parseMarkingTitle(Map<String, dynamic> marking) {
    String? foundTitle = marking['title'] ??
        marking['project_name'] ??
        marking['plan_title'] ??
        marking['task_title'] ??
        marking['planning_name'] ??
        marking['work_title'];

    if (foundTitle != null && foundTitle.isNotEmpty && foundTitle != "General Duty") {
      return foundTitle;
    }

    final dynamic planIdFromMarking = marking['planning_id'] ?? marking['plan_id'];
    if (planIdFromMarking != null && planIdFromMarking.toString() != '0') {
      try {
        final matchedPlan = widget.availablePlans.firstWhere(
          (p) => p['id'].toString() == planIdFromMarking.toString(),
          orElse: () => {},
        );
        if (matchedPlan.isNotEmpty) {
          return matchedPlan['title'] ??
              matchedPlan['name'] ??
              matchedPlan['project_name'] ??
              "General Duty";
        }
      } catch (_) {}
    }

    return "General Duty";
  }

  @override
  Widget build(BuildContext context) {
    final bool isSignOutAction = _isCurrentActionSignOut;
    final displayLogs = _todayLogs;
    final bool hasActiveShift = _globallyActiveIds.isNotEmpty || _attendanceId > 0;
    final bool showTaskList = _hasTaskAccess && widget.availablePlans.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          isSignOutAction ? "Active Shift Detail" : "Attendance Marking",
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
                      "User: ${widget.workerName} ($_roleName)",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1F21)),
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
                  border: Border.all(
                    color: isSignOutAction ? Colors.red.shade300 : Colors.blue.shade300,
                    width: 1.5,
                  ),
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

              if (_pendingSignoutsCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Warning: You have $_pendingSignoutsCount pending sign-out(s) from previous days.",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (showTaskList) ...[
                Text(
                  isSignOutAction ? "Your Active Task:" : "Select Task / Project: ${_isWorker ? '*' : ''}",
                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ListView.separated(
                    itemCount: widget.availablePlans.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final plan = widget.availablePlans[index];
                      final String planId = plan['id'].toString();
                      final bool isChecked = _selectedPlanIds.contains(planId);
                      final bool isAlreadyCheckedIn = _globallyActiveIds.contains(planId);

                      final String planTitle = plan['title'] ??
                          plan['project_name'] ??
                          plan['plan_title'] ??
                          plan['name'] ??
                          "Task #$planId";

                      return CheckboxListTile(
                        title: Text(
                          planTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isAlreadyCheckedIn ? const Color(0xFFD9222A) : const Color(0xFF1E1F21),
                          ),
                        ),
                        activeColor: isAlreadyCheckedIn ? const Color(0xFFD9222A) : const Color(0xFF1E6FD9),
                        value: isChecked,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? checked) {
                          if (_isWorker && hasActiveShift && !isAlreadyCheckedIn && checked == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Action Blocked: Please sign out of your current active task before switching to another."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            if (checked == true) {
                              _selectedPlanIds = [planId];
                            } else {
                              _selectedPlanIds.clear();
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF1E6FD9)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          !_hasTaskAccess
                              ? "General Duty Attendance for $_roleName"
                              : "No active tasks assigned. Proceed with General Duty.",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
                    final bool isCheckIn = !isSignOutAction;

                    if (_isWorker && _selectedPlanIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            hasActiveShift
                                ? "Workers must keep their active task selected to sign out."
                                : "Workers must select at least one task or project to mark attendance.",
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if (isCheckIn && _isWorker && hasActiveShift) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Action Blocked: You must sign out of your current active task first."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    String selectedTitle = "General Duty / Duty Attendance";
                    if (_selectedPlanIds.isNotEmpty && showTaskList) {
                      final selectedPlan = widget.availablePlans.firstWhere(
                        (p) => p['id'].toString() == _selectedPlanIds.first,
                        orElse: () => {'title': 'General Duty'},
                      );
                      selectedTitle = selectedPlan['title'] ??
                          selectedPlan['project_name'] ??
                          selectedPlan['plan_title'] ??
                          selectedPlan['name'] ??
                          'General Duty';
                    }

                    int effectiveAttendanceId = 0;
                    if (isSignOutAction) {
                      if (_selectedPlanIds.isEmpty) { 
                        try {
                          final genLog = _allLogs.firstWhere((log) {
                            bool isUnclosed = log['out_time'] == null || log['out_time'].toString().trim().isEmpty;
                            dynamic pId = log['planning_id'];
                            String t = (log['title'] ?? '').toString().trim();
                            bool isGen = (pId == null || pId.toString() == '0' || pId.toString().isEmpty) || t == "General Duty";
                            return isUnclosed && isGen;
                          });
                          effectiveAttendanceId = int.tryParse(genLog['id']?.toString() ?? '0') ?? _attendanceId;
                        } catch (_) {
                          effectiveAttendanceId = _attendanceId;
                        }
                      } else { // Task Sign-Out Target ID
                        try {
                          final taskLog = _allLogs.firstWhere((log) {
                            bool isUnclosed = log['out_time'] == null || log['out_time'].toString().trim().isEmpty;
                            dynamic pId = log['planning_id'];
                            return isUnclosed && pId.toString() == _selectedPlanIds.first;
                          });
                          effectiveAttendanceId = int.tryParse(taskLog['id']?.toString() ?? '0') ?? _attendanceId;
                        } catch (_) {
                          effectiveAttendanceId = _attendanceId;
                        }
                      }
                    }

                    final dynamic result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckInScreen(
                          employeeId: widget.employeeId,
                          workerId: widget.workerId,
                          selectedPlanIds: _selectedPlanIds,
                          attendanceId: effectiveAttendanceId,
                          selectedPlanTitle: selectedTitle,
                          userToken: widget.userToken,
                        ),
                      ),
                    );

                    if (result != null && result is Map<String, dynamic>) {
                      if (!mounted) return;
                      _refreshData();
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
                      Icon(
                        isSignOutAction ? Icons.logout_rounded : Icons.login_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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
                        "No matching attendance logs recorded today.",
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
                        final bool isActiveLog = marking['out_time'] == null || marking['out_time'].toString().trim().isEmpty;
                        final String itemTitle = _parseMarkingTitle(marking);

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
                              Text(itemTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Future<void> _refreshData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String getPlansUrl = ApiConstants.detailsProduct;
      final planningsResponse = await http
          .post(
            Uri.parse(getPlansUrl),
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer ${widget.userToken}",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) Navigator.pop(context);

      if (planningsResponse.statusCode == 200 && planningsResponse.body.isNotEmpty) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(planningsResponse.body);
          final Map<String, dynamic> dataPayload = responseData['data'] ?? {};
          final List<dynamic> markingsList = dataPayload['today_markings'] ?? [];

          List<Map<String, dynamic>> parsedMarkings = markingsList.map((item) {
            Map<String, dynamic> itemMap = Map<String, dynamic>.from(item as Map);
            return {
              ...itemMap,
              "id": itemMap['id'], // Grab explicit ID
              "planning_id": itemMap['planning_id'] ?? itemMap['plan_id'], // Grab explicit Task ID
              "title": itemMap['title'] ?? itemMap['project_name'] ?? itemMap['plan_title'] ?? itemMap['task_title'] ?? itemMap['planning_name'] ?? itemMap['work_title'] ?? 'General Duty',
              "in_time": itemMap['in_time'],
              "out_time": itemMap['out_time'],
            };
          }).toList();

          int activeAttendanceId = int.tryParse(dataPayload['attendance_id']?.toString() ?? '0') ?? 0;
          int pendingCount = int.tryParse(dataPayload['pending_previous_signouts_count']?.toString() ?? '0') ?? 0;
          List<String> activePlanningIds = List<String>.from((dataPayload['active_planning_ids'] as List? ?? []).map((e) => e.toString()));

          setState(() {
            _attendanceId = activeAttendanceId;
            _pendingSignoutsCount = pendingCount;
            _globallyActiveIds = activePlanningIds;
            _allLogs = parsedMarkings;

            if (_globallyActiveIds.isNotEmpty) {
              _selectedPlanIds = [_globallyActiveIds.first];
            } else {
              _selectedPlanIds.clear();
            }
          });
        } catch (e) {
          debugPrint("JSON Decode Error: $e");
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error updating layout: $e");
    }
  }
}