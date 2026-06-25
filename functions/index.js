const { defineSecret } = require("firebase-functions/params");
const axios = require("axios");

const {setGlobalOptions} = require("firebase-functions");
const {onRequest, onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const PLACES_API_KEY = defineSecret("PLACES_API_KEY");
const EMAIL_PASS = defineSecret("EMAIL_PASS");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

setGlobalOptions({ maxInstances: 10 });

exports.searchPlaces = onRequest(
  {
    secrets: [PLACES_API_KEY],
    cors: true,
    enforceAppCheck: true,
    region: "us-central1"
  },
  async (req, res) => {
    try {
      const appCheckToken = req.header('X-Firebase-AppCheck');

      if (!appCheckToken) {
        return res.status(401).json({ error: 'App Check token ausente' });
      }

      try {
        await admin.appCheck().verifyToken(appCheckToken);
      } catch (err) {
        console.error('Token App Check inválido:', err);
        return res.status(403).json({ error: 'Token App Check inválido' });
      }
      const { query } = req.body;

      if (!query) {
        return res.status(400).send({ error: "Missing query parameter" });
      }

      const fields =
        "places.id,places.displayName,places.formattedAddress,places.location," +
        "places.primaryType,places.types,places.photos,places.rating," +
        "places.reviews,places.reviewSummary,places.currentOpeningHours," +
        "places.internationalPhoneNumber,places.userRatingCount," +
        "places.websiteUri,nextPageToken";

      const body = {
        textQuery: query,
        includePureServiceAreaBusinesses: false,
        strictTypeFiltering: true,
        includedType: "restaurant",
        languageCode: "pt",
        regionCode: "br",
        locationRestriction: {
          rectangle: {
            low: { latitude: -16.150000, longitude: -48.300000 },
            high: { latitude: -15.450000, longitude: -47.350000 },
          },
        },
      };

      const response = await axios.post(
        "https://places.googleapis.com/v1/places:searchText",
        body,
        {
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": PLACES_API_KEY.value(),
            "X-Goog-FieldMask": fields,
          },
        }
      );

      res.status(200).send(response.data);
    } catch (error) {
      console.error("Error calling Places API:", error);
      res.status(500).send({ error: "Failed to fetch places" });
    }
  }
);

exports.getPhotoUrl = onRequest(
  {
    secrets: [PLACES_API_KEY],
    cors: true,
    enforceAppCheck: true,
    region: "us-central1",
  },
  async (req, res) => {
    try {
     const appCheckToken = req.header('X-Firebase-AppCheck');

     if (!appCheckToken) {
       return res.status(401).json({ error: 'App Check token ausente' });
     }

     try {
       await admin.appCheck().verifyToken(appCheckToken);
     } catch (err) {
       console.error('Token App Check inválido:', err);
       return res.status(403).json({ error: 'Token App Check inválido' });
     }

     const { photoName } = req.body;

     if (!photoName) {
       return res.status(400).send({ error: "Missing photoName" });
     }

     const url = `https://places.googleapis.com/v1/${photoName}/media`;

      const response = await axios.get(url, {
        params: {
          maxWidthPx: 1000,
          maxHeightPx: 1000,
          skipHttpRedirect: true,
          key: PLACES_API_KEY.value(),
        },
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (response.status === 200) {
        const photoUri = response.data.photoUri;
        return res.status(200).send({ photoUri });
      }

      return res.status(response.status).send({ error: "Failed to get photo" });
    } catch (error) {
      console.error("Error fetching photo:", error.response?.data || error);
      res.status(500).send({ error: "Failed to fetch photo" });
    }
  }
);

const nodemailer = require("nodemailer");

exports.sendRestaurantSuggestion = onCall(
  { secrets: [EMAIL_PASS] },
  async (data, context) => {
    const { name, location, userId } = data.data;

    if (!name || !location) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Nome e local são obrigatórios`
      );
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "mathewdourado@gmail.com",
        pass: EMAIL_PASS.value(),
      },
    });

    const mailOptions = {
      from: "mathewdourado@gmail.com",
      to: "mathewdourado@gmail.com",
      subject: "Nova sugestão de restaurante",
      text: `Nome: ${name}\nLocal: ${location}\nUserId: ${userId}`,
    };

    try {
      await transporter.sendMail(mailOptions);
      return { message: "Sugestão enviada com sucesso!" };
    } catch (error) {
      console.error("Erro ao enviar email:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Erro ao enviar email"
      );
    }
  }
);

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { title, body, type, route, arguments, image, userIds } = data.data;

  if (!title || !body || !type) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Campos obrigatórios: title, body e type. ${data}`
    );
  }

  const createdAt = admin.firestore.FieldValue.serverTimestamp();
  const read = false;

  // 🔹 GRUPO
  if (type === "group") {
    if (!Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userIds (array) é obrigatório para notificações de grupo."
      );
    }

    const tokens = [];
    const batch = db.batch();

    for (const uid of userIds) {
      const userRef = db.collection("users").doc(uid);
      const notifRef = userRef.collection("notifications").doc();

      // 🔸 Se o route for '/reward', ajusta o arguments
      let adjustedArguments = arguments;
      if (route === "/reward") {
        adjustedArguments = {
          id: notifRef.id ?? "",
          points: arguments ?? 0,
          route: route,
        };
      }

      batch.set(notifRef, {
        title,
        body,
        type,
        route,
        createdAt,
        image,
        arguments: adjustedArguments,
        read,
      });

      const userDoc = await userRef.get();
      const token = userDoc.get("fcmToken");
      if (token) tokens.push({ token, notifId: notifRef.id });
    }

    await batch.commit();

    if (tokens.length > 0) {
      const chunkSize = 500;
      for (let i = 0; i < tokens.length; i += chunkSize) {
        const chunk = tokens.slice(i, i + chunkSize);

        await messaging.sendEachForMulticast({
          tokens: chunk.map((c) => c.token),
          notification: { title, body },
          data: {
            type: "group",
            route: route,
            arguments: JSON.stringify(
              route === "/reward"
                ? { id: tokens[i].notifId ?? "", points: arguments ?? 0, route: route }
                : arguments
            ),
            image: image,
          },
        });
      }
    }

    return { success: true, sentTo: userIds, total: userIds.length };
  }

  // 🔹 GLOBAL
  if (type === "global") {
    const ref = await db.collection("notifications").add({
      title,
      body,
      type,
      route,
      image,
      createdAt,
    });

    const usersSnap = await db.collection("users").get();
    const tokens = usersSnap.docs
      .map((doc) => doc.get("fcmToken"))
      .filter(Boolean);
      console.log('TOKENS ', tokens);

    if (tokens.length > 0) {
      const chunkSize = 500;
      const sendTasks = [];
      for (let i = 0; i < tokens.length; i += chunkSize) {
        const chunk = tokens.slice(i, i + chunkSize);
        sendTasks.push(
          messaging.sendEachForMulticast({
            tokens: chunk,
            notification: { title, body },
            data: {
              id: ref.id,
              type: "global",
              route: route ?? '',
              arguments: arguments,
              image: image,
            },
          }).then(response => {
            response.responses.forEach((res, idx) => {
              if (!res.success) console.error('Erro token', chunk[idx], res.error);
            });
          })
        );
        console.log('Mensagem enviada para o usuario', chunk);
      }
    }

    return { success: true, sentTo: "all", total: tokens.length, id: ref.id };
  }

  throw new functions.https.HttpsError(
    "invalid-argument",
    "Tipo de notificação inválido. Use: group ou global."
  );
});

exports.notifyNewFollower = functions.https.onCall(async (data, context) => {
  const { targetUserId, username, userId } = data.data;

  if (!targetUserId || !username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Os campos targetUserId e username são obrigatórios."
    );
  }

  try {
    const userDoc = await db.collection("users").doc(targetUserId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Usuário não encontrado.");
    }

    const token = userDoc.data().fcmToken;

    const title = "Novo seguidor! 👥";
    const body = `O usuário ${username} começou a seguir você.`;
    const route = '/splash';
    const arguments = `{"route": "/profile", "userId": ${userId}}`;
    const image = "https://firebasestorage.googleapis.com/v0/b/foodfinderapp-b2c0d.firebasestorage.app/o/notifications%2Fcommon%2Fpngwing.com-3.png?alt=media&token=c0a5dd1c-c20a-4c27-b4d6-62fb11291502";

    const batch = db.batch();
    const createdAt = admin.firestore.FieldValue.serverTimestamp();
    const read = false;
    const userRef = db.collection("users").doc(targetUserId);
    const notifRef = userRef.collection("notifications").doc();
    batch.set(notifRef, { title, body, route, createdAt, image, read });

    await batch.commit();

    if (!token) {
      console.log(`Usuário ${targetUserId} não possui token FCM.`);
      return { success: false };
    }

    const message = {
      notification: {
        title: "Novo seguidor! 👥",
        body: body,
      },
      data: {
        route: route,
        image: image,
      },
      token: token,
    };

    await admin.messaging().send(message);
    console.log(`Notificação enviada para ${targetUserId}`);

    return { success: true };
  } catch (error) {
    console.error("Erro ao enviar notificação de novo seguidor:", error);
    throw new functions.https.HttpsError("internal", "Erro ao enviar notificação.");
  }
});

exports.notifyTaggedPeople = functions.https.onCall(async (data, context) => {
  const { targetIds, postId, username } = data.data;

  if (!targetIds || !Array.isArray(targetIds) || targetIds.length === 0 || !postId || !username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Os campos targetIds (array), postId e username são obrigatórios."
    );
  }

  const title = "Você foi marcado em um post 📌";
  const body = `${username} marcou você em um post.`;
  const route = `/post/${postId}`;
  const image =
    "https://firebasestorage.googleapis.com/v0/b/foodfinderapp-b2c0d.firebasestorage.app/o/notifications%2Fcommon%2FNicePng_location-pin-icon-png_1307677.png?alt=media&token=7b883714-0a7b-4fc4-b4a5-1fd922e9b638";

  const tokens = [];
  const userRefs = [];

  for (const uid of targetIds) {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) continue;

    const token = userDoc.data().fcmToken;
    if (token) {
      tokens.push({ token, uid });
      userRefs.push(userRef);
    }
  }

  if (tokens.length === 0) {
    console.log("Nenhum dos usuários marcados possui token FCM válido.");
    return { success: false };
  }

  const batch = db.batch();
  const createdAt = admin.firestore.FieldValue.serverTimestamp();
  const read = false;

  for (const ref of userRefs) {
    const notifRef = ref.collection("notifications").doc();
    batch.set(notifRef, { title, body, route, createdAt, image, read });
  }
  await batch.commit();

  const multicastMessage = {
    notification: { title, body },
    data: { route, image },
    tokens: tokens.map(t => t.token),
  };

  const response = await admin.messaging().sendEachForMulticast(multicastMessage);

  for (let i = 0; i < response.responses.length; i++) {
    const resp = response.responses[i];
    const { token, uid } = tokens[i];

    if (!resp.success) {
      const errorCode = resp.error.code;
      console.error(`Erro ao enviar para token ${token}:`, errorCode);

      if (
        errorCode === "messaging/invalid-registration-token" ||
        errorCode === "messaging/registration-token-not-registered"
      ) {
        await db.collection("users").doc(uid).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
        console.log(`🧹 Token inválido removido do usuário ${uid}`);
      }
    }
  }

  console.log(`✅ Notificação enviada para ${tokens.length} usuários marcados`);
  return { success: true, sent: tokens.length };
});


/**
 * Função para notificar um usuário que teve um post curtido
 * data: { targetUserId: string, username: string }
 */
exports.notifyPostLiked = functions.https.onCall(async (data, context) => {
  const { targetUserId, username, postId } = data.data;

  if (!targetUserId || !username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Os campos targetUserId e username são obrigatórios."
    );
  }

  try {
    const userDoc = await db.collection("users").doc(targetUserId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Usuário não encontrado.");
    }

    const token = userDoc.data().fcmToken;

    const title = "Nova curtida! ❤️";
    const body = `O usuário ${username} curtiu seu post.`;
    const route = `/post/${postId}`;
    const image = "https://firebasestorage.googleapis.com/v0/b/foodfinderapp-b2c0d.firebasestorage.app/o/notifications%2Fcommon%2FHeart%20Icon%20-%20480x480.png?alt=media&token=78226e29-6ed1-40cf-93d0-d14551cdff20";

    const batch = db.batch();
    const createdAt = admin.firestore.FieldValue.serverTimestamp();
    const read = false;
    const userRef = db.collection("users").doc(targetUserId);
    const notifRef = userRef.collection("notifications").doc();
    batch.set(notifRef, { title, body, route, createdAt, image, read });

    await batch.commit();

    if (!token) {
      console.log(`Usuário ${targetUserId} não possui token FCM.`);
      return { success: false };
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        route: route,
        image: image,
      },
      token: token,
    };

    try {
      await admin.messaging().send(message);
      console.log(`Notificação de curtida enviada para ${targetUserId}`);
      return { success: true };
    } catch (error) {
      console.error(`❌ Erro ao enviar notificação para token ${token}:`, error.code);

      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        await userRef.update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
        console.log(`🧹 Token inválido removido do usuário ${targetUserId}`);
      }

      return { success: false };
    }
  } catch (error) {
    console.error("Erro ao enviar notificação de curtida:", error);
    throw new functions.https.HttpsError("internal", "Erro ao enviar notificação.");
  }
});

exports.notifyNewComment = functions.https.onCall(async (data, context) => {
  const { targetUserId, postId, username, commentText } = data.data;

  if (!targetUserId || !postId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Os campos targetUserId e postId são obrigatórios."
    );
  }

  try {
    const userDoc = await db.collection("users").doc(targetUserId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Usuário não encontrado.");
    }

    const token = userDoc.data().fcmToken;

    const title = `${username} comentou em um post seu.`;
    const body = `${commentText}`;
    const route = `/post/${postId}`;
    const image = "https://firebasestorage.googleapis.com/v0/b/foodfinderapp-b2c0d.firebasestorage.app/o/notifications%2Fcommon%2Fpngfind.com-comment-png-657175.png?alt=media&token=01caffd0-d091-4ca9-b9ea-c6859dffac0e";

    const batch = db.batch();
    const createdAt = admin.firestore.FieldValue.serverTimestamp();
    const read = false;
    const userRef = db.collection("users").doc(targetUserId);
    const notifRef = userRef.collection("notifications").doc();
    batch.set(notifRef, { title, body, route, createdAt, image, read });

    await batch.commit();

    if (!token) {
      console.log(`Usuário ${targetUserId} não possui token FCM.`);
      return { success: false };
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        route: route,
        image: image,
      },
      token: token,
    };

    try {
      await admin.messaging().send(message);
      console.log(`✅ Notificação de comentário enviada para ${targetUserId}`);
      return { success: true };
    } catch (error) {
      console.error(`❌ Erro ao enviar notificação para token ${token}:`, error.code);

      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        await userRef.update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
        console.log(`🧹 Token inválido removido do usuário ${targetUserId}`);
      }

      return { success: false };
    }
  } catch (error) {
    console.error("Erro ao enviar notificação de comentário:", error);
    throw new functions.https.HttpsError("internal", "Erro ao enviar notificação.");
  }
});

exports.notifyCommentReply = functions.https.onCall(async (data, context) => {
  const { postId, postOwnerId, commentId, replyAuthorId, replyAuthorName } = data.data;
  if (!postId || !postOwnerId || !commentId || !replyAuthorId || !replyAuthorName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Campos obrigatórios: postId, commentId, replyAuthorId, replyAuthorName."
    );
  }

  const createdAt = admin.firestore.FieldValue.serverTimestamp();
  const read = false;
  const image = "https://firebasestorage.googleapis.com/v0/b/foodfinderapp-b2c0d.firebasestorage.app/o/notifications%2Fcommon%2Fpngfind.com-comment-png-657175.png?alt=media&token=01caffd0-d091-4ca9-b9ea-c6859dffac0e";

  try {
    // 🔹 Busca o comentário original
    const commentDoc = await db.collection("posts").doc(postId).collection("comments").doc(commentId).get();
    if (!commentDoc.exists) throw new functions.https.HttpsError("not-found", "Comentário não encontrado.");
    const commentOwnerId = commentDoc.data().authorId;

    // 🔹 Busca todas as respostas do comentário
    const repliesSnap = await db
      .collection("posts")
      .doc(postId)
      .collection("comments")
      .doc(commentId)
      .collection("answers")
      .get();

    const repliedUserIds = repliesSnap.docs
      .map((d) => d.data().authorId)
      .filter((uid) => uid !== replyAuthorId && uid !== commentOwnerId && uid !== postOwnerId);

    const notifiedUsers = new Set();

    // 🔸 Função auxiliar para enviar e registrar notificação
    const sendNotificationToUser = async (uid, title, body, route) => {
      const userRef = db.collection("users").doc(uid);
      const userDoc = await userRef.get();
      if (!userDoc.exists) return;

      const token = userDoc.data().fcmToken;
      if (!token) return;

      const notifRef = userRef.collection("notifications").doc();
      await notifRef.set({ title, body, route, image, createdAt, read });

      try {
        await admin.messaging().send({
          token,
          notification: { title, body },
          data: { route, image },
        });
      } catch (error) {
        console.error(`Erro ao enviar para ${uid}:`, error.code);
        if (
          error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered"
        ) {
          await userRef.update({ fcmToken: admin.firestore.FieldValue.delete() });
        }
      }

      notifiedUsers.add(uid);
    };

    const route = `/post/${postId}`;

    // 🔹 1. Notifica o dono do post (se não for ele mesmo)
    if (postOwnerId !== replyAuthorId) {
      await sendNotificationToUser(
        postOwnerId,
        "Novo comentário no seu post 💬",
        `${replyAuthorName} comentou no seu post.`,
        route
      );
    }

    // 🔹 2. Notifica o dono do comentário (se diferente)
    if (commentOwnerId !== replyAuthorId && commentOwnerId !== postOwnerId) {
      await sendNotificationToUser(
        commentOwnerId,
        "Nova resposta no seu comentário 💭",
        `${replyAuthorName} respondeu o seu comentário.`,
        route
      );
    }

    // 🔹 3. Notifica outros participantes da thread
    for (const uid of repliedUserIds) {
      if (!notifiedUsers.has(uid)) {
        await sendNotificationToUser(
          uid,
          "Nova resposta em um comentário que você participou 🔔",
          `${replyAuthorName} também respondeu ao comentário.`,
          route
        );
      }
    }

    return { success: true, notified: Array.from(notifiedUsers) };
  } catch (error) {
    console.error("Erro em notifyCommentReply:", error);
    throw new functions.https.HttpsError("internal", "Falha ao enviar notificações de resposta.");
  }
});

exports.sendUserStatusNotification = onCall( async (request) => {
  const { userId, type, newValue } = request.data;
  const caller = request.auth?.uid;

  if (!caller) throw new HttpsError("unauthenticated", "Usuário não autenticado.");
  if (!userId || !type)
    throw new HttpsError("invalid-argument", "Parâmetros inválidos.");

  // 🔹 Busca dados do usuário alvo
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  if (!userDoc.exists)
    throw new HttpsError("not-found", "Usuário não encontrado.");

  const user = userDoc.data();
  const token = user?.fcmToken;
  const createdAt = admin.firestore.FieldValue.serverTimestamp();

  let title, body, image, route, arguments;

  // 🔸 Admin
  if (type === "admin") {
    image =
      "https://firebasestorage.googleapis.com/v0/b/foodfinderapp-b2c0d.firebasestorage.app/o/notifications%2Fcommon%2Fadmin.png?alt=media&token=79b8b126-9f8b-4091-9ef5-6b6466b88ae4";

    if (newValue) {
      title = "🎉 Novo privilégio!";
      body = "Você agora é administrador do BSB Eats!";
    } else {
      title = "⚠️ Permissão removida";
      body = "Suas permissões de administrador foram revogadas.";
    }

    route = "/splash";
    arguments = '{"route": "/admin"}';
  }

  // 🔸 Verificado
  else if (type === "verified") {
    image =
      "https://firebasestorage.googleapis.com/v0/b/foodfinderapp-b2c0d.firebasestorage.app/o/notifications%2Fcommon%2Fverified.png?alt=media&token=e2e212cc-42a0-45fd-8292-b5086916d594";

    if (newValue) {
      title = "✅ Conta verificada!";
      body = "Parabéns! Sua conta agora possui um selo de verificação.";
    } else {
      title = "⚠️ Verificação removida";
      body = "Sua verificação foi removida.";
    }

    route = "/splash";
    arguments = '{"route": "/user_profile"}';
  } else {
    throw new HttpsError("invalid-argument", "Tipo de notificação inválido.");
  }

  // 🔹 Cria notificação no Firestore
  const notifRef = userRef.collection("notifications").doc();
  await notifRef.set({
    title,
    body,
    image,
    route,
    read: false,
    type: 'user',
    arguments,
    createdAt,
  });

  console.log(`📩 Notificação salva em /users/${userId}/notifications/${notifRef.id}`);

  // 🔹 Envia notificação push via FCM
  if (token) {
    try {
      await messaging.send({
        token,
        notification: { title, body, image },
        data: { route, image, arguments },
      });
      console.log(`✅ Push FCM enviado para ${userId}`);
    } catch (err) {
      console.error("❌ Erro ao enviar push:", err);
    }
  } else {
    console.log(`ℹ️ Usuário ${userId} sem token FCM.`);
  }

  return { success: true };
});

exports.onReviewCreated = onDocumentCreated("restaurantes/{restaurantId}/reviews/{reviewId}", async (event) => {
    const snap = event.data;
    const newReview = snap.data();
    const atmosphere = newReview.atmosphere || 0;
    const food = newReview.food || 0;
    const service = newReview.service || 0;
    const price = newReview.price || 0;
    const newRating = ((atmosphere + food + service + price) / 4) || 0;

    const restaurantId = event.params.restaurantId;

    const restaurantRef = admin.firestore().collection("restaurantes").doc(restaurantId);

    await admin.firestore().runTransaction(async (transaction) => {
      const restaurantSnap = await transaction.get(restaurantRef);
      const restaurantData = restaurantSnap.data() || {};

      const oldTotal = restaurantData.userRatingCount || 0;
      const oldMedia = restaurantData.rating || 0;

      // Calcula a nova média sem precisar das notas antigas
      const novaMedia = ((oldMedia * oldTotal) + newRating) / (oldTotal + 1);

      transaction.update(restaurantRef, {
        rating: novaMedia,
        userRatingCount: admin.firestore.FieldValue.increment(1),
      });
    });
});