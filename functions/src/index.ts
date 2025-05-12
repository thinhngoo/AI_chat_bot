// Import Firebase SDK
import {onRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";

// Import script demo Genkit
import "./genkit-sample";

// Simple HTTP function demo
export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from AI Chat Bot Firebase Functions!");
});
