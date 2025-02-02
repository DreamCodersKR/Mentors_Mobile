import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String userName;

  const ChatRoomScreen(
      {super.key, required this.chatRoomId, required this.userName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _chatService.sendMessage(
          chatId: widget.chatRoomId, content: message);

      _messageController.clear();

      // 메시지 전송 후 스크롤 최하단으로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('a h:mm', Intl.defaultLocale).format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getChatMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('메시지가 없습니다.'));
                }

                // Firestore가 최신 메시지부터 반환하는 경우, reverse하여 오래된 메시지가 위로 오도록 함.
                final messages = snapshot.data!.docs.reversed.toList();
                final currentUser = FirebaseAuth.instance.currentUser;

                // 스냅샷이 갱신될 때마다 자동 스크롤
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageData = message.data() as Map<String, dynamic>;

                    final isMine = messageData['sender_id'] == currentUser?.uid;
                    final text = messageData['content'] ?? '';
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    final time = _formatTimestamp(timestamp);

                    return Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: isMine
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMine)
                              const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                            if (!isMine) const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.6,
                                ),
                                padding: const EdgeInsets.all(10.0),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? Colors.yellow[200]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(10),
                                    topRight: const Radius.circular(10),
                                    bottomLeft: isMine
                                        ? const Radius.circular(10)
                                        : Radius.zero,
                                    bottomRight: isMine
                                        ? Radius.zero
                                        : const Radius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  text,
                                  textAlign:
                                      isMine ? TextAlign.right : TextAlign.left,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 50.0, // 상대방 아바타를 피하기 위해
                            right: 8.0,
                            top: 4.0,
                          ),
                          child: Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Text(
                              time,
                              style: const TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // 추가 기능 버튼
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "메시지 보내기",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
