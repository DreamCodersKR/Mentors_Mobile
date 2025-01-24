import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '알림',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              // 알림 전체 삭제 로직
            },
            icon: const Icon(Icons.delete, color: Colors.black),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3, // 알림 개수 (더미 데이터 기준)
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.mail, color: Colors.grey),
            title: Text(
              index == 0 ? '매칭이 완료되었습니다.' : 'ooo님이 회원님에게 댓글을 남겼습니다.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              index == 0
                  ? '2분 전'
                  : index == 1
                      ? '20시간 전'
                      : '2025.01.24 15:43:01',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // 알림 클릭 시 상세 페이지 이동 로직
            },
          );
        },
      ),
    );
  }
}
