import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/components/customButton.dart';
import 'package:mentors_app/screens/join_screen.dart';
import 'package:mentors_app/widgets/banner_ad.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final Logger logger = Logger();

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('이메일과 비밀번호를 입력해주세요.'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
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
              await userDocRef.update({
                'updated_at': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공!'),
        ),
      );
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      String errorMessage = '로그인에 실패했습니다';
      if (e.code == 'user-not-found') {
        errorMessage = '존재하지 않는 이메일입니다.';
      } else if (e.code == 'wrong-password') {
        errorMessage = '비밀번호가 잘못되었습니다.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류 발생 : $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: const Text(
          "로그인페이지",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Mentors",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "이메일",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "비밀번호",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      label: "로그인",
                      onPressed: _login,
                      backgroundColor: const Color(0xFFB794F4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderRadius: 24,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
              const SizedBox(height: 10),
              CustomButton(
                label: "회원가입",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinScreen(),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF9575CD), // 기존 배경색 유지
                padding: const EdgeInsets.symmetric(vertical: 14), // 기존 패딩 유지
                borderRadius: 24, // 기존 버튼 모양 유지
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(
                height: 180,
              ),
              Center(
                child: BannerAdWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
