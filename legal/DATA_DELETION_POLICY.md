# Data Deletion Policy

**Last Updated:** July 4, 2026

*Disclaimer: This document is a template for informational purposes. Consult with a qualified attorney to ensure compliance with all applicable laws and regulations specific to your situation.*

At **Learned App** (the "App"), we respect your privacy and provide a simple, transparent path to have your account and associated personal data deleted. This Data Deletion Policy outlines what information is deleted, what is retained for compliance, and how you can initiate a deletion request.

---

## 1. Scope of Data Deletion

When you request the deletion of your account, we process the removal of your personal data from all active systems. The scope of deletion depends on your user role.

### A. For Students
We will permanently delete:
* **Account Credentials:** Your Firebase Authentication profile, login credentials, and linked Google Sign-In associations.
* **Student Profile Metadata:** Your name, email address, profile picture, selected subjects, board, and grade.
* **Activity & Engagement Records:** Your quiz scores, test records, active learning trails, and XP (Experience Points).
* **Communication Logs:** Private chat messages sent to teachers and community doubts labeled with your identity.
* **Financial Wallet Details:** Unutilized balances or active escrows (upon deletion, all remaining credits in your account are forfeited and the wallet is closed).

### B. For Teachers
We will permanently delete:
* **Account Credentials:** Your Firebase Authentication profile and linked credentials.
* **Teacher Profile & Stats:** Name, email, profile picture, and stats summaries.
* **Verification Documents:** All academic qualification certificates and demo videos uploaded to Google Cloud Storage for account approval.
* **Wallet History:** Active balance and withdrawal history (withdrawals must be finalized *before* request processing).

---

## 2. What Data Is Retained (And Why)

In certain circumstances, we are legally required or operationally justified in retaining specific subsets of data. In such cases, the data is either strictly anonymized or stored securely separate from active directories.

* **Transaction Records:** We retain logs of payments, purchases, and teacher payouts for tax, financial auditing, and bookkeeping compliance (as required by local tax authorities). No payment card details are stored by us.
* **Anonymized Doubts and Explanations:** To prevent breaking the educational feeds and learning indexes of other users, public questions and solutions you posted will be anonymized. All identifying information (name, avatar, user ID) is removed, and the post is assigned to a generic "Deleted User" profile.
* **Anonymized AI Cached Queries:** Past queries submitted to the AI Doubt Assistant will be fully stripped of personal identifiers and retained in our cached questions index to speed up response latency for other students.

---

## 3. How to Request Data Deletion

You can request data deletion through the following three methods:

### Method 1: Web Data Deletion Form (Recommended)
You can submit an automated request using our [Data Deletion Request Form](data_deletion_form.html). Fill out your registered details and submit the form for automated verification.

### Method 2: In-App Settings
1. Log in to the **Learned App**.
2. Navigate to your **Profile Tab**.
3. Tap on the **Settings Gear Icon** in the top right.
4. Select **Edit Profile** / **Account Settings**.
5. Tap **Delete Account** and follow the on-screen confirmation steps.

### Method 3: Email Support
Send an email to **support@learnedapp.com** from your registered email address with the subject line: **"Data Deletion Request - [Your Name]"**.

---

## 4. Processing Timeline

* **Wipe Out Phase:** Once a deletion request is verified, we will begin the deletion process. Your account will be immediately deactivated, restricting access to the App.
* **Completion Window:** Your personal data will be completely deleted from our production databases (Cloud Firestore) and file stores (Google Cloud Storage) within **30 days** of the request.
* **Backup Cycles:** Data may persist in secure database backups for up to **60 days** before being completely overwritten. Backups are encrypted and isolated from active operations.

---

## 5. Contact Information

If you have questions regarding the status of your data deletion request, please contact our Data Protection Officer at:
* **Email:** privacy@learnedapp.com
