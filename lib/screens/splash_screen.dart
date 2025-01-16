import 'package:flutter/material.dart';
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

    // 스플래쉬 화면 종료
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    });
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
          return TweenAnimationBuilder(
            tween: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ),
            duration: Duration(milliseconds: 1000 + (index * 200)),
            curve: Curves.easeOutCubic,
            builder: (context, Offset offset, child) {
              return Opacity(
                opacity: offset.dy == 0 ? 1.0 : 0.8,
                child: Transform.translate(
                  offset: offset * 50,
                  child: Text(
                    text[index],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black26,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
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
