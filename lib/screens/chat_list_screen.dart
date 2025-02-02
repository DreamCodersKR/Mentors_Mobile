import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentors_app/screens/chat_room_screen.dart';
import 'package:mentors_app/services/chat_service.dart';
import 'package:mentors_app/widgets/bottom_nav_bar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  String _selectedFilter = '전체';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: const Text(
          '채팅방',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 필터 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton('전체'),
                _buildFilterButton('멘토'),
                _buildFilterButton('멘티'),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getUserChatRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('채팅방이 없습니다.'));
                  }

                  final chatRooms = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: chatRooms.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final chatRoom = chatRooms[index];
                      return _buildChatRoomListTile(chatRoom);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/main', (route) => false);
          }
          if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/board', (route) => false);
          }
          if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/myInfo', (route) => false);
          }
        },
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedFilter == filter
            ? const Color(0xFFE2D4FF)
            : Colors.grey[200],
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(filter),
    );
  }

  Widget _buildChatRoomListTile(QueryDocumentSnapshot chatRoom) {
    final chatRoomData = chatRoom.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;

    // 현재 사용자가 아닌 상대방 ID 찾기
    final otherUserId = chatRoomData['mentor_id'] == currentUser?.uid
        ? chatRoomData['mentee_id']
        : chatRoomData['mentor_id'];

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const ListTile(title: Text('로딩 중...'));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userNickname = userData['user_nickname'] ?? '알 수 없음';
        final profilePhoto = userData['profile_photo'];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey,
            backgroundImage:
                profilePhoto != null ? NetworkImage(profilePhoto) : null,
            child: profilePhoto == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(
            userNickname,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            chatRoomData['last_message'] ?? '메시지 없음',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(
                  chatRoomId: chatRoom.id,
                  userName: userNickname,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
