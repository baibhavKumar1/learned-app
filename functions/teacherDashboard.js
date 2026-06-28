const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

/**
 * 1. onQuizAttemptEvaluated
 * Triggered when a student completes a quiz. 
 * If they score low, it creates an alert for the teacher.
 */
exports.onQuizAttemptEvaluated = onDocumentUpdated(
  { document: "students/{studentId}/quiz_attempts/{attemptId}", database: "(default)", region: "us-central1" },
  async (event) => {
    const newData = event.data.after?.data();
    const oldData = event.data.before?.data();
    
    if (!newData) return null;
    
    // Check if score became poor in this update
    if (newData.score < 50 && (oldData.score === undefined || oldData.score >= 50)) {
      const studentId = event.params.studentId;
      const teacherAlert = {
        type: "POOR_PERFORMANCE",
        studentId: studentId,
        quizId: newData.quizId,
        score: newData.score,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: "unread",
        message: `Student scored ${newData.score}% on quiz ${newData.quizId}.`
      };
      
      await admin.firestore().collection("teacher_alerts").add(teacherAlert);
      console.log(`Alert created for poor performance: Student ${studentId}`);
    }
    return null;
  }
);

/**
 * 2. onNewDoubtPosted
 * Triggered when a student asks a question in the forum.
 */
exports.onNewDoubtPosted = onDocumentCreated(
  { document: "forums/{forumId}/doubts/{doubtId}", database: "(default)", region: "us-central1" },
  async (event) => {
    const data = event.data?.data();
    if (!data) return null;
    
    const teacherAlert = {
      type: "NEW_DOUBT",
      studentId: data.studentId,
      forumId: event.params.forumId,
      doubtId: event.params.doubtId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "unread",
      message: `Student asked a new doubt: "${data.question?.substring(0, 50)}..."`
    };
    
    await admin.firestore().collection("teacher_alerts").add(teacherAlert);
    console.log(`Alert created for new doubt: ${event.params.doubtId}`);
    return null;
  }
);

/**
 * 3. onStudentInteraction
 * Triggered when a student likes content (reacts), triggering an interaction alert.
 */
exports.onStudentInteraction = onDocumentWritten(
  { document: "course_materials/{contentId}/reactions/{studentId}", database: "(default)", region: "us-central1" },
  async (event) => {
    const newData = event.data.after?.data();
    const oldData = event.data.before?.data();
    
    // If newData doesn't exist, they removed their reaction entirely
    if (!newData) return null;
    
    // Only alert if they liked content (and it wasn't already liked)
    if (newData.type === "like" && oldData?.type !== "like") {
      // 1. Fetch the course material to find the teacherId
      const materialRef = admin.firestore().collection("course_materials").doc(event.params.contentId);
      const materialSnap = await materialRef.get();
      
      if (!materialSnap.exists) {
        console.log("Material not found, cannot send alert.");
        return null;
      }
      
      const teacherId = materialSnap.data().teacherId;
      
      if (!teacherId) {
        console.log("No teacherId found on material.");
        return null;
      }

      const teacherActivity = {
        title: `Student liked your content`,
        type: "upvote",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          studentId: event.params.studentId,
          contentId: event.params.contentId,
        }
      };
      
      // 2. Write directly to the specific teacher's activities subcollection (since it is an ActivityItem)
      await admin.firestore().collection("teachers").doc(teacherId).collection("activities").add(teacherActivity);
      console.log(`Activity routed to teacher ${teacherId} for student interaction.`);
    }
    return null;
  }
);
