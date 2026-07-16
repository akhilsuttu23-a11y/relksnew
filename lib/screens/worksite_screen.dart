import 'dart:ui';
import 'package:flutter/material.dart';
import 'check_in_screen.dart';
import 'auth_utils.dart';
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
  late List<Map<String, dynamic>> _todayLogs;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _attendanceId = widget.initialAttendanceId;
    _selectedPlanIds = List<String>.from(widget.initialActivePlanningIds);
    _isCheckedIn = _attendanceId > 0;
    _todayLogs = List<Map<String, dynamic>>.from(widget.todayMarkings);
  }

  String _formatTimeString(dynamic timeString) {
    if (timeString == null) return "--:--";
    try {
      DateTime parsed = DateTime.parse(timeString.toString()).toLocal();
      String hour = parsed.hour.toString().padLeft(2, '0');
      String minute = parsed.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (_) {
      return timeString.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isCheckedIn ? "Active Shift Detail" : "Select Work Plan",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => AuthUtils.logout(context, widget.userToken),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://images.unsplash.com/photo-1541888946425-d81bb19240f5?q=80&w=2070",
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_circle_rounded,
                              color: Color(0xFF1E6FD9),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Employee Name: ${widget.workerName}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1F21),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isCheckedIn
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isCheckedIn
                                  ? Colors.red.shade300
                                  : Colors.blue.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isCheckedIn
                                    ? Icons.logout_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: _isCheckedIn
                                    ? Colors.red.shade800
                                    : Colors.blue.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isCheckedIn
                                      ? "CURRENT STATUS: ACTIVE SHIFT"
                                      : "CURRENT STATUS: OUT OF SHIFT",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isCheckedIn
                                        ? Colors.red.shade900
                                        : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isCheckedIn
                              ? "Your currently checked-in projects (Checkout Required):"
                              : "Select the project allocation lists you are checking into today:",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: widget.availablePlans.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      "No projects assigned today.",
                                      style: TextStyle(
                                        color: Colors.black45,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  itemCount: widget.availablePlans.length,
                                  itemBuilder: (context, index) {
                                    final plan = widget.availablePlans[index];
                                    final String planId = plan['id'].toString();
                                    final bool isChecked = _selectedPlanIds
                                        .contains(planId);

                                    return CheckboxListTile(
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['title'].toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E1F21),
                                            ),
                                          ),
                                          if (_isCheckedIn && isChecked)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2.0,
                                              ),
                                              child: Text(
                                                "Active (Checked-In)",
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      activeColor: _isCheckedIn
                                          ? const Color(0xFFD9222A)
                                          : const Color(0xFF1E6FD9),
                                      value: isChecked,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      onChanged: _isCheckedIn
                                          ? null
                                          : (bool? checked) {
                                              setState(() {
                                                if (checked == true) {
                                                  _selectedPlanIds.add(planId);
                                                } else {
                                                  _selectedPlanIds.remove(
                                                    planId,
                                                  );
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
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: _isCheckedIn
                                  ? [
                                      const Color(0xFFD9222A),
                                      const Color(0xFF99181E),
                                    ]
                                  : [
                                      const Color(0xFF1E6FD9),
                                      const Color(0xFF0F4C99),
                                    ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_selectedPlanIds.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please select at least one project first.",
                                    ),
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
                                    selectedPlanIds: _selectedPlanIds,
                                    attendanceId: _attendanceId,
                                    selectedPlanTitle:
                                        _selectedPlanIds.length == 1
                                        ? widget.availablePlans.firstWhere(
                                            (p) =>
                                                p['id'].toString() ==
                                                _selectedPlanIds.first,
                                          )['title']
                                        : "${_selectedPlanIds.length} Projects Selected",
                                    userToken: widget.userToken,
                                  ),
                                ),
                              );

                              if (result != null &&
                                  result is Map<String, dynamic>) {
                                setState(() {
                                  if (result['out_time'] != null) {
                                    _todayLogs.insert(0, {
                                      'title': _selectedPlanIds.length == 1
                                          ? widget.availablePlans.firstWhere(
                                              (p) =>
                                                  p['id'].toString() ==
                                                  _selectedPlanIds.first,
                                            )['title']
                                          : "${_selectedPlanIds.length} Projects Summary Log",
                                      'in_time': result['in_time'],
                                      'out_time': result['out_time'],
                                    });
                                  }

                                  _attendanceId = result['attendance_id'] ?? 0;
                                  _selectedPlanIds = List<String>.from(
                                    (result['active_planning_ids'] as List? ??
                                            [])
                                        .map((e) => e.toString()),
                                  );
                                  _isCheckedIn = _attendanceId > 0;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isCheckedIn
                                      ? "PROCEED TO SYSTEM CHECK-OUT"
                                      : "PROCEED TO SYSTEM CHECK-IN",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isCheckedIn
                                      ? Icons.logout_rounded
                                      : Icons.login_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.history_toggle_off_rounded,
                              color: Color(0xFF1E6FD9),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Today's Shift Log History (${_todayLogs.length})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E1F21),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _todayLogs.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "No previous attendance logs recorded for today yet.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _todayLogs.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final marking = _todayLogs[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            marking['title'] ?? "Worksite Plan",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.green.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                "IN: ${_formatTimeString(marking['in_time'])}",
                                                style: TextStyle(
                                                  color: Colors.green.shade800,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.orange.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                "OUT: ${_formatTimeString(marking['out_time'])}",
                                                style: TextStyle(
                                                  color: Colors.orange.shade800,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
