import 'package:flutter/material.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/screens/search_screen.dart';
import 'package:mentors_app/screens/write_board_screen.dart';
import 'package:mentors_app/widgets/bottom_nav_bar.dart';

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.search, color: Colors.black),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WriteBoardScreen(),
                  ),
                );
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
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoardDetailScreen(
                          title: '글제목 $index',
                          content: '글 내용 나옴',
                          author: '닉네임 나옴',
                          likes: 111,
                          views: 12344,
                        ),
                      ));
                },
              );
            },
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 1,
            onTabSelected: (index) {
              if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                );
              }
            }));
  }
}
