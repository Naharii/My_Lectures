import 'package:flutter/material.dart';
import 'package:my_lectures/pages/models/course.dart';
import 'package:intl/intl.dart';
import 'package:my_lectures/pages/notificationManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class reminders extends StatefulWidget {
  const reminders({super.key});

  @override
  State<reminders> createState() => _remindersState();
}

class _remindersState extends State<reminders> {
  final TextEditingController courseController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  String selectedType = "Homework";
  DateTime selectedDate = DateTime.now();
  int selectedRemindBefore = 24; // Default 1 day

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('user_reminders');
    if (data != null) {
      setState(() {
        Iterable l = jsonDecode(data);
        userReminders.clear();
        userReminders.addAll(List<Reminder>.from(l.map((m) => Reminder.fromMap(m))));
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(userReminders.map((r) => r.toMap()).toList());
    await prefs.setString('user_reminders', encoded);
  }

  void _showAddReminderModal({Reminder? reminder, int? index}) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isEditing = reminder != null;

    if (isEditing) {
      courseController.text = reminder.course;
      detailsController.text = reminder.details;
      selectedType = reminder.type;
      selectedDate = reminder.dueDate;
      selectedRemindBefore = reminder.remindBeforeHours;
    } else {
      courseController.clear();
      detailsController.clear();
      selectedType = "Homework";
      selectedDate = DateTime.now();
      selectedRemindBefore = 24;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isEnabled = courseController.text.trim().isNotEmpty;
            Color textColor = isDarkMode ? Colors.white : const Color(0xFF3E2723);
            Color subTextColor = isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.7);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEditing ? "Edit Reminder" : "Add Reminder", style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
                      IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Type", style: TextStyle(color: subTextColor, fontFamily: 'ShareTech', fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildTypeButton("Homework", selectedType == "Homework", (val) => setModalState(() => selectedType = val)),
                      const SizedBox(width: 10),
                      _buildTypeButton("Quiz", selectedType == "Quiz", (val) => setModalState(() => selectedType = val)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: courseController,
                    style: TextStyle(color: textColor),
                    onChanged: (v) => setModalState(() {}),
                    decoration: InputDecoration(
                      labelText: "Course Name",
                      labelStyle: TextStyle(color: subTextColor, fontFamily: 'ShareTech'),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDarkMode ? Colors.white24 : const Color(0xFF3E2723).withOpacity(0.2))),
                    ),
                  ),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Details (Optional)",
                      labelStyle: TextStyle(color: subTextColor, fontFamily: 'ShareTech'),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDarkMode ? Colors.white24 : const Color(0xFF3E2723).withOpacity(0.2))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Due Date:", style: TextStyle(color: subTextColor, fontFamily: 'ShareTech')),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && mounted) {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (time != null && mounted) {
                              setModalState(() {
                                selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                              });
                            }
                          }
                        },
                        child: Text(DateFormat('EEE, MMM d, h:mm a').format(selectedDate), style: TextStyle(color: isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37), fontFamily: 'ShareTech')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Remind me:", style: TextStyle(color: subTextColor, fontFamily: 'ShareTech')),
                  DropdownButton<int>(
                    value: selectedRemindBefore,
                    dropdownColor: isDarkMode ? const Color(0xFF212121) : const Color(0xFFFAF3E0),
                    isExpanded: true,
                    style: TextStyle(color: textColor, fontFamily: 'ShareTech'),
                    items: [6, 12, 24, 48, 72].map((int hours) {
                      String label = hours < 24 ? "$hours hours before" : "${hours ~/ 24} days before";
                      return DropdownMenuItem(value: hours, child: Text(label));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedRemindBefore = val!),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnabled ? (isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37)) : (isDarkMode ? Colors.grey : Colors.grey[400]),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isEnabled ? () async {
                        String id = isEditing ? reminder.id : DateTime.now().millisecondsSinceEpoch.toString();
                        
                        if (isEditing) {
                          await NotificationService.cancelNotification(id);
                        }

                        Reminder newReminder = Reminder(
                          id: id,
                          type: selectedType,
                          course: courseController.text,
                          details: detailsController.text,
                          dueDate: selectedDate,
                          remindBeforeHours: selectedRemindBefore,
                        );

                        setState(() {
                          if (isEditing) {
                            userReminders[index!] = newReminder;
                          } else {
                            userReminders.add(newReminder);
                          }
                        });

                        await NotificationService.scheduleReminderNotification(
                          id,
                          selectedType,
                          courseController.text,
                          selectedDate,
                          selectedRemindBefore,
                        );
                        await _saveReminders();
                        courseController.clear();
                        detailsController.clear();
                        if (mounted) Navigator.pop(context);
                      } : null,
                      child: Text(isEditing ? "Update Reminder" : "Save Reminder", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'ShareTech')),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReminderDetails(Reminder rem) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isQuiz = rem.type == "Quiz";
    Color themeColor = isQuiz 
        ? (isDarkMode ? const Color(0xFFF48FB1) : const Color(0xFFD2691E)) 
        : (isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37));
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF3E2723);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1D2D) : const Color(0xFFFAF3E0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(rem.type.toUpperCase(), style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
              ),
              const Spacer(),
              IconButton(icon: Icon(Icons.close, color: textColor, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rem.course, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
            const SizedBox(height: 10),
            if (rem.details.isNotEmpty) ...[
              Text("Details:", style: TextStyle(color: themeColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF3E2723).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Text(rem.details, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 16, fontFamily: 'ShareTech')),
              ),
              const SizedBox(height: 15),
            ],
            _buildDetailRow(Icons.calendar_today, "Due Date", DateFormat('EEEE, MMM d, yyyy').format(rem.dueDate)),
            _buildDetailRow(Icons.access_time, "Time", DateFormat('h:mm a').format(rem.dueDate)),
            _buildDetailRow(Icons.notifications_active, "Reminder", "${rem.remindBeforeHours < 24 ? '${rem.remindBeforeHours} hours' : '${rem.remindBeforeHours ~/ 24} days'} before"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37)),
          const SizedBox(width: 10),
          Text("$label: ", style: TextStyle(color: isDarkMode ? Colors.white60 : const Color(0xFF3E2723).withOpacity(0.6), fontSize: 14, fontFamily: 'ShareTech')),
          Text(value, style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isSelected, Function(String) onTap) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37)) : (isDarkMode ? Colors.white10 : const Color(0xFFE6D5B8)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? Colors.white60 : const Color(0xFF3E2723).withOpacity(0.6)), fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
      appBar: AppBar(
        title: const Text("Reminders", style: TextStyle(fontFamily: 'ShareTech', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)),
        backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFF6F4E37),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homeScreen'),
        ),
      ),
      body: userReminders.isEmpty
          ? Center(child: Text("No reminders yet", style: TextStyle(color: isDarkMode ? Colors.white38 : const Color(0xFF3E2723).withOpacity(0.4), fontFamily: 'ShareTech', fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 100),
              itemCount: userReminders.length,
              itemBuilder: (context, index) {
                final rem = userReminders[index];
                bool isQuiz = rem.type == "Quiz";
                Color themeColor = isQuiz 
        ? (isDarkMode ? const Color(0xFFF48FB1) : const Color(0xFFD2691E))
        : (isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37));
                Color cardColor = isDarkMode ? const Color(0xFF1A1D2D) : const Color(0xFFE6D5B8);
                Color textColor = isDarkMode ? Colors.white : const Color(0xFF3E2723);
                Color subTextColor = isDarkMode ? Colors.white60 : const Color(0xFF3E2723).withOpacity(0.7);
                Color dateColor = isDarkMode ? Colors.white38 : const Color(0xFF3E2723).withOpacity(0.5);

                return GestureDetector(
                  onTap: () => _showReminderDetails(rem),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDarkMode ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 6,
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: themeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          rem.type.toUpperCase(),
                                          style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'ShareTech'),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showAddReminderModal(reminder: rem, index: index),
                                        child: Icon(Icons.edit_outlined, color: isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37), size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(rem.course, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
                                  if (rem.details.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      rem.details,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: subTextColor, fontSize: 14, fontFamily: 'ShareTech'),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, color: dateColor, size: 14),
                                      const SizedBox(width: 5),
                                      Text(DateFormat('EEE, MMM d, h:mm a').format(rem.dueDate), style: TextStyle(color: dateColor, fontSize: 13, fontFamily: 'ShareTech')),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.notifications_none, color: dateColor, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Remind ${rem.remindBeforeHours < 24 ? '${rem.remindBeforeHours}h' : '${rem.remindBeforeHours ~/ 24}d'} before",
                                        style: TextStyle(color: dateColor, fontSize: 13, fontFamily: 'ShareTech'),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () async {
                                          await NotificationService.cancelNotification(rem.id);
                                          setState(() => userReminders.removeAt(index));
                                          await _saveReminders();
                                        },
                                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderModal,
        backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
          border: Border(top: BorderSide(color: isDarkMode ? Colors.black.withValues(alpha: 0.05) : const Color(0xFFE6D5B8), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(context, Icons.calendar_month, "Schedule", () {
              Navigator.pushReplacementNamed(context, '/homeScreen');
            }),
            _buildBottomNavItem(context, Icons.notifications_active, "Reminders", () {}, isActive: true),
            _buildBottomNavItem(context, Icons.document_scanner, "Scan", () {
              Navigator.pushReplacementNamed(context, '/scan');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color activeColor = isDarkMode ? Colors.white : const Color(0xFF6F4E37);
    Color inactiveColor = isDarkMode ? Colors.white60 : const Color(0xFF3E2723).withOpacity(0.5);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? activeColor : inactiveColor, fontFamily: 'ShareTech', fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
