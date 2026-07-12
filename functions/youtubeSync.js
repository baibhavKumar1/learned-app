const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getStorage } = require("firebase-admin/storage");
const { getFirestore } = require("firebase-admin/firestore");
const youtubedl = require("youtube-dl-exec");
const fs = require("fs");
const path = require("path");
const os = require("os");

exports.syncYouTubeVideo = onCall(
  {
    timeoutSeconds: 540, // Allow up to 9 minutes for downloading
    memory: "1GiB",
  },
  async (request) => {
    const { videoId, title, url } = request.data;
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in to sync videos.");
    }
    if (!videoId || !url) {
      throw new HttpsError("invalid-argument", "Missing video ID or URL.");
    }

    const tempFilePath = path.join(os.tmpdir(), `${videoId}.mp4`);

    try {
      console.log(`Starting yt-dlp download for ${url}`);
      // 1. Download video using yt-dlp via youtube-dl-exec
      await youtubedl(url, {
        output: tempFilePath,
        format: 'best[ext=mp4]', // Force mp4 for broad compatibility
      });
      console.log(`Download complete: ${tempFilePath}`);

      // 2. Upload to Google Cloud Storage
      const bucket = getStorage().bucket();
      const destinationPath = `course_materials/${uid}/youtube_syncs/${videoId}.mp4`;
      
      console.log(`Uploading to bucket path: ${destinationPath}`);
      await bucket.upload(tempFilePath, {
        destination: destinationPath,
        contentType: 'video/mp4',
      });

      // (Optional) Make file public if your security rules allow it
      const file = bucket.file(destinationPath);
      await file.makePublic();
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${destinationPath}`;
      
      console.log(`Upload complete. Public URL: ${publicUrl}`);

      // 3. Save reference to Firestore
      const db = getFirestore();
      const docData = {
        teacherId: uid,
        title: title || 'Synced YouTube Video',
        videoUrl: publicUrl,
        source: 'youtube',
        originalVideoId: videoId,
        createdAt: new Date(),
        isVisible: true,
        views: 0,
        likesCount: 0,
        helpfulCount: 0,
        commentsCount: 0,
        isSyllabusBased: false, 
      };

      await db.collection('course_materials').add(docData);
      console.log("Firestore document created successfully.");

      // 4. Cleanup temp file
      fs.unlinkSync(tempFilePath);

      return { success: true, videoUrl: publicUrl };
    } catch (error) {
      if (fs.existsSync(tempFilePath)) {
        fs.unlinkSync(tempFilePath);
      }
      console.error("Sync Error:", error);
      throw new HttpsError("internal", `Failed to sync video: ${error.message}`);
    }
  }
);
