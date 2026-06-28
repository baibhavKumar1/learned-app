# Complete Project Functioning Plan (From Dummy to Production)

Currently, the app consists of beautiful UI screens but relies heavily on hardcoded dummy data (like static lists of videos, mocked authentication, and placeholder buttons). To make this project fully functional, we need to wire up the frontend to Firebase (Authentication, Firestore Database, and Cloud Storage).

Here is the step-by-step roadmap to make the project functional:

## Phase 1: Authentication & User Profiles
Right now, the app likely bypasses real login or uses mock users.
1. **Firebase Auth Integration:** Wire up the Login/Signup screens to use `FirebaseAuth.instance.signInWithEmailAndPassword` or Google Sign-In.
2. **User Roles:** Create a `users` collection in Firestore. When a user signs up, save their role (`teacher` or `student`).
   * *Example Document:* `{ uid: "123", name: "Rahul", role: "student", xp: 120, plan: "Pro" }`
3. **Routing Logic:** Update `main.dart` or a splash screen to check `FirebaseAuth.instance.currentUser`. Route teachers to the Teacher Dashboard and students to the Student Dashboard.

## Phase 2: Teacher Uploads & Content Management
The `UploadContentScreen` currently just changes a toggle state.
1. **Actual File Selection:** Integrate the `file_picker` package so teachers can browse and select PDFs or MP4 files from their device.
2. **GCS Upload:** Use the `GcsService.uploadToGcs` (with our Cloud Function) to securely upload the selected file to Google Cloud Storage.
3. **Save Metadata:** Once the upload succeeds, save the content details to a `content` collection in Firestore.
   * *Example Document:* `{ title: "Newton's Laws", subject: "Physics", type: "Video", storagePath: "uploads/t1/123.mp4", teacherId: "t1" }`

## Phase 3: Student Syllabus & Content Discovery
The `topic_list_screen.dart` and `search_screen.dart` use hardcoded Dart lists.
1. **Dynamic Syllabus:** Use a `StreamBuilder` or `FutureBuilder` to fetch data from the Firestore `content` collection where `subject == 'Physics'`.
2. **Search Implementation:** Replace the local string matching with a Firestore query. 
3. **Interactive Feed:** In `student_feed_screen.dart`, when a student submits an explanation, save it to a `student_explanations` collection and increment their `xp` in the `users` collection.

## Phase 4: Secure Video Playback
The `video_page.dart` currently has a dummy black container.
1. **Video Player Package:** Install the `video_player` and `chewie` packages for custom controls.
2. **Secure Fetching:** Before playing, call `GcsService().fetchSignedUrl()` passing the `storagePath` retrieved from Firestore.
3. **Playback:** Feed the temporary 15-minute secure URL to the `VideoPlayerController` to start streaming the video.

## Phase 5: Subscriptions & Payments
The `plan_selection_screen` and `confirmation_screen` are UI only.
1. **Stripe / Razorpay Integration:** Integrate a payment gateway SDK.
2. **Webhooks:** Use Firebase Cloud Functions to listen to successful payment webhooks.
3. **Unlock Content:** Update the user's Firestore document (`plan: "Premium"`). In the app, lock certain videos unless the student's `plan` allows it.

## Phase 6: AI-Driven Credit Economy & Incentive Model
Instead of traditional time-bound subscriptions, the platform uses a credit-based escrow system to perfectly align incentives across the Platform, Teachers, and Students.

1. **Course Unlock (The Split):**
   * Students pay a fixed amount (e.g., 1,000 Credits) to unlock a course.
   * **10% (100 Credits)** goes immediately to the Teacher's wallet as a base royalty.
   * **90% (900 Credits)** is placed into an "Agent Escrow Pool" specific to that student and course.

2. **Agent Burn & Caching (Platform Profit):**
   * The AI Agent acts as the primary tutor, answering doubts and grading.
   * **Novel Queries:** When a student asks a unique question, it costs credits (e.g., 10 credits) which are burned from the escrow to cover API/server costs.
   * **Cached Queries (Scale):** If a question has been asked before (common as student count scales from 10 to 100+), the Agent answers from cache. The fee is still deducted from the student's escrow, but these credits go to the **Platform Wallet** as profit.

3. **Course Completion (The 50/50 Split):**
   * When the student finishes the course, any remaining unutilized credits in their Agent Escrow pool (e.g., 600 credits) are split 50-50.
   * **50% to the Student:** Acts as a "Learn-to-Earn" completion reward. Efficient students who study well and don't spam the AI earn credits back to unlock future courses.
   * **50% to the Teacher:** Acts as a "Quality Bonus". Teachers who create clear, high-quality material generate fewer student doubts, leaving a larger escrow balance and maximizing their final payout.

## Next Steps
To begin implementation, we should start with **Phase 1 (Authentication)** to ensure we have a valid `currentUser.uid` before writing data to Firestore.
