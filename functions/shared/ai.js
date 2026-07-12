/**
 * Shared Genkit + Vertex AI singleton.
 *
 * Import this module instead of calling genkit() directly in individual
 * function files. Having a single ai instance prevents duplicate plugin
 * initialization which causes Firebase's code-analysis step to time out.
 */
const { genkit } = require('genkit');
const { vertexAI } = require('@genkit-ai/vertexai');

const ai = genkit({
  plugins: [vertexAI()],
  model: 'vertexai/gemini-2.5-flash',
});

module.exports = { ai };
