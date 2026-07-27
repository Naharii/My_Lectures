import 'package:flutter/material.dart';
import 'package:my_lectures/pages/models/course.dart';
import 'package:my_lectures/pages/scan.dart';
import 'package:my_lectures/pages/reminders.dart';
import 'package:my_lectures/pages/homeScreen.dart';
import 'package:my_lectures/pages/notificationManager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_lectures/pages/models/course.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("Error initializing notifications: $e");
  }

  runApp(

      const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const homeScreen(),
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: isDark ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
            canvasColor: isDark ? const Color(0xFF0D0F1A) : const Color(0xFFFAF3E0),
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? const Color(0xFF0D0F1A) : const Color(0xFF6F4E37),
              foregroundColor: Colors.white,
            ),
            colorScheme: isDark 
              ? const ColorScheme.dark(
                  surface: Color(0xFF212121),
                  primary: Colors.deepPurple,
                )
              : const ColorScheme.light(
                  surface: Color(0xFFFAF3E0),
                  primary: Color(0xFF6F4E37),
                  onPrimary: Colors.white,
                  secondary: Color(0xFF3E2723),
                  onSurface: Color(0xFF3E2723),
                ),
          ),
          routes: {
            '/homeScreen': (context) => const homeScreen(),
            '/scan': (context) => const ScanPage(),
            '/reminders': (context) => const reminders(),
          },
        );
      }
    );
  }
}
