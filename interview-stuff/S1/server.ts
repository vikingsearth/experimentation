import express from "express";
import { runClaude } from "./runner";

const app = express();
app.use(express.json());

app.post("/api/chat", async (req, res) => {
  const { prompt, sessionId } = req.body;

  if (!prompt || typeof prompt !== "string") {
    res.status(400).json({ error: "prompt is required" });
    return;
  }

  try {
    const response = await runClaude({ prompt, sessionId });
    res.json(response);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    res.status(500).json({ error: message });
  }
});

const PORT = process.env.PORT ?? 3050;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
