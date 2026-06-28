# Project Implementation TODO List

This document lists all the features that are either missing or partially implemented in the application.

## 🎓 Student App

### Onboarding
- [x] **Select Subjects**: Add a subject selection step or input (e.g., Mathematics, Physics, Chemistry, Biology) in the onboarding flow.

### Home
- [x] **Trending**: Add a section showing trending courses or video lectures on the home dashboard.

### Syllabus
- [x] **Topic List**: Make chapter items clickable, navigating to a topic list screen for that chapter.
- [x] **Video Page**: Create a video details and playback screen for selected topics with a mock video player.
- [x] **Chapter Test**: Create an MCQ test module containing questions, options, timer, and score summaries.

### Search
- [x] **Filter Panel**: Create a sheet or widget with filters for Class, Board, Subject, and Teacher.
- [x] **Result Page**: Create a page listing videos, chapters, or notes matching the search query.

### Doubts
- [x] **Community Doubts**: Add a tab/toggle to let students view public questions posted by peers.

### Subscription
- [x] **Plan Selection**: Renders premium tier subscription cards (e.g., Monthly, Yearly, Exam Special).
- [x] **Payment Gateway**: Simulated checkout screen requiring mock card details.
- [x] **Confirmation**: Success screen showing invoice confirmation, active duration, and receipt.

### Profile
- [x] **Saved Content**: Add a view displaying bookmarked or offline-downloaded chapters and notes.
- [x] **Settings Functionality**: Connect the settings options (Edit Profile, Subscriptions, Help) to functional views.

---

## 👨‍🏫 Teacher App

### Verification
- [x] **Qualification Upload**: Add form/inputs to upload files representing certificates or academic details.
- [x] **Demo Video**: Add section/inputs to upload a screen recording or presentation video.
- [x] **Approval Status**: Screen displaying verification status (e.g., Pending review, Approved, Rejected).

### Bottom Navigation Tabs Setup
- [x] **Navigation Core**: Connect the BottomNavigationBar in the Teacher Dashboard to switch between screens (Dashboard, Upload, Students, Earnings, Profile) rather than rendering a static layout.

### Upload Content
- [x] **Metadata Selection**: Input form fields (Class, Board, Subject, Title, Description).
- [x] **Video Upload**: Mock selector/progress bar for lecture videos.
- [x] **PDF Upload**: Mock selector/progress bar for textbook chapters or formula notes.
- [x] **Pricing & Publish**: Fields to define if the resource is Free or Premium, with pricing details and a publish trigger.

### Student Management
- [x] **Subscribers**: A panel lists enrolled/subscribed students with search and stats.
- [x] **Messages**: A messaging/chat panel allowing direct messaging with subscribers.

### Earnings
- [x] **Wallet**: Current balances, lifetime earnings, and monthly summaries.
- [x] **Withdraw**: Form to process bank payouts.
- [x] **Transaction History**: List showing subscriber subscription splits, and past withdrawals.

### Profile
- [x] **Teacher Profile**: Add settings, stats summary, and qualification display.
