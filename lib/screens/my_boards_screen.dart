import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/services/board_service.dart';

class MyBoardsScreen extends StatelessWidget {
  const MyBoardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BoardService boardService = BoardService();
    final String? userId = boardService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 글'),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: userId == null
          ? const Center(child: Text("로그인이 필요합니다."))
          : FutureBuilder(
              future: boardService.getBoardsByAuthorId(userId),
              builder: (context, AsyncSnapshot<List<BoardModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("데이터를 불러오는 중 오류 발생"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("작성한 글이 없습니다."));
                }

                final myBoards = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: myBoards.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final board = myBoards[index];
                    final formattedDate =
                        DateFormat('yy.MM.dd HH:mm').format(board.createdAt);

                    return ListTile(
                      leading:
                          const Icon(Icons.article, color: Color(0xFFB794F4)),
                      title: Text(
                        '[${board.category}] ${board.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '작성일: $formattedDate',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '조회수 ${board.views}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '추천 ${board.likes}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BoardDetailScreen(
                              boardId: board.id,
                              title: board.title,
                              content: board.content,
                              author: board.author,
                              authorUid: board.authorUid,
                              category: board.category,
                              likes: board.likes,
                              views: board.views,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
