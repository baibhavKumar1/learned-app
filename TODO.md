# Game-Changing Features Backlog

This document outlines the 10x features designed to make the platform the ultimate command center for Creator-Educators and an undeniably premium learning experience for professional students. 

## Learner Features (Professional Upskilling)

### 1. Speed-Up-In-Silence ("Smart Speed")
**What it means:** Using the video's AI-generated transcript, the player automatically speeds up playback (e.g., to 1.5x) during pauses, silences, or filler words, and drops back to 1.0x when complex concepts are being explained.
**Why build it:** Saves the learner minutes per session automatically, giving them a highly optimized, premium viewing experience.
**Effort:** High
**Implementation Steps:**
1. Process the video through GCP Video Intelligence or an LLM to map silences and filler words to specific timestamps.
2. Generate and save a metadata track (JSON) of playback speed multipliers mapped to time ranges in Firestore.
3. Write a Flutter stream listener attached to the video controller that dynamically adjusts `VideoPlayerController.setPlaybackSpeed` in real-time based on the current position.

### 2. Roleplay Simulator Mode
**What it means:** Moving beyond multiple-choice quizzes, the AI acts as a real-world stakeholder (e.g., a difficult client, a code reviewer). The student must apply their knowledge in a realistic, chat/voice roleplay scenario to earn back their escrow credits.
**Why build it:** Bridges the gap between passive watching and active doing, turning a cheap video course into an expensive "bootcamp-level" experience.
**Effort:** Very High
**Implementation Steps:**
1. Build a custom chat/voice interface UI in Flutter dedicated to simulator sessions.
2. Setup Vertex AI / Gemini with a strict system prompt defining the persona, scenario, and grading rubric based on the course metadata.
3. Implement session state management to pass student context back and forth to the LLM.
4. Write backend logic where the LLM evaluates the user's final performance and triggers the escrow refund Cloud Function if they pass.

### 3. Socratic Escrow Savings
**What it means:** When a student has a doubt, the AI offers two paths: "Give me the direct answer" (costs 10 credits) or "Guide me to the answer" (costs 2 credits). The latter uses Socratic questioning to help the student figure it out themselves.
**Why build it:** Gamifies learning and genuinely teaches the student how to think, preventing the AI from just being an expensive search engine.
**Effort:** Low to Medium
**Implementation Steps:**
1. Update the 'Ask Doubt' UI to present two distinct buttons with their respective credit costs.
2. If 'Socratic' is chosen, dynamically inject a system prompt instruction to the AI to "only ask guiding questions, do not give the direct answer".
3. Update the Cloud Function billing logic to deduct 2 credits instead of the standard 10 for that specific chat session.

---

## Educator Features (Creator Command Center)

### 1. Global Auto-Dubbing
**What it means:** Using advanced AI audio processing, English video uploads are automatically translated, dubbed, and lip-synced (or voice-overed) into multiple languages (Spanish, Hindi, Mandarin, etc.) as selectable audio tracks in the player.
**Why build it:** Instantly 10x's the creator's Total Addressable Market (TAM) with zero extra work, making the platform irresistible to big YouTubers.
**Effort:** Very High
**Implementation Steps:**
1. Run the raw video audio through GCP Speech-to-Text to generate the English transcript.
2. Use Cloud Translation API to translate the transcript into target languages.
3. Pass the translated text to GCP Text-to-Speech (or a specialized voice API like ElevenLabs) to generate localized `.mp3` audio tracks.
4. Multiplex the new audio tracks into the final HLS manifest (`.m3u8`) using the Transcoder API so the Flutter player can select them natively.

### 2. Ghost-Course Predictor
**What it means:** The platform's AI aggregates every doubt, comment, and roleplay failure from an educator's current students. It then auto-generates a highly detailed, data-backed outline for their *next* course.
**Why build it:** Takes the guesswork out of product creation. Creators know exactly what their audience struggles with and what they are willing to pay for next.
**Effort:** Medium
**Implementation Steps:**
1. Write a Firestore aggregation script that pulls all doubts asked by students across all of an educator's courses.
2. Feed the aggregated text corpus into Vertex AI with a prompt to identify common knowledge gaps and generate a 5-module course outline.
3. Display the generated Markdown outline in a dedicated "Insights" or "Next Course" tab in the educator's dashboard UI.
