import 'package:flutter/material.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: const Text(
          '자유게시판',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              // 검색 기능 개발필요
            },
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              // 글 작성 기능 개발필요
            },
            icon: const Icon(Icons.edit, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.separated(
          itemCount: 10, // 임시 게시글 수
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Row(
                children: [
                  Text(
                    '글제목 $index',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.article,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const Spacer(),
                  const Text(
                    '조회수 12377',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  const Text(
                    '닉네임',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  const SizedBox(width: 10),
                  const Text(
                    '11:37',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '1',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '댓글',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              onTap: () {
                // 게시글 상세보기 이동 개발필요
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // 게시판 탭 활성화
        onTap: (index) {
          // 네비게이션 동작
          if (index == 0) {
            Navigator.pushNamed(context, '/main'); // 메인화면 이동
          }
        },
        selectedItemColor: const Color(0xFFB794F4),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "게시판"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "채팅방"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}
