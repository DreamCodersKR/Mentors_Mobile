import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/screens/match_history_screen.dart';
import 'package:mentors_app/widgets/banner_ad.dart';
import 'package:mentors_app/widgets/question_item.dart';

final Logger logger = Logger();

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController question1Controller = TextEditingController();
    final TextEditingController question2Controller = TextEditingController();
    final TextEditingController question3Controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: const Text(
          'IT/전문기술 > 멘티 질문페이지',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.black,
            ),
            onPressed: () {
              // 알림 기능 구현 예정
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuestionItem(
                questionTitle: 'Q1. 당신이 배우고 싶은 분야는 무엇입니까?',
                hintText:
                    '예: 웹개발(Frontend: React, Vue / Backend: Node.js, Spring), 데이터 분석(Python, R), 클라우드 인프라(AWS, Azure), 보안, 네트워크 등',
                maxLength: 150,
                maxLines: 3,
                controller: question1Controller,
              ),
              const SizedBox(height: 24),
              QuestionItem(
                questionTitle: 'Q2. 해당 분야에서 무엇을 배우고 싶으십니까?',
                hintText:
                    '예: 프로젝트 실무 적용 방법, 프레임워크 사용법(Spring Boot, Django), 데이터 시각화, 머신러닝 모델 구현, DevOps 파이프라인 구축 등',
                maxLength: 150,
                maxLines: 3,
                controller: question2Controller,
              ),
              const SizedBox(height: 24),
              QuestionItem(
                questionTitle: 'Q3. 어떤 도움을 바랍니까?',
                hintText:
                    '예: 실무 가이드(코딩 컨벤션, 아키텍처 설계), 최신 기술 동향(트렌드, 유망 스택), 포트폴리오 피드백, 취업 상담, 오픈소스 기여 안내 등',
                maxLength: 150,
                maxLines: 3,
                controller: question3Controller,
              ),
              const SizedBox(height: 26),
              Center(
                child: const BannerAdWidget(),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MatchHistoryScreen(),
                      ),
                    );
                    // 작성된 데이터 출력 (디버깅용)
                    logger.i('Q1: ${question1Controller.text}');
                    logger.i('Q2: ${question2Controller.text}');
                    logger.i('Q3: ${question3Controller.text}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9575CD),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    '매칭완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}
