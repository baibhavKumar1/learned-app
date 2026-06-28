const admin = require("firebase-admin");

// Initialize Firebase Admin SDK first
admin.initializeApp();

const auth = require("./auth");
const content = require("./content");

// Auth module exports
exports.getUserProfile = auth.getUserProfile;
exports.updateUserProfile = auth.updateUserProfile;

// Content module exports
exports.generateSignedUrl = content.generateSignedUrl;
exports.getSubjectsAndMaterials = content.getSubjectsAndMaterials;

// Teacher Dashboard module exports
const teacherDashboard = require("./teacherDashboard");
exports.onQuizAttemptEvaluated = teacherDashboard.onQuizAttemptEvaluated;
exports.onNewDoubtPosted = teacherDashboard.onNewDoubtPosted;
exports.onStudentInteraction = teacherDashboard.onStudentInteraction;
