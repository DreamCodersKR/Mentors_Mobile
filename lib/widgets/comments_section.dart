// widgets/comments_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentsSection extends StatelessWidget {
  final String boardId;

  const CommentsSection({super.key, required this.boardId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('boards')
          .doc(boardId)
          .collection('comments')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("오류가 발생했습니다."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("댓글이 없습니다."));
        }

        final comments = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final authorId = comment['author_id'];
            final content = comment['content'];
            final createdAt = (comment['created_at'] as Timestamp?)?.toDate();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authorId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('로딩 중...'),
                  );
                }

                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(content),
                    subtitle: Text(
                      createdAt != null
                          ? DateFormat('yy.MM.dd HH:mm').format(createdAt)
                          : '알 수 없음',
                    ),
                  );
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;
                final profilePhotoUrl = userData?['profile_photo'] ?? '';
                final userNickname = userData?['user_nickname'] ?? '익명';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: profilePhotoUrl.isNotEmpty
                        ? NetworkImage(profilePhotoUrl)
                        : null,
                    child: profilePhotoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(content),
                  subtitle: Text(
                    "작성자: $userNickname · ${createdAt != null ? DateFormat('yy.MM.dd HH:mm').format(createdAt) : '알 수 없음'}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
