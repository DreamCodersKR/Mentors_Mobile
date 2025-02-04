import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const messaging = admin.messaging();

export const sendNotificationOnComment = onDocumentCreated(
  "boards/{board_id}/comments/{comment_id}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.error("No comment data found!");
      return;
    }

    const commentData = snapshot.data();
    const boardId = event.params.board_id;
    const authorId = commentData?.author_id;
    const commentText = commentData?.content;

    if (!boardId || !authorId || !commentText) {
      console.error("Invalid comment data!");
      return;
    }

    try {
      const boardDoc = await admin
        .firestore()
        .collection("boards")
        .doc(boardId)
        .get();

      if (!boardDoc.exists) {
        console.error("Board not found!");
        return;
      }

      const boardOwnerId = boardDoc.data()?.author_id;

      if (!boardOwnerId) {
        console.error("Board owner ID not found!");
        return;
      }

      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(boardOwnerId)
        .get();

      const fcmTokens = userDoc.data()?.fcm_tokens;

      if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
        console.error("No FCM tokens found for board owner!");
        return;
      }

      const validTokens: string[] = [];
      for (const token of fcmTokens) {
        try {
          await messaging.send({
            notification: {
              title: "새로운 댓글이 달렸습니다!",
              body: commentText,
            },
            data: {
              action: JSON.stringify({
                screen: "BoardDetailScreen",
                params: {
                  board_id: boardId,
                  title: boardDoc.data()?.title || "제목 없음",
                  author_uid: boardDoc.data()?.author_id || "작성자 없음",
                },
              }),
            },
            token,
          });
          validTokens.push(token);
        } catch (error: unknown) {
          console.error(`FCM 전송 실패 (토큰: ${token}):`, error);

          if (
            (typeof error === "object" &&
              error !== null &&
              "code" in error &&
              (error as { code: string }).code ===
                "messaging/registration-token-not-registered") ||
            (error as { code: string }).code === "messaging/invalid-argument"
          ) {
            console.warn(`유효하지 않은 토큰: ${token}`);
          }
        }
      }

      await admin.firestore().collection("users").doc(boardOwnerId).update({
        fcm_tokens: validTokens,
      });

      console.log("Firestore temp_navigation 데이터 추가");
      await admin
        .firestore()
        .collection("temp_navigation")
        .doc("pending_navigation")
        .set({
          screen: "BoardDetailScreen",
          params: {
            board_id: boardId,
            title: boardDoc.data()?.title || "제목 없음",
            author_uid: boardDoc.data()?.author_id || "작성자 없음",
          },
          processed: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log("알림 전송 성공!");
    } catch (error) {
      console.error("알림 전송 실패:", error);
    }
  }
);

/**
 * 매칭 성공 시 알림을 전송하는 함수
 */
export const sendNotificationOnMatchSuccess = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.error("No match data found!");
      return;
    }

    const matchData = snapshot.data();
    const menteeId = matchData?.mentee_id;
    const mentorId = matchData?.mentor_id;
    const categoryId = matchData?.category_id;

    if (!menteeId || !mentorId) {
      console.error("Invalid match data!");
      return;
    }

    try {
      // 멘티와 멘토의 사용자 정보 조회
      const menteeDoc = await admin
        .firestore()
        .collection("users")
        .doc(menteeId)
        .get();
      const mentorDoc = await admin
        .firestore()
        .collection("users")
        .doc(mentorId)
        .get();

      // 카테고리 정보 조회
      const categoryDoc = await admin
        .firestore()
        .collection("categories")
        .doc(categoryId)
        .get();
      const categoryName =
        categoryDoc.data()?.cate_name || "알 수 없는 카테고리";

      const menteeTokens = menteeDoc.data()?.fcm_tokens || [];
      const mentorTokens = mentorDoc.data()?.fcm_tokens || [];

      // 멘티에게 보내는 알림
      await sendMatchSuccessNotification(
        menteeTokens,
        mentorId,
        categoryName,
        "mentor",
        "mentee"
      );

      // 멘토에게 보내는 알림
      await sendMatchSuccessNotification(
        mentorTokens,
        menteeId,
        categoryName,
        "mentee",
        "mentor"
      );

      console.log("매칭 성공 알림 전송 완료!");
    } catch (error) {
      console.error("매칭 성공 알림 전송 실패:", error);
    }
  }
);

// 채팅 메시지 알림 함수
export const sendNotificationOnChatMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.error("No message data found!");
      return;
    }

    const messageData = snapshot.data();
    const senderId = messageData?.sender_id;
    const messageContent = messageData?.content;
    const chatId = event.params.chatId;

    if (!senderId || !messageContent) {
      console.error("Invalid message data!");
      return;
    }

    try {
      // 채팅방 정보 조회
      const chatDoc = await admin
        .firestore()
        .collection("chats")
        .doc(chatId)
        .get();
      const participants = chatDoc.data()?.participants || [];
      const recipientId = participants.find((id: string) => id !== senderId);

      if (!recipientId) {
        console.error("Recipients not found!");
        return;
      }

      // 발신자 정보 조회
      const senderDoc = await admin
        .firestore()
        .collection("users")
        .doc(senderId)
        .get();
      const senderNickname = senderDoc.data()?.user_nickname || "익명";

      // 수신자 토큰 조회
      const recipientDoc = await admin
        .firestore()
        .collection("users")
        .doc(recipientId)
        .get();
      const recipientTokens = recipientDoc.data()?.fcm_tokens || [];

      // 수신자에게 알림 전송
      await sendChatMessageNotification(
        recipientTokens,
        senderNickname,
        messageContent,
        chatId
      );

      console.log("채팅 메시지 알림 전송 완료!");
    } catch (error) {
      console.error("채팅 메시지 알림 전송 실패:", error);
    }
  }
);

// 매칭 성공 알림 헬퍼 함수
async function sendMatchSuccessNotification(
  tokens: string[],
  otherUserId: string,
  categoryName: string,
  otherUserRole: string,
  recipientRole: string
) {
  for (const token of tokens) {
    try {
      await messaging.send({
        notification: {
          title: "멘토링 매칭 성공!",
          body: `${categoryName} 카테고리에서 ${otherUserRole} 매칭되었습니다.`,
        },
        data: {
          action: JSON.stringify({
            screen: "MatchDetailScreen",
            params: {
              user_id: otherUserId,
              category_name: categoryName,
              role: recipientRole,
            },
          }),
        },
        token,
      });
    } catch (error) {
      console.error(`매칭 성공 알림 전송 실패 (토큰: ${token}):`, error);
    }
  }
}

// 채팅 메시지 알림 헬퍼 함수
async function sendChatMessageNotification(
  tokens: string[],
  senderNickname: string,
  messageContent: string,
  chatId: string
) {
  for (const token of tokens) {
    try {
      await messaging.send({
        notification: {
          title: `${senderNickname}님의 메시지`,
          body: messageContent,
        },
        data: {
          action: JSON.stringify({
            screen: "ChatRoomScreen",
            params: {
              chat_room_id: chatId,
            },
          }),
        },
        token,
      });
    } catch (error) {
      console.error(`채팅 메시지 알림 전송 실패 (토큰: ${token}):`, error);
    }
  }
}
