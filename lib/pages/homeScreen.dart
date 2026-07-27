import 'package:flutter/material.dart';
import 'package:my_lectures/pages/models/course.dart';
import 'package:my_lectures/main.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_lectures/pages/notificationManager.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({super.key});
  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  // Use the global notifier
  bool get isDarkMode => isDarkModeNotifier.value;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  String selectedDay = "Sun";
  String selectedTime = "08:30 AM";
  int selectedReminder = 30;

  //Create button sheet function. the "_" is to make it private.

  void _showAddCourseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isEnabled = nameController.text.trim().isNotEmpty &&
                roomController.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add New Lecture",
                      style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontWeight: FontWeight.bold, fontFamily: 'ShareTech', fontSize: 20)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    onChanged: (value) => setModalState(() {}),
                    style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723)),
                    decoration: InputDecoration(
                      labelText: "Course Name",
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.7), fontFamily: 'ShareTech', fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  TextField(
                    controller: roomController,
                    onChanged: (value) => setModalState(() {}),
                    style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723)),
                    decoration: InputDecoration(
                      labelText: "Room Name",
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.7), fontFamily: 'ShareTech', fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Text("Remind me: ", style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.8), fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: selectedReminder,
                        dropdownColor: isDarkMode ? const Color(0xFF212121) : const Color(0xFFFAF3E0),
                        style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 17),
                        items: [5, 10, 15, 30, 45, 60].map((int mins) {
                          return DropdownMenuItem<int>(
                              value: mins,
                              child: Text(mins == 60 ? "1 hour before" : "$mins mins before")
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setModalState(() { selectedReminder = newValue!; });
                        },
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Text("Day: ", style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.8), fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: selectedDay,
                        dropdownColor: isDarkMode ? const Color(0xFF212121) : const Color(0xFFFAF3E0),
                        style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 17),
                        items: ["Sun", "Mon", "Tue", "Wed", "Thur"].map((String day) {
                          return DropdownMenuItem<String>(value: day, child: Text(day));
                        }).toList(),
                        onChanged: (newValue) {
                          setModalState(() { selectedDay = newValue!; });
                        },
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Text("Time: ", style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.8), fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedTime = picked.format(context);
                            });
                          }
                        },
                        child: Text(selectedTime, style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled ? (isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37)) : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
                      minimumSize: const Size(160, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    ),
                    onPressed: isEnabled ? () async {
                      setState(() {
                        userSchedule.add(Course(
                          name: nameController.text,
                          room: roomController.text,
                          day: selectedDay,
                          time: selectedTime,
                          reminderMinutes: selectedReminder,
                        ));
                      });
                      nameController.clear();
                      roomController.clear();
                      Navigator.pop(context);
                      await _saveAndReschedule();
                    } : null,
                    child: const Text("Save Lecture",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'ShareTech', fontSize: 20)),
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

  void _showEditCourseModal(Course course) {
    int tempOffset = course.reminderMinutes;

    TextEditingController nameEditController = TextEditingController(text: course.name);
    TextEditingController roomEditController = TextEditingController(text: course.room);
    String tempDay = course.day;
    String tempTime = course.time;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isEnabled = nameEditController.text.trim().isNotEmpty &&
                roomEditController.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edit Lecture", style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontWeight: FontWeight.bold, fontFamily: 'ShareTech', fontSize: 20)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameEditController,
                    onChanged: (value) => setModalState(() {}),
                    style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723)),
                    decoration: InputDecoration(
                        labelText: "Course Name",
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.7), fontFamily: 'ShareTech', fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ),
                  TextField(
                    controller: roomEditController,
                    onChanged: (value) => setModalState(() {}),
                    style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723)),
                    decoration: InputDecoration(
                        labelText: "Room Name",
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.7), fontFamily: 'ShareTech', fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- REMINDER SELECTOR ---
                  Row(
                    children: [
                      Text("Remind me: ", style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.8), fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: tempOffset,
                        dropdownColor: isDarkMode ? const Color(0xFF212121) : const Color(0xFFFAF3E0),
                        style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 17),
                        items: [5, 10, 15, 30, 45, 60].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value == 60 ? "1 hour before" : "$value mins before"),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => tempOffset = val!),
                      ),
                    ],
                  ),

                  // Day Selector
                  Row(
                    children: [
                      Text("Day: ", style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.8), fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: tempDay,
                        dropdownColor: isDarkMode ? const Color(0xFF212121) : const Color(0xFFFAF3E0),
                        style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 17),
                        items: ["Sun", "Mon", "Tue", "Wed", "Thur"].map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                        onChanged: (val) => setModalState(() => tempDay = val!),
                      ),
                    ],
                  ),

                  // Time Selector
                  Row(
                    children: [
                      Text("Time: ", style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.8), fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setModalState(() {
                              tempTime = picked.format(context);
                            });
                          }
                        },
                        child: Text(tempTime, style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 18)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // DELETE BUTTON
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[400],
                          minimumSize: const Size(140, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        onPressed: () async {
                          setState(() {
                            userSchedule.remove(course);
                          });
                          Navigator.pop(context); // Pop immediately
                          await _saveAndReschedule();
                        },
                        child: Text("Delete", style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      ),

                      const SizedBox(width: 10),

                      // SAVE CHANGES BUTTON
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEnabled ? (isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37)) : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
                          minimumSize: const Size(140, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        onPressed: isEnabled ? () async {
                          setState(() {
                            course.name = nameEditController.text;
                            course.room = roomEditController.text;
                            course.day = tempDay;
                            course.time = tempTime;
                            course.reminderMinutes = tempOffset;
                          });

                          Navigator.pop(context); // Pop immediately
                          await _saveAndReschedule();
                        } : null,
                        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
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

  // Helper to save data AND update notifications
  Future<void> _saveAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(userSchedule.map((c) => c.toMap()).toList());
    await prefs.setString('saved_schedule', encodedData);

    // Update Notifications
    await NotificationService.cancelAll();
    for (int i = 0; i < userSchedule.length; i++) {
      await NotificationService.scheduleWeeklyNotification(
        id: i,
        name: userSchedule[i].name,
        room: userSchedule[i].room,
        day: userSchedule[i].day,
        timeStr: userSchedule[i].time,
        offsetMinutes: userSchedule[i].reminderMinutes,
      );
    }
  }

  int _timeToMinutes(String time) {
    if (time.isEmpty) return 0;
    try {
      String cleanTime = time.replaceAll('٠', '0').replaceAll('١', '1').replaceAll('٢', '2')
          .replaceAll('٣', '3').replaceAll('٤', '4').replaceAll('٥', '5')
          .replaceAll('٦', '6').replaceAll('٧', '7').replaceAll('٨', '8')
          .replaceAll('٩', '9').toUpperCase();

      final parts = cleanTime.split(' ');
      final hm = parts[0].split(':');
      int hour = int.parse(hm[0]);
      int minutes = int.parse(hm[1]);

      bool isPM = cleanTime.contains("PM") || cleanTime.contains("م");
      bool isAM = cleanTime.contains("AM") || cleanTime.contains("ص");

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return (hour * 60) + minutes;
    } catch (e) {
      debugPrint("Error parsing time: $time");
      return 0;
    }
  }

  Color _getDayColor(String day) {
    if (isDarkMode) {
      switch (day) {
        case "Sun": return Colors.redAccent;
        case "Mon": return Colors.blueAccent;
        case "Tue": return Colors.greenAccent;
        case "Wed": return Colors.orangeAccent;
        case "Thur": return Colors.purpleAccent;
        default: return Colors.blueAccent;
      }
    }
    switch (day) {
      case "Sun": return const Color(0xFF8D6E63); // Muted Mocha
      case "Mon": return const Color(0xFF795548); // Milk Chocolate
      case "Tue": return const Color(0xFF6D4C41); // Roasted Coffee
      case "Wed": return const Color(0xFF5D4037); // Espresso
      case "Thur": return const Color(0xFF4E342E); // Dark Bean
      default: return const Color(0xFF6F4E37);
    }
  }

  Widget _buildCell(String time, String day) {
    final course = userSchedule.firstWhere(
          (c) => c.time.replaceFirst(RegExp(r'^0'), '') == time && c.day == day,
      orElse: () => Course(name: "", room: "", day: "", time: ""),
    );

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: course.name.isEmpty
          ? const SizedBox(height: 80)
          : GestureDetector(
              onTap: () => _showEditCourseModal(course),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A1D2D) : const Color(0xFFE6D5B8),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isDarkMode ? [] : [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 2.7,
                      decoration: BoxDecoration(
                        color: _getDayColor(day),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(course.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
                            const SizedBox(height: 2),
                            Text(course.time, textAlign: TextAlign.center, style: TextStyle(color: _getDayColor(day), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
                            Text(course.room, textAlign: TextAlign.center, style: TextStyle(color: _getDayColor(day).withOpacity(0.7), fontWeight: FontWeight.bold ,fontSize: 8, fontFamily: 'ShareTech')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('saved_schedule');

    if (savedData != null) {
      setState(() {
        Iterable l = jsonDecode(savedData);
        userSchedule.clear();
        userSchedule.addAll(List<Course>.from(l.map((model) => Course.fromMap(model))));
      });
    } else {
      setState(() {
        userSchedule.clear();
      });
    }
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      children: ["Sun", "Mon", "Tue", "Wed", "Thur"].map((day) {
        Color dayColor = _getDayColor(day);
        int count = userSchedule.where((c) => c.day == day).length;
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1D2D) : const Color(0xFFE6D5B8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: dayColor, shape: BoxShape.circle),
                ),
                const SizedBox(height: 4),
                Text(day, textAlign: TextAlign.center,
                    style: TextStyle(color: dayColor, fontWeight: FontWeight.bold, fontFamily: 'ShareTech', fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  alignment: Alignment.center,
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFF3E2723).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text("$count", textAlign: TextAlign.center, style: TextStyle(color: isDarkMode ? Colors.white38 : const Color(0xFF3E2723).withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'ShareTech')),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<TableRow> _buildDynamicRows() {
    userSchedule.sort((a, b) => _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time)));

    List<String> timeSlots = userSchedule
        .map((c) => c.time.replaceFirst(RegExp(r'^0'), ''))
        .toSet()
        .toList();

    return timeSlots.map((time) {
      return TableRow(
        children: [
          _buildCell(time, "Sun"),
          _buildCell(time, "Mon"),
          _buildCell(time, "Tue"),
          _buildCell(time, "Wed"),
          _buildCell(time, "Thur"),
        ],
      );
    }).toList();
  }

  Future<void> clearSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_schedule');
    await NotificationService.cancelAll();
    setState(() {
      userSchedule.clear();
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF212121) : const Color(0xFFFAF3E0),
          title: Text("Clear All Lectures?", style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontSize: 20, fontFamily: 'ShareTech', fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete your schedule?", style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.8), fontWeight: FontWeight.bold, fontFamily: 'ShareTech', fontSize: 20)),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'ShareTech', color: isDarkMode ? Colors.white70 : const Color(0xFF6F4E37)))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37)),
              onPressed: () async {
                // Dismiss the dialog immediately
                Navigator.of(dialogContext).pop();

                // Perform the clear and update UI
                await clearSchedule();

                // Show a confirmation snackbar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Schedule Cleared", style: TextStyle(fontFamily: 'ShareTech'))),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(fontFamily: 'ShareTech', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
      appBar: AppBar(
        title: const Text("My Lectures", style: TextStyle(fontFamily: 'ShareTech', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 26)),
        backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFF6F4E37),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              ),
              child: IconButton(
                icon: Icon(isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined),
                color: isDarkMode ? Colors.white : const Color(0xFFFAF3E0),
                onPressed: () => setState(() => isDarkModeNotifier.value = !isDarkModeNotifier.value),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 2),
        child: Table(
          
          children: [
            _buildHeaderRow(),
            ..._buildDynamicRows(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: "btnDeleteSchedule",
              backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37),
              onPressed: _confirmDelete,
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            ),
            FloatingActionButton(
              heroTag: "btnAddSchedule",
              backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37),
              onPressed: _showAddCourseModal,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
          border: Border(top: BorderSide(color: isDarkMode ? Colors.black.withOpacity(0.05) : const Color(0xFFE6D5B8), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.calendar_month, "Schedule", () {
              // Already on home/schedule
            }, isActive: true),
            _buildBottomNavItem(Icons.notifications_active, "Reminders", () {
              Navigator.pushReplacementNamed(context, '/reminders');
            }),
            _buildBottomNavItem(Icons.document_scanner, "Scan", () {
              Navigator.pushReplacementNamed(context, '/scan');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
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
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontFamily: 'ShareTech',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
