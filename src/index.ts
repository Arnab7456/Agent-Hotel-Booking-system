import { GoogleGenAI, Type } from '@google/genai';
import type { FunctionDeclaration, Tool } from '@google/genai';
import * as readline from 'readline/promises';
import { stdin as input, stdout as output } from 'process';
import express from 'express';
import dotenv from 'dotenv';
dotenv.config();

// ==========================================
// Express Setup (Server & Router)
// ==========================================
const app = express();
const PORT = 3000;
const MULESOFT_API_URL = 'http://localhost:8081/api/db';
const MULESOFT_QUEUE_URL = 'http://localhost:8081/api/queue';

app.use(express.json());

// Express Router to handle the data fetching and filtering
app.get('/api/hotels/search', async (req, res) => {
  try {
    const { country } = req.query;
    const response = await fetch(MULESOFT_API_URL);
    if (!response.ok) throw new Error(`MuleSoft error: ${response.statusText}`);
    
    const completeHotelData: any = await response.json();

    let availableHotels = completeHotelData;
    if (country) {
      availableHotels = completeHotelData.filter((hotel: any) => 
        hotel.country_name?.toLowerCase() === (country as string).toLowerCase()
      );
    }
    res.status(200).json(availableHotels);
  } catch (error: any) {
    console.error("Router error:", error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Express server routing hotel data on http://localhost:${PORT}`);
});

// ==========================================
// Gemini API Config
// ==========================================
const ai = new GoogleGenAI({ apiKey: process.env.apiKey as string }); 
const MODEL_NAME = 'gemini-2.5-flash';

// ==========================================
// 1. Tool Implementation Actions
// ==========================================
async function fetchAvailableHotels(country: string): Promise<any> {
  try {
    const response = await fetch(`http://localhost:${PORT}/api/hotels/search?country=${encodeURIComponent(country)}`);
    if (!response.ok) return { error: "Could not fetch availability from backend routing table." };
    return await response.json();
  } catch (error: any) {
    return { error: error.message };
  }
}

async function sendBookingToMuleQueue(bookingData: { chatId: number, name: string, email: string, destination: string, country: string }): Promise<any> {
  try {
    const response = await fetch(MULESOFT_QUEUE_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chatId: bookingData.chatId,
        Name: bookingData.name,
        Email: bookingData.email,
        booking_destination: bookingData.destination,
        booking_country: bookingData.country
      })
    });
    return { status: "Success", message: "Booking successfully pushed to JMS queue via MuleSoft flow." };
  } catch (error: any) {
    return { status: "Error", message: error.message };
  }
}

// ==========================================
// 2. Define Schema-validated Tools
// ==========================================
const getAvailableHotelsDeclaration: FunctionDeclaration = {
  name: 'get_available_hotels',
  description: 'Fetches complete data to see which hotels are available in a specific country.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      country: { type: Type.STRING, description: 'The destination country extracted from user intent (e.g., India).' }
    },
    required: ['country'],
  },
};

const confirmBookingDeclaration: FunctionDeclaration = {
  name: 'confirm_booking',
  description: 'Submits and confirms the final reservation. Call this ONLY after you have collected the user\'s Name, Email, Destination Hotel Name, and Country.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      chatId: { type: Type.INTEGER, description: 'A unique random integer identifier generated for this transaction session.' },
      name: { type: Type.STRING, description: 'The full name of the guest.' },
      email: { type: Type.STRING, description: 'The customer email address.' },
      destination: { type: Type.STRING, description: 'The explicit name of the chosen hotel selected from the available choices.' },
      country: { type: Type.STRING, description: 'The country where the hotel resides.' }
    },
    required: ['chatId', 'name', 'email', 'destination', 'country'],
  },
};

const agentTools: Tool[] = [{ functionDeclarations: [getAvailableHotelsDeclaration, confirmBookingDeclaration] }];

// ==========================================
// 3. Main Multi-turn Execution Loop
// ==========================================
async function main() {
  const rl = readline.createInterface({ input, output });
  const generatedChatId = Math.floor(100000 + Math.random() * 900000); // Unique ID for session tracking
  
  const chat = ai.chats.create({
    model: MODEL_NAME,
    config: {
      systemInstruction: `You are an expert hotel reservation manager. 
      Your goal is to gather complete information to finish a booking.
      1. First check hotel availability using the tool if the user gives a destination. Show options.
      2. If a user selects a hotel, actively ask conversational questions to collect their Name and Email. 
      3. Once you have Name, Email, chosen Hotel Destination, and Country, instantly invoke 'confirm_booking'.
      Use the following session tracking chatId for the booking function call: ${generatedChatId}`,
      tools: agentTools,
    },
  });

  console.log("🤖 Support Agent Online. Type 'exit' to quit.\n");

  while (true) {
    const userMessage = await rl.question('User: ');
    if (userMessage.trim().toLowerCase() === 'exit') {
      console.log("Goodbye!");
      break;
    }
    if (!userMessage.trim()) continue;

    let response = await chat.sendMessage({ message: userMessage });
    
    while (response.functionCalls && response.functionCalls.length > 0) {
      const firstCall = response.functionCalls[0];
      if (!firstCall) break;

      console.log(`\n[System] Tool Call ➡️ Executing: ${firstCall.name}...`);
      let toolResult: any = "";

      if (firstCall.name === 'get_available_hotels') {
        const args = firstCall.args as { country: string };
        const data = await fetchAvailableHotels(args.country);
        toolResult = { availableHotels: data };
      } else if (firstCall.name === 'confirm_booking') {
        const args = firstCall.args as any;
        const data = await sendBookingToMuleQueue(args);
        toolResult = { db_queue_response: data };
      }

      response = await chat.sendMessage({
        message: [
          {
            functionResponse: {
                name: firstCall.name ?? '', 
                response: toolResult
            }
          }
        ]
      });
    }

    console.log(`Customer Agent: ${response.text}\n`);
  }
  rl.close();
}

main().catch(console.error);