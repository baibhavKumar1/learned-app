const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

exports.getUserProfile = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }
  try {
    const uid = request.auth.uid;
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (!userDoc.exists) {
      return { exists: false };
    }
    return { exists: true, ...userDoc.data() };
  } catch (error) {
    console.error("Error fetching user profile:", error);
    throw new HttpsError("internal", "Unable to fetch user profile.");
  }
});

exports.updateUserProfile = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }
  try {
    const uid = request.auth.uid;
    const updates = {};
    if (request.data.name !== undefined) updates.name = request.data.name;
    if (request.data.email !== undefined) updates.email = request.data.email;
    if (request.data.role !== undefined) updates.role = request.data.role;
    if (request.data.provider !== undefined) updates.provider = request.data.provider;
    if (request.data.linkedProviders !== undefined) {
      updates.linkedProviders = request.data.linkedProviders;
    }
    if (request.data.onboardingComplete !== undefined) {
      updates.onboardingComplete = request.data.onboardingComplete;
    }

    const userRef = admin.firestore().collection("users").doc(uid);
    await userRef.set(updates, { merge: true });
    return { success: true };
  } catch (error) {
    console.error("Error updating user profile:", error);
    throw new HttpsError("internal", "Unable to update user profile.");
  }
});
