# Custom HLS Implementation Plan

## Overview
This plan outlines the steps to build a custom, secure HTTP Live Streaming (HLS) pipeline using Google Cloud native tools. This replaces the basic `.mp4` signed URL approach with a robust, chunked, and encrypted video delivery system.

## Phase 1: Storage and Cloud Functions Setup
1. **Raw Videos Bucket:** Create a dedicated GCS bucket (e.g., `gs://[PROJECT_ID]-raw-videos`) for teacher uploads.
2. **Processed Videos Bucket:** Create a second bucket (e.g., `gs://[PROJECT_ID]-processed-videos`) to store the final `.m3u8` and `.ts` chunks.
3. **Trigger Function:** Write a Firebase Cloud Function (`onObjectFinalized`) that listens to the `raw-videos` bucket. When an `.mp4` is uploaded, it triggers Phase 2.

## Phase 2: Transcoding Pipeline (Google Cloud Transcoder API)
1. **Enable API:** Enable the Google Cloud Transcoder API in the GCP project.
2. **Create Job:** The Cloud Function from Phase 1 will submit a Job to the Transcoder API.
   * Input: `gs://[PROJECT_ID]-raw-videos/teacher1/video.mp4`
   * Output: `gs://[PROJECT_ID]-processed-videos/teacher1/video/`
3. **Job Configuration:**
   * Generate multiple resolutions (1080p, 720p, 480p).
   * Create an HLS manifest (`.m3u8`).
   * Apply AES-128 encryption to the chunks (optional but recommended for security).
4. **Cleanup:** Delete the raw `.mp4` after the job succeeds to save storage costs.

## Phase 3: Metadata and Firestore
1. **Update Database:** Use Pub/Sub or a webhook from the Transcoder API to notify when the job is done.
2. **Save to Firestore:** Update the video document in Firestore with the `m3u8` storage path (or public URL if using CDN) instead of the raw `.mp4` path.
   * `storagePath: "processed-videos/teacher1/video/manifest.m3u8"`

## Phase 4: Flutter Playback
1. **Fetch Playlist:** The Flutter app requests the `.m3u8` URL from the backend.
2. **Video Player:** Point the `video_player` controller (or `chewie`) to the `.m3u8` URL. The player will automatically handle downloading chunks and switching resolutions based on internet speed.
