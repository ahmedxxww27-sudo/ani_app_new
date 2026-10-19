import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

initializeApp();
const db = getFirestore();

// Example trusted backend trigger: when a comment is created, notify the post owner.
// Deploy only after reviewing notification privacy and abuse/rate-limit requirements.
export const notifyPostOwnerOnComment = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;
    const postSnap = await db.doc(`posts/${event.params.postId}`).get();
    if (!postSnap.exists) return;
    const post = postSnap.data()!;
    const ownerUid = post.uid as string;
    if (!ownerUid || ownerUid === comment.uid) return;
    await db.collection("users").doc(ownerUid).collection("notifications").add({
      type: "comment",
      title: "تعليق جديد",
      body: `@${comment.username ?? "مستخدم"} علّق على منشورك`,
      postId: event.params.postId,
      actorUid: comment.uid,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
);
