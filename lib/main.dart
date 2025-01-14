import 'package:flutter/material.dart';
import 'package:mentors_app/widgets/splash_screen.dart';
// import 'package:google_fonts/google_fonts.dart';

void main() {
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

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF0E6FF).withAlpha(190),
              const Color(0xFFB794F4).withAlpha(190),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // 로고 애니메이션
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),
              // 환영 텍스트
              Text(
                'dddd',
                // style: GoogleFonts.notoSans(
                //   fontSize: 32,
                //   fontWeight: FontWeight.bold,
                //   color: Colors.white,
                //   shadows: [
                //     Shadow(
                //       blurRadius: 10.0,
                //       color: Colors.black.withOpacity(0.3),
                //       offset: const Offset(0, 5),
                //     ),
                //   ],
                // ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '메뉴',
                          // style: GoogleFonts.notoSans(
                          //   fontSize: 24,
                          //   fontWeight: FontWeight.bold,
                          //   color: const Color(0xFF8B5CF6),
                          // ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildMenuCard(context, '프로필', Icons.person),
                              _buildMenuCard(context, '설정', Icons.settings),
                              _buildMenuCard(
                                  context, '알림', Icons.notifications),
                              _buildMenuCard(context, '통계', Icons.bar_chart),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // 메뉴 아이템 탭 동작
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              Text(
                title,
                // style: GoogleFonts.notoSans(
                //   fontSize: 16,
                //   fontWeight: FontWeight.bold,
                //   color: const Color(0xFF8B5CF6),
                // ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
