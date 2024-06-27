import { OpenAIModel } from '@/components/chat/types';

const url = 'https://api.openai.com/v1/chat/completions';

// Create an AbortController to control and cancel the fetch request when the user hits the stop button
const controller = new AbortController();

export function stopFetch() {
  controller.abort();
}

export async function fetchData(
  apiKey: string,
  searchContent: string,
  {
    onAnswerUpdate,
    onDone,
  }: {
    onAnswerUpdate: (line: string) => void;
    onDone: (done: boolean) => void;
  }
) {
  const prompt = `Generate a comprehensive summary in Markdown format on the topic of ${searchContent}. Include sections for definition, importance, current technologies, challenges, and future perspectives. Use headers, bullet points, and links where appropriate.`;

  // Make a POST request to the OpenAI API to get chat completions
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.6,
      model: OpenAIModel.DAVINCI_TURBO,
      // Limiting the tokens during development
      max_tokens: 150,
      stream: true,
    }),
    // Use the AbortController's signal to allow aborting the request
    // This is a `fetch()` API thing, not an OpenAI thing
    signal: controller.signal,
  });

  if (!response.body) {
    return;
  }

  const data = response.body;

  if (!data) {
    return;
  }

  // Create a TextDecoder to decode the response body stream
  const decoder = new TextDecoder();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  for await (const chunk of response.body as any) {
    const decodedChunk = decoder.decode(chunk);

    const isDone = decodedChunk.includes('[DONE]');

    if (isDone) {
      onDone(true);
      break;
    }

    // Clean up the data
    const lines = decodedChunk
      .split('\n')
      .map((line) => line.replace('data: ', ''))
      .filter((line) => line.length > 0)
      .filter((line) => line !== '[DONE]')
      .map((line) => JSON.parse(line));

    // Destructuring!
    for (const line of lines) {
      const {
        choices: [
          {
            delta: { content },
          },
        ],
      } = line;

      if (content) {
        onAnswerUpdate(content);
      }
    }
  }
}
