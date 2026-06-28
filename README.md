# Agents

A small Node.js / TypeScript project that exposes a hotel search API and runs an AI-backed hotel booking assistant.

## Features

- Express server serving hotel search requests
- Google GenAI `gemini-2.5-flash` integration
- Tool-based function calls for availability lookup and booking confirmation
- Booking confirmation sends reservation data to a MuleSoft queue endpoint

## Prerequisites

- Node.js 20+ or compatible version
- `pnpm` package manager
- Google GenAI API key
- A running MuleSoft service with API endpoints at:
  - `http://localhost:8081/api/db`
  - `http://localhost:8081/api/queue`

## Setup

1. Install dependencies:

```bash
pnpm install
```

2. Create a `.env` file in the project root with the following content:

```env
apiKey=YOUR_GOOGLE_GENAI_API_KEY
```

## Run

```bash
pnpm exec tsx src/index.ts
```

The server listens on `http://localhost:3000` and exposes:

- `GET /api/hotels/search?country=<country>`

## Notes

- This project uses `@google/genai` for AI chat and tool invocation.
- The current implementation expects `country` as a query parameter for hotel search filtering.
- The booking workflow is intended for conversational use through the AI assistant.
