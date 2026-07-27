import 'package:flutter/material.dart';
import 'package:my_lectures/pages/models/course.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_lectures/pages/notificationManager.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  // PLACE YOUR GEMINI API KEY HERE
  static const String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndScanImage() async {
    if (_apiKey.isEmpty || _apiKey.startsWith('YOUR_GEMINI')) {
      _showError("Please set your Gemini API Key in scan.dart");
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);


      String modelName = 'models/gemini-2.5-flash';
      var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/$modelName:generateContent?key=$_apiKey');

      final prompt = """
        Look at this university schedule image.
        1. It uses Arabic text for subjects and rooms.
        2. It has a table layout with columns for days.
        3. Red dots in the cells indicate when a lecture takes place.

        Please extract all classes into a JSON list with exactly these keys:
        'day', 'subject', 'start_time', 'room'.
        
        Rules:
        - Keep 'subject' and 'room' in the original Arabic.
        - Map 'day' to English: 'Sun', 'Mon', 'Tue', 'Wed', 'Thur'.
        - Format 'start_time' as 'HH:mm AM/PM'.
        - Return ONLY the JSON array. No markdown, no '```json' tags.
        
        Note: if the subject is written as a dash '-', then take the name (and only the subject name) of the subject directly above.
        and if the subject above is also a dash '-', then take the name of the subject above that one for both.
      """;

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      });

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // If flash isn't available, try the older Pro model as a fallback
      if (response.statusCode == 404) {
        url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$_apiKey');
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? responseText = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (responseText != null) {
          // Clean up response text in case Gemini adds markdown
          String cleanedJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
          final List<dynamic> decoded = jsonDecode(cleanedJson);

          List<Course> detectedCourses = decoded.map((item) {
            return Course(
              name: item['subject'] ?? 'Unknown Subject',
              room: item['room'] ?? 'N/A',
              day: item['day'] ?? 'Sun',
              time: item['start_time'] ?? '08:00 AM',
            );
          }).toList();

          if (detectedCourses.isNotEmpty) {
            _showDetectedCoursesDialog(detectedCourses);
          } else {
            _showError("No lectures detected in the image.");
          }
        } else {
          _showError("Empty response from AI.");
        }
      } else {
        // Handle specific error codes
        if (response.statusCode == 429) {
          _showError("API Rate Limit Exceeded. Please wait a minute and try again.");
        } else {
          _showError("Scanning Error (${response.statusCode}). Please try again later.");
        }
        debugPrint("FULL API ERROR: ${response.body}");
      }
    } catch (e) {
      debugPrint("Gemini OCR Error: $e");
      _showError("Scanning failed ($e)");
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _showError(String message) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message,
              style: TextStyle(
                color: isDarkMode ? Colors.black : Colors.white,
                fontFamily: 'ShareTech',
              )),
          backgroundColor: isDarkMode ? Colors.white : const Color(0xFF6F4E37),
        ),
      );
    }
  }

  void _showDetectedCoursesDialog(List<Course> courses) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Detected Lectures",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF3E2723),
              fontFamily: 'ShareTech',
              fontWeight: FontWeight.bold,
              fontSize: 22,
            )),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final c = courses[index];
              return ListTile(
                title: Text(c.name,
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : const Color(0xFF3E2723),
                        fontFamily: 'ShareTech',
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                subtitle: Text("${c.day} at ${c.time} (Room: ${c.room})",
                    style: TextStyle(
                        color: isDarkMode ? Colors.white70 : const Color(0xFF3E2723).withOpacity(0.7),
                        fontFamily: 'ShareTech',
                        fontSize: 14)),
                leading: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              );
            },
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[400],
                  minimumSize: const Size(130, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel",
                    style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF3E2723), fontFamily: 'ShareTech', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37),
                  minimumSize: const Size(130, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                onPressed: () async {
                  userSchedule.clear();
                  userSchedule.addAll(courses);
                  await _saveAndReschedule();
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/homeScreen', (route) => false);
                  }
                },
                child: const Text("Import Schedule",
                    style: TextStyle(color: Colors.white, fontFamily: 'ShareTech', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(userSchedule.map((c) => c.toMap()).toList());
    await prefs.setString('saved_schedule', encodedData);

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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color scaffoldBg = isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0);
    Color cardColor = isDarkMode ? const Color(0xFF1A1D2D) : const Color(0xFFE6D5B8);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homeScreen'),
        ),
        title: const Text("Scan Schedule", style: TextStyle(fontFamily: 'ShareTech', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)),
        backgroundColor: isDarkMode ? const Color(0xFF0D0F1A) : const Color(0xFF6F4E37),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black : const Color(0xFFFAF3E0),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: isDarkMode ? Colors.deepPurple.withOpacity(0.5) : const Color(0xFF6F4E37).withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: _isScanning
                          ? CircularProgressIndicator(color: isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37))
                          : Icon(Icons.document_scanner, size: 80, color: (isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37)).withOpacity(0.3)),
                    ),
                  ),
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: MediaQuery.of(context).size.height * 0.6 * _animation.value,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37),
                              boxShadow: [
                                BoxShadow(color: (isDarkMode ? Colors.blueAccent : const Color(0xFF6F4E37)).withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Text(
                  "Smart Gemini Scanning",
                  style: TextStyle(fontFamily: 'ShareTech', fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF3E2723)),
                ),
                const SizedBox(height: 10),
                Text(
                  "Upload a photo of your university schedule.\nGemini will read the schedule and extract the lectures automatically.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'ShareTech', fontSize: 14, color: isDarkMode ? Colors.grey : const Color(0xFF3E2723).withOpacity(0.6)),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF6F4E37),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isScanning ? null : _pickAndScanImage,
                  child: Text(
                      _isScanning ? "AI IS THINKING..." : "CHOOSE SCHEDULE PHOTO",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'ShareTech')
                  ),
                ),
              ],
            ),
          ),
        ],
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
            _buildBottomNavItem(context, Icons.notifications_active, "Reminders", () {
              Navigator.pushReplacementNamed(context, '/reminders');
            }),
            _buildBottomNavItem(context, Icons.document_scanner, "Scan", () {}, isActive: true),
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
