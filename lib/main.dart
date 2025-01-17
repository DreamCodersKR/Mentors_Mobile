import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mentors_app/firebase_options.dart';
import 'package:mentors_app/screens/board_screen.dart';
import 'package:mentors_app/screens/chat_list_screen.dart';
import 'package:mentors_app/screens/login_screen.dart';
import 'package:mentors_app/screens/main_screen.dart';
import 'package:mentors_app/screens/my_info_screen.dart';
import 'package:mentors_app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
        '/board': (context) => const BoardScreen(),
        '/login': (context) => const LoginScreen(),
        '/chat': (context) => const ChatListScreen(),
        '/myInfo': (context) => const MyInfoScreen(),
      },
    );
  }
}
