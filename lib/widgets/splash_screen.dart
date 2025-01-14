import 'package:flutter/material.dart';
import 'package:mentors_app/main.dart';

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
  late Animation<Color?> _backgroundColorAnimation;
  bool _isLogoAnimationCompleted = false; // 로고 애니메이션 완료 여부

  @override
  void initState() {
    super.initState();

    // AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // 로고 확대 애니메이션 시간
      vsync: this,
    );

    // 로고 확대 애니메이션
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticInOut,
      ),
    );

    // 로고 위치 이동 애니메이션 (위로 이동)
    _logoPositionAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    // 배경색 변화 애니메이션
    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFFF0E6FF),
      end: const Color(0xFFB794F4),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    // 로고 애니메이션 실행
    _controller.forward().then((_) {
      setState(() {
        _isLogoAnimationCompleted = true; // 로고 애니메이션 완료
      });
    });

    // 스플래쉬 화면 종료
    Future.delayed(const Duration(seconds: 6), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
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
      mainAxisSize: MainAxisSize.min, // 텍스트를 중앙 정렬
      children: List.generate(
        text.length,
        (index) {
          return TweenAnimationBuilder(
            tween: Tween<Offset>(
              begin: const Offset(0, 1), // 아래에서 시작
              end: Offset.zero, // 원래 위치
            ),
            duration: Duration(milliseconds: 1000 + (index * 200)), // 순차적 등장
            curve: Curves.easeOutCubic, // 부드러운 애니메이션
            builder: (context, Offset offset, child) {
              return Opacity(
                opacity: offset.dy == 0 ? 1.0 : 0.8, // 위치에 따라 투명도 조정
                child: Transform.translate(
                  offset: offset * 50, // 텍스트 이동 거리
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
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
                  // 로고 위치와 크기 애니메이션
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
                  // 로고 애니메이션이 끝난 후 텍스트 애니메이션 실행
                  if (_isLogoAnimationCompleted) _buildAnimatedText(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
