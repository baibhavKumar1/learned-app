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

// Generate exports
const generate = require("./generate");
exports.generatePoem = generate.generatePoem;
exports.generateComment = generate.generateComment;
exports.generateContextualNote = generate.generateContextualNote;

// YouTube Sync export
const youtubeSync = require("./youtubeSync");
exports.syncYouTubeVideo = youtubeSync.syncYouTubeVideo;

// JIT Video Stitching exports
const jitStitch = require("./jitStitch");
exports.processExistingContent = jitStitch.processExistingContent;
exports.searchSegments = jitStitch.searchSegments;
