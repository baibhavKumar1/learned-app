const { z } = require('genkit');
const { onCallGenkit } = require('firebase-functions/https');
const admin = require('firebase-admin');
const { ai } = require('./shared/ai');

// 2. Define the flow logic (replaces onFlow)
const generatePoemFlow = ai.defineFlow(
  {
    name: 'generatePoem',
    inputSchema: z.object({ subject: z.string() }),
    outputSchema: z.object({ poem: z.string() }),
  },
  async ({ subject }) => {
    // Generate text using the ai instance
    const { text } = await ai.generate(`Compose a short poem about ${subject}.`);
    return { poem: text };
  }
);

// 3. Export as a Firebase HTTPS Callable function
// This automatically handles the network layer so Flutter can call it
exports.generatePoem = onCallGenkit(
  {
    // For testing without app check/auth:
    enforceAppCheck: false,
    authPolicy: () => true, 
  },
  generatePoemFlow
);

const generateCommentFlow = ai.defineFlow(
  {
    name: "generateComment",
    inputSchema: z.object({
      postContent: z.string(),
      tone: z.string().default('positive'),
      ctaLink: z.string().optional(),
      promoCode: z.string().optional(),
    }),
    outputSchema: z.string(),
  },
  async (input) => {
    let prompt = `You are a helpful and knowledgeable educator replying to a student's YouTube comment on your educational video.
The student commented: "${input.postContent}"
Write a ${input.tone}, concise, and engaging reply to this comment. Do not use hashtags. Keep it under 3 sentences.`;

    if (input.ctaLink) {
      prompt += `\nCritically important: At the end of your reply, seamlessly invite them to check out your full course using this link: ${input.ctaLink}`;
      if (input.promoCode) {
        prompt += ` and mention that they can use the promo code ${input.promoCode} for a discount.`;
      }
    }

    const { text } = await ai.generate(prompt);
    return text;
  }
);

exports.generateComment = onCallGenkit(
  {
    enforceAppCheck: false,
    authPolicy: () => true,
  },
  generateCommentFlow
);

// Phase 4: Contextual Note-Taking
const generateContextualNoteFlow = ai.defineFlow(
  {
    name: "generateContextualNote",
    inputSchema: z.object({
      transcriptSegment: z.string(),
      imageBase64: z.string().optional(),
    }),
    outputSchema: z.object({
      title: z.string(),
      markdownNote: z.string(),
    }),
  },
  async (input) => {
    const prompt = `You are an AI teaching assistant creating a contextual study note for a student.
Below is a segment of the video's transcript:
"${input.transcriptSegment}"

Based on this transcript (and the provided video frame if available), create a comprehensive, structured study note.
Provide a concise title and a detailed markdown note. Focus on the core educational concepts. Include bullet points if helpful.`;

    const request = {
      model: 'vertexai/gemini-2.5-flash',
      prompt: prompt,
      config: {
        temperature: 0.4,
      }
    };

    // If an image is provided, attach it as a multimodal part
    if (input.imageBase64) {
      request.messages = [
        {
          role: 'user',
          content: [
            { text: prompt },
            { media: { url: `data:image/jpeg;base64,${input.imageBase64}` } }
          ]
        }
      ];
      delete request.prompt;
    }

    const { text } = await ai.generate(request);
    
    // We expect the model to return JSON if we instruct it, or we can use structured output.
    // Let's use AI's built in structured output generation via output schema.
    const result = await ai.generate({
      ...request,
      output: {
        schema: z.object({
          title: z.string().describe('A short, descriptive title for this note.'),
          markdownNote: z.string().describe('The detailed study note formatted in Markdown.'),
        })
      }
    });

    return result.output;
  }
);

exports.generateContextualNote = onCallGenkit(
  {
    enforceAppCheck: false,
    authPolicy: () => true,
  },
  generateContextualNoteFlow
);