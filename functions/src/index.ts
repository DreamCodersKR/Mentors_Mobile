import {onDocumentCreated} from "firebase-functions/v2/firestore";
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

      console.log("알림 전송 성공!");
    } catch (error) {
      console.error("알림 전송 실패:", error);
    }
  }
);
