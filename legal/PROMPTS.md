# Legal Policies & Prompt Generator Guide

This directory contains the necessary resources for implementing and maintaining compliance on **Learned App**. 

---

## 💡 Policy Maintenance Prompts
If you ever need to adjust your Privacy Policy, Terms of Service, or Data Deletion rules as the features of the app grow, you can copy the custom prompt below and paste it directly into an AI model (like ChatGPT, Gemini, or Claude) to generate updated legal drafts.

### Master Prompt for AI Policy Generator
```text
Act as an expert technology attorney and compliance counsel. Write/update a highly professional, comprehensive Privacy Policy and Data Deletion Policy for "Learned App," a mobile-first EdTech platform connecting Students and Teachers. 

### Key Application Context & Features:
1. Two user roles: Students (including minors under 13) and Teachers.
2. User authentication is managed using Firebase Authentication (supporting Email/Password and Google Sign-In).
3. Teachers upload lecture videos and PDFs to Google Cloud Storage. Uploaded videos are processed via Google Cloud Transcoder API into HLS (.m3u8) streams.
4. Teachers must upload credentials (certificates) and demo videos during onboarding for verification.
5. Students can take MCQ chapter tests, record scores, log learning statuses, and post educational doubts in public community chats.
6. The app features an AI Doubt Assistant (powered by LLM APIs). Student questions are sent to the AI API, and unique queries are cached in a Firestore database to speed up repeats.
7. The platform runs a Credit-Based Escrow Economy:
   - Students purchase credits via Stripe/Razorpay.
   - 10% royalty goes to the Teacher upon course unlock; 90% goes into an Escrow Pool.
   - AI queries burn credits. Repeating cached queries pays the Platform.
   - Completion of course splits remaining escrow 50/50 (Learn-to-Earn reward for student, Quality bonus for teacher).
   - Teachers withdraw cash through Stripe/Razorpay bank payouts.
8. Communication includes peer-to-peer chats and peer grading/voting features.

### Specific Compliance Requirements:
- GDPR (for European users) regarding access, portability, and deletion.
- COPPA compliance (since users under 13 use the student platform, requiring parental consent flows).
- CCPA/CPRA rights.
- A clear, simple Data Deletion policy showing how data is wiped from Firestore and GCS, and specifying what must be retained (e.g., anonymized transaction logs for tax audits and anonymized questions to prevent breaking public feeds).

Draft the following documents:
1. Privacy Policy (Markdown format, containing details on collected data, usage, third parties, children's privacy, and user rights).
2. Data Deletion Policy (Markdown format, detailing exactly what gets deleted, what is retained in anonymized/financial form, and the 30-day processing window).
```

---

## 📂 Legal Folder Directory

The following files have been prepared for deployment:

1. **Privacy Policy:** [PRIVACY_POLICY.md](file:///C:/playground/guide/legal/PRIVACY_POLICY.md)
   * Defines data collection (credentials, profile choices, video transcodes, chat logs, wallet histories) and COPPA requirements for young students.
2. **Data Deletion Policy:** [DATA_DELETION_POLICY.md](file:///C:/playground/guide/legal/DATA_DELETION_POLICY.md)
   * Details user rights, 30-day deletion processing SLA, what data gets scrubbed, and what subset must be kept for financial audits.
3. **Data Deletion Request Form:** [data_deletion_form.html](file:///C:/playground/guide/legal/data_deletion_form.html)
   * A premium glassmorphic dark-mode static web page that serves as the visual portal for users to submit deletion requests.
