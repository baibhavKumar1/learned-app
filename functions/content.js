const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

exports.generateSignedUrl = onCall(async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to upload files."
    );
  }

  const fileName = request.data.fileName;
  const contentType = request.data.contentType;

  if (!fileName || !contentType) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with a 'fileName' and 'contentType'."
    );
  }

  const uid = request.auth.uid;
  const filePath = `uploads/${uid}/${Date.now()}_${fileName}`;

  try {
    const bucket = admin.storage().bucket();
    const file = bucket.file(filePath);

    const [url] = await file.getSignedUrl({
      version: "v4",
      action: "read",
      expires: Date.now() + 60 * 60 * 1000, // 1 hour
    });

    return {
      signedUrl: url,
      storagePath: filePath,
    };
  } catch (error) {
    console.error("Error generating signed URL:", error);
    throw new HttpsError("internal", "Unable to generate signed URL.");
  }
});

exports.getSubjectsAndMaterials = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }
  try {
    const snapshot = await admin.firestore().collection("course_materials").get();
    const materials = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.createdAt && data.createdAt.toDate) {
        data.createdAt = data.createdAt.toDate().toISOString();
      }
      materials.push({ id: doc.id, ...data });
    });
    return { success: true, materials };
  } catch (error) {
    console.error("Error fetching materials:", error);
    throw new HttpsError("internal", "Unable to fetch course materials.");
  }
});
