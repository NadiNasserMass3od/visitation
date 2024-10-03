import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:visitation/screens/splash_screen.dart';
import 'helpers/notification_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visitation/screens/password_screen.dart';

Future<void> _requestPermissions() async {
  await Permission.manageExternalStorage.request();
  await Permission.notification.request();
  await Permission.storage.request();
  await Permission.scheduleExactAlarm.request();
  await Permission.storage.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper.initNotifications();
  tz.initializeTimeZones();
  await _requestPermissions();
  NotificationHelper().scheduleDailyNotifications();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  bool isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

  runApp(VisitationApp(isAuthenticated: isAuthenticated));
}

class VisitationApp extends StatelessWidget {
  final bool isAuthenticated;

  const VisitationApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متابعة الافتقاد',
      theme: ThemeData(primarySwatch: Colors.blue),
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      home: isAuthenticated ? const SplashScreen() : const PasswordScreen(),
    );
  }
}
