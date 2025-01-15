import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mentors_app/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentors',
      theme: ThemeData(
        primaryColor: const Color(0xFFB794F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB794F4),
          primary: const Color(0xFFB794F4),
          secondary: const Color(0xFF9575CD),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
