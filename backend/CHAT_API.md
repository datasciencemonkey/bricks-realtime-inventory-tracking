# Chat API Documentation

## Overview
The chat API endpoint allows the Flutter mobile app to interact with the Databricks AI model endpoint for conversational AI features.

## Configuration

### Environment Variables
Add the following to your `.env` file:

```bash
# Databricks Chat/AI Model Endpoint Configuration
DATABRICKS_CHAT_ENDPOINT=https://fe-vm-vdm-serverless-jpckvw.cloud.databricks.com/serving-endpoints
DATABRICKS_CHAT_MODEL=mas-3c3cfb5f-endpoint
```

**Note**: The `DATABRICKS_TOKEN` variable is reused from the SQL warehouse configuration.

## API Endpoint

### POST `/api/chat`

Sends messages to the Databricks chat model and returns the AI response.

#### Request Body
```json
{
  "messages": [
    {
      "role": "user",
      "content": "hello"
    }
  ]
}
```

#### Response
```json
{
  "response": "The AI model's response text",
  "model": "mas-3c3cfb5f-endpoint"
}
```

#### Example using curl
```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "hello"
      }
    ]
  }'
```

#### Example using Python
```python
import requests

response = requests.post(
    "http://localhost:8000/api/chat",
    json={
        "messages": [
            {"role": "user", "content": "hello"}
        ]
    }
)

data = response.json()
print(data["response"])
```

## Multi-turn Conversations

To maintain conversation context, send the full conversation history:

```json
{
  "messages": [
    {
      "role": "user",
      "content": "What is the inventory status?"
    },
    {
      "role": "assistant",
      "content": "The current inventory shows 1,000 units in transit..."
    },
    {
      "role": "user",
      "content": "What about the items at the DC?"
    }
  ]
}
```

## Error Handling

### 500: Configuration Error
```json
{
  "detail": "Chat endpoint not configured. Please set DATABRICKS_TOKEN, DATABRICKS_CHAT_ENDPOINT, and DATABRICKS_CHAT_MODEL in .env"
}
```

### 504: Timeout
```json
{
  "detail": "Chat request timed out"
}
```

### Other Errors
```json
{
  "detail": "Error calling chat endpoint: [error message]"
}
```

## Databricks Model Integration

The endpoint uses the OpenAI Python SDK to communicate with Databricks serving endpoints:

```python
from openai import OpenAI

# Initialize client with Databricks endpoint
client = OpenAI(
    api_key=os.getenv("DATABRICKS_TOKEN"),
    base_url="https://fe-vm-vdm-serverless-jpckvw.cloud.databricks.com/serving-endpoints"
)

# Make chat completion request
response = client.chat.completions.create(
    model="mas-3c3cfb5f-endpoint",
    messages=[
        {"role": "user", "content": "hello"}
    ]
)

# Extract response
response_text = response.choices[0].message.content
```

The backend automatically handles the OpenAI SDK integration and returns a simple JSON response to the Flutter app.

## Dependencies

The chat endpoint requires the OpenAI Python SDK. Install it with:

```bash
cd backend
uv pip install -r requirements.txt
```

Or specifically:
```bash
uv pip install openai>=1.0.0
```

## Testing

Start the backend server:
```bash
cd backend
uv run uvicorn main:app --reload
```

Test the endpoint:
```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "hello"}]}'
```

## Next Steps

1. Update your `.env` file with the actual endpoint and model name
2. Restart the backend server
3. The Flutter Planning screen will automatically connect to this endpoint
4. Test the chat functionality in the mobile app
