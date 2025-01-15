import 'package:flutter/material.dart';
import 'package:mentors_app/widgets/banner_ad.dart';

class MentorMenteeScreen extends StatefulWidget {
  final String categoryName;

  const MentorMenteeScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<MentorMenteeScreen> createState() => _MentorMenteeScreenState();
}

class _MentorMenteeScreenState extends State<MentorMenteeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25.5, horizontal: 12.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "사용자님의 역할을 선택해 주세요",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: const Text(
                  "멘토",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "지식과 열정을 나누며 더 큰 성장을 이끌어 보세요.",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  // 멘토 선택 동작
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: const Text(
                  "멘티",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "더 큰 도약을 꿈꾸는 당신을 위한 맞춤형 멘토링 서비스.",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  // 멘티 선택 동작
                },
              ),
            ),
            const Spacer(),
            Center(
              child: const BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
