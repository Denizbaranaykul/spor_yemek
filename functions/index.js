const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNoteReminders = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async (context) => {
    const now = new Date();
    const db = admin.firestore();

    try {
      // Create strings for comparison
      // Firestore string format varies, so we check using simple string comparison
      // or check if it's a timestamp object and parse it inside rules. 
      // It's safer to fetch the upcoming notes and filter them in memory if formats vary.
      const nowIso = now.toISOString();

      // Use collectionGroup because notes are saved under users/{userId}/notes
      const notesRef = db.collectionGroup("notes");
      const snapshot = await notesRef
        .where("isSent", "==", false)
        .get();

      if (snapshot.empty) {
        console.log("No pending notifications.");
        return null;
      }

      // Filter in memory to handle different date formats safely
      const validDocs = snapshot.docs.filter(doc => {
        const data = doc.data();
        if (!data.reminder_time) return false;

        // Convert the stored string back into a JS Date to compare mathematically
        // This avoids alphabetical sorting issues if Flutter sent Local instead of UTC (Missing 'Z')
        const reminderDate = new Date(data.reminder_time);

        // Compare numeric timestamps
        const isPastOrNow = reminderDate.getTime() <= now.getTime();

        return isPastOrNow;
      });

      if (validDocs.length === 0) {
        console.log("No notes due at this time.");
        return null;
      }

      console.log(`Found ${validDocs.length} pending notes. Sending...`);

      const batch = db.batch();
      const promises = [];

      for (const doc of validDocs) {
        const note = doc.data();

        // Since we are using collectionGroup, we can extract the userId from the doc reference path.
        // The path is typically: users/{userId}/notes/{noteId}
        let userId = note.userId;
        if (!userId) {
          // Fallback to extracting from the path
          const pathSegments = doc.ref.path.split('/');
          if (pathSegments.length >= 4 && pathSegments[0] === 'users') {
            userId = pathSegments[1];
          }
        }

        if (!userId) {
          console.log(`Skipping note ${doc.id} - No userId attached or found in path. Document path: ${doc.ref.path}`);
          continue;
        }

        // Fetch user's FCM token
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
          console.log(`Skipping note ${doc.id} - User ${userId} not found`);
          continue;
        }

        const userData = userDoc.data();
        const token = userData.fcmToken;

        if (!token) {
          console.log(`Skipping note ${doc.id} - User ${userId} has no FCM token`);
          continue;
        }

        const payload = {
          notification: {
            title: "Hatırlatıcı \u23f0",
            body: note.text || "Yeni bir hatırlatıcınız var!",
          },
          token: token,
        };

        const pushPromise = admin.messaging().send(payload)
          .then((response) => {
            console.log(`Successfully sent message to ${userId}:`, response);
            // Persistent loop: We no longer mark isSent: true here. 
            // The user must mark it done in the Flutter App.
          })
          .catch((error) => {
            console.error(`Error sending message to ${userId}:`, error);
          });

        promises.push(pushPromise);
      }

      await Promise.all(promises);
      await batch.commit();

      console.log("Finished processing pending notifications.");
      return null;
    } catch (error) {
      console.error("Error in scheduled function:", error);
      return null;
    }
  });
