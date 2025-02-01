import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoPositionAnimation;
  bool _isLogoAnimationCompleted = false;

  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // 로고 확대 애니메이션
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticInOut,
      ),
    );

    // 로고 위치 이동 애니메이션
    _logoPositionAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    // 애니메이션 실행
    _controller.forward().then((_) {
      setState(() {
        _isLogoAnimationCompleted = true;
      });
    });
    _initializeAdsAndNavigate();
  }

  Future<void> _initializeAdsAndNavigate() async {
    try {
      // Google Mobile Ads 초기화
      await MobileAds.instance.initialize();
      logger.i("Google Mobile Ads 초기화 완료");

      // FCM 토큰 업데이트
      await _checkAndUpdateFCMToken();
    } catch (e) {
      logger.e("초기화 실패: $e");
    }

    // 스플래시 화면 종료 및 메인 화면으로 이동
    if (mounted) {
      Future.delayed(const Duration(seconds: 6), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      });
    }
  }

  Future<void> _checkAndUpdateFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.i("사용자가 로그인되어 있지 않습니다.");
      return;
    }

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (userDoc.exists) {
          final existingTokens = userDoc.data()?['fcm_tokens'] ?? [];
          if (!existingTokens.contains(fcmToken)) {
            await userDocRef.update({
              'fcm_tokens': FieldValue.arrayUnion([fcmToken]),
              'updated_at': FieldValue.serverTimestamp(),
            });
            logger.i("새로운 FCM 토큰 추가 : $fcmToken");
          } else {
            logger.i("이미 존재하는 FCM 토큰입니다 : $fcmToken");
          }
        }
      }
    } catch (e) {
      logger.e("FCM 토큰 업데이트 실패: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedText() {
    const String text = "Mentors";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        text.length,
        (index) {
          return TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: Colors.grey,
              end: Colors.white,
            ),
            duration: Duration(milliseconds: 800 + (index * 200)),
            curve: Curves.easeInOut,
            builder: (context, color, child) {
              return Text(
                text[index],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  shadows: const [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black26,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0E6FF),
              Color(0xFFB794F4),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, _logoPositionAnimation.value),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_isLogoAnimationCompleted) _buildAnimatedText(),
            ],
          ),
        ),
      ),
    );
  }
}
