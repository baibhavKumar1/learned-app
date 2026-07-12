const { z } = require('genkit');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { ai } = require('./shared/ai');

// Zod schema for a single transcript segment
const segmentSchema = z.object({
  topic: z.string().describe('Short title of the concept being explained'),
  summary: z
    .string()
    .describe('2-3 sentence plain-English summary of what is explained'),
  keywords: z
    .array(z.string())
    .describe(
      '5-10 lowercase keywords or short phrases a student might search to find this clip'
    ),
  startSec: z
    .number()
    .describe('Timestamp in seconds where this concept begins'),
  endSec: z
    .number()
    .describe('Timestamp in seconds where this concept ends'),
});

/**
 * Tokenizes text into an array of unique lowercase words, removing punctuation.
 * Used for building searchable text indices natively in Firestore.
 */
function generateSearchTokens(topic, summary, keywords) {
  const combined = `${topic} ${summary} ${keywords.join(' ')}`;
  // Remove non-alphanumeric (keep spaces), lowercase, split by whitespace
  const rawTokens = combined.toLowerCase().replace(/[^\w\s]/g, '').split(/\s+/);
  // Filter out tiny words and deduplicate
  const uniqueTokens = [...new Set(rawTokens.filter((t) => t.length > 1))];
  return uniqueTokens;
}

/**
 * Internal helper: calls Gemini 2.5 Flash with the video at gsUri and returns
 * an array of semantically segmented context blocks.
 *
 * This is called ONCE per video at ingest time — never at query time.
 */
async function segmentVideo(gsUri) {
  const result = await ai.generate({
    model: 'vertexai/gemini-2.5-flash',
    messages: [
      {
        role: 'user',
        content: [
          {
            media: {
              url: gsUri,
              contentType: 'video/mp4',
            },
          },
          {
            text: `You are analyzing an educational video.
Segment the entire video into self-contained conceptual topics.

Rules:
- Each segment starts EXACTLY where the concept begins and ends EXACTLY where it concludes.
- Segments must be contiguous — endSec of one segment equals startSec of the next.
- Segments must be exhaustive — together they must cover the full video from 0 to the last second.
- A segment can be 10 seconds or 10 minutes. Follow natural content boundaries, not a fixed window.
- Keywords must be lowercase single words or short phrases that a student would type in a search bar.
- Do not include filler segments like "intro" or "outro" unless they contain real educational content.

Return only valid JSON matching this exact shape, no other text:
{
  "segments": [
    {
      "topic": "...",
      "summary": "...",
      "keywords": ["...", "..."],
      "startSec": 0.0,
      "endSec": 45.5
    }
  ]
}`,
          },
        ],
      },
    ],
    output: {
      schema: z.object({
        segments: z.array(segmentSchema),
      }),
    },
  });

  if (!result.output || !Array.isArray(result.output.segments)) {
    throw new Error('Gemini returned an unexpected output structure.');
  }

  return result.output.segments;
}

/**
 * processExistingContent
 *
 * HTTP-callable Cloud Function.
 * Takes the Firestore docId of an already-uploaded course_materials document,
 * runs the full transcription + segmentation pipeline on its video, and writes
 * the resulting transcript_segments to Firestore.
 *
 * The educator calls this once for any video uploaded before the automatic
 * onDocumentCreated trigger is in place. It also serves as the backfill tool.
 *
 * Input:  { docId: string }
 * Output: { success: true, segmentsCreated: number }
 */
exports.processExistingContent = onCall(
  {
    timeoutSeconds: 540, // 9 minutes — enough for a full lecture video
    memory: '512MiB',
    enforceAppCheck: false,
    authPolicy: (auth) => !!auth,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be logged in.');
    }

    const { docId } = request.data;

    if (!docId || typeof docId !== 'string' || docId.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'A valid docId is required.');
    }

    const db = admin.firestore();
    const docRef = db.collection('course_materials').doc(docId);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new HttpsError(
        'not-found',
        `No course_materials document found for docId: ${docId}`
      );
    }

    const data = doc.data();

    // Only the teacher who owns this content may trigger processing
    if (data.teacherId !== request.auth.uid) {
      throw new HttpsError(
        'permission-denied',
        'You are not authorized to process this content.'
      );
    }

    if (!data.videoUrl || !data.videoFileName) {
      throw new HttpsError(
        'failed-precondition',
        'This content has no video file. Only video content can be processed.'
      );
    }

    if (data.transcriptionStatus === 'processing') {
      throw new HttpsError(
        'failed-precondition',
        'This video is already being processed. Please wait.'
      );
    }

    if (data.transcriptionStatus === 'done') {
      throw new HttpsError(
        'already-exists',
        'This video has already been processed and indexed.'
      );
    }

    // Mark as processing immediately so duplicate calls are blocked
    await docRef.update({ transcriptionStatus: 'processing' });

    try {
      // Reconstruct the gs:// URI from known storage path pattern.
      // upload_content_screen.dart stores files at:
      //   course_materials/{docId}/videos/{videoFileName}
      const bucketName = admin.storage().bucket().name;
      const gsUri = `gs://${bucketName}/course_materials/${docId}/videos/${data.videoFileName}`;

      console.log(`Starting segmentation for docId=${docId}, gsUri=${gsUri}`);

      const segments = await segmentVideo(gsUri);

      if (segments.length === 0) {
        throw new Error('Gemini returned 0 segments. The video may be too short or silent.');
      }

      // Denormalize courseTitle and isFree into each segment so searchSegments
      // can return complete results without N+1 Firestore reads.
      const courseTitle = data.title ?? 'Untitled';
      const isFree = data.isFree ?? false;
      const courseId = data.courseId ?? null;

      // Write all segments in a single batch
      const batch = db.batch();

      for (const seg of segments) {
        const segRef = db.collection('transcript_segments').doc();
        batch.set(segRef, {
          docId,
          videoUrl: data.videoUrl,
          courseId,
          teacherId: data.teacherId,
          courseTitle,
          isFree,
          topic: seg.topic,
          summary: seg.summary,
          keywords: seg.keywords,
          searchTerms: generateSearchTokens(seg.topic, seg.summary, seg.keywords),
          startSec: seg.startSec,
          endSec: seg.endSec,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await docRef.update({ transcriptionStatus: 'done' });

      console.log(
        `processExistingContent: wrote ${segments.length} segments for docId=${docId}`
      );

      return { success: true, segmentsCreated: segments.length };
    } catch (error) {
      console.error(`processExistingContent error for docId=${docId}:`, error);
      // Mark as failed so the educator can retry
      await docRef.update({ transcriptionStatus: 'failed' });
      throw new HttpsError('internal', `Processing failed: ${error.message}`);
    }
  }
);

/**
 * searchSegments
 *
 * HTTP-callable Cloud Function.
 * Accepts a free-text query from the student, tokenizes it into keywords,
 * queries transcript_segments via Firestore array-contains-any, and returns
 * only clips the student is allowed to access (free content + unlocked courses).
 *
 * Zero AI calls at query time — all context boundaries are pre-computed.
 *
 * Input:  { query: string }
 * Output: { clips: Array<{ segmentId, docId, videoUrl, topic, summary, startSec, endSec, courseTitle }> }
 */
exports.searchSegments = onCall(
  {
    enforceAppCheck: false,
    authPolicy: (auth) => !!auth,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be logged in.');
    }

    const { query } = request.data;

    if (!query || typeof query !== 'string' || query.trim().length < 2) {
      throw new HttpsError(
        'invalid-argument',
        'query must be a string of at least 2 characters.'
      );
    }

    const uid = request.auth.uid;
    const db = admin.firestore();

    // Fetch the student's unlocked course IDs
    const userDoc = await db.collection('users').doc(uid).get();
    const unlockedCourses = userDoc.exists
      ? (userDoc.data()?.unlockedCourses ?? [])
      : [];

    // Tokenize query: lowercase, split on whitespace, drop single-character tokens
    const queryKeywords = query
      .toLowerCase()
      .trim()
      .split(/\s+/)
      .filter((k) => k.length > 1)
      .slice(0, 10); // Firestore array-contains-any supports up to 30; cap at 10

    if (queryKeywords.length === 0) {
      return { clips: [] };
    }

    // Query transcript_segments. Firestore array-contains-any returns documents
    // where the searchTerms array contains at least one of the queried tokens.
    const snapshot = await db
      .collection('transcript_segments')
      .where('searchTerms', 'array-contains-any', queryKeywords)
      .limit(20)
      .get();

    const clips = snapshot.docs
      .map((doc) => {
        const seg = doc.data();

        // Gate: only return the clip if the content is free OR the student
        // has unlocked the course it belongs to
        const accessible =
          seg.isFree === true || unlockedCourses.includes(seg.courseId);

        if (!accessible) return null;

        return {
          segmentId: doc.id,
          docId: seg.docId,
          videoUrl: seg.videoUrl,
          topic: seg.topic,
          summary: seg.summary,
          startSec: seg.startSec,
          endSec: seg.endSec,
          courseTitle: seg.courseTitle,
        };
      })
      .filter(Boolean); // remove null (inaccessible) entries

    return { clips };
  }
);
