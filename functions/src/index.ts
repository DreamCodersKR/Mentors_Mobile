import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const messaging = admin.messaging();

// 알림 전송 전에 설정 확인 함수 추가
async function checkNotificationSettings(
  userId: string,
  sendNotification: () => Promise<void>
) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();

  const notificationSettings = userDoc.data()?.notification_settings;

  // 알림 설정이 없다면 기본값으로 처리 (알림 허용)
  if (!notificationSettings) {
    await sendNotification();
    return;
  }

  // 알림 비활성화 체크
  if (!notificationSettings.isNotificationEnabled) {
    console.log("알림이 비활성화되었습니다.");
    return;
  }

  // 방해금지 시간 체크
  if (notificationSettings.isDoNotDisturbEnabled) {
    const now = new Date();
    // const currentHour = now.getHours();
    // const currentMinute = now.getMinutes();

    const startTime = new Date(now);
    const [startHour, startMinute] =
      notificationSettings.doNotDisturbStart.split(":");
    startTime.setHours(parseInt(startHour), parseInt(startMinute), 0);

    const endTime = new Date(now);
    const [endHour, endMinute] =
      notificationSettings.doNotDisturbEnd.split(":");
    endTime.setHours(parseInt(endHour), parseInt(endMinute), 0);

    // 방해금지 시간 로직 구현
    if (startTime <= endTime) {
      // 같은 날짜 내 방해금지 시간
      if (now >= startTime && now <= endTime) {
        console.log("방해금지 시간입니다.");
        return;
      }
    } else {
      // 다음 날 자정을 넘어가는 방해금지 시간
      if (now >= startTime || now <= endTime) {
        console.log("방해금지 시간입니다.");
        return;
      }
    }
  }

  // 모든 조건 통과 시 알림 전송
  await sendNotification();
}

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

      await checkNotificationSettings(boardOwnerId, async () => {
        for (const token of fcmTokens) {
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
        }
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

    if (!menteeId || !mentorId || !categoryId) {
      console.error("Invalid match data!");
      return;
    }

    try {
      const categoryDoc = await admin
        .firestore()
        .collection("categories")
        .doc(categoryId)
        .get();
      const categoryName =
        categoryDoc.data()?.cate_name || "알 수 없는 카테고리";

      await checkNotificationSettings(menteeId, async () => {
        await sendMatchSuccessNotification(
          menteeId,
          mentorId,
          categoryName,
          "멘토",
          "멘티"
        );
      });

      await checkNotificationSettings(mentorId, async () => {
        await sendMatchSuccessNotification(
          mentorId,
          menteeId,
          categoryName,
          "멘티",
          "멘토"
        );
      });

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

      if (!recipientTokens.length) {
        console.warn(`No FCM tokens found for recipientId: ${recipientId}`);
        return;
      }

      // 알림 전송 전에 방해 금지 설정 확인
      await checkNotificationSettings(recipientId, async () => {
        await sendChatMessageNotification(
          recipientTokens,
          senderNickname,
          messageContent,
          chatId
        );
      });

      console.log("채팅 메시지 알림 전송 완료!");
    } catch (error) {
      console.error("채팅 메시지 알림 전송 실패:", error);
    }
  }
);

// 매칭 성공 알림 헬퍼 함수
async function sendMatchSuccessNotification(
  userId: string,
  otherUserId: string,
  categoryName: string,
  otherUserRole: string,
  recipientRole: string
) {
  try {
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      console.error(`User document not found for userId: ${userId}`);
      return;
    }

    const fcmTokens = userDoc.data()?.fcm_tokens || [];

    if (!fcmTokens.length) {
      console.warn(`No FCM tokens found for userId: ${userId}`);
      return;
    }

    for (const token of fcmTokens) {
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
        console.error(`FCM 메시지 전송 실패 (토큰: ${token}):`, error);
      }
    }

    console.log(`매칭 성공 알림 전송 완료 (userId: ${userId})`);
  } catch (error) {
    console.error(
      `sendMatchSuccessNotification 실패 (userId: ${userId}):`,
      error
    );
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
