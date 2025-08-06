#!/bin/bash

# OPENAI_BASE_URL and OPENAI_API_KEY should be set in .env
# source ./.env

# Model configuration - can be overridden with command line argument
PRIMARY_MODEL="${1:-openai.gpt-oss-120b-1:0}"
NOVA_MODEL="us.amazon.nova-premier-v1:0"

echo "🚀 Testing Amazon Bedrock OpenAI Compatibility with curl"
echo "Base URL: $OPENAI_BASE_URL"
echo "Primary Model: $PRIMARY_MODEL"
echo "Nova Model: $NOVA_MODEL"
echo "=================================================="

# Test 1: Basic Chat Completion with Reasoning Model
echo "Test 1: Basic Chat Completion with Reasoning Model"
curl -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"$PRIMARY_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"What is 15 * 23? Show your reasoning step by step.\"}
    ],
    \"max_completion_tokens\": 1024
  }" | jq '.'
#
# Response:
# {
#   "id": "chatcmpl-edc562cd",
#   "choices": [
#     {
#       "finish_reason": "stop",
#       "index": 0,
#       "message": {
#         "content": "<reasoning>We need to answer what is 15 * 23, showing reasoning step by step. So compute multiplication. 15*23 = 15*20 + 15*3 = 300 + 45 = 345. Show steps: break 23 into 20+3. Or use other methods. Provide answer: 345.\n\nWe must show reasoning step by step. Provide answer. Probably format: Step 1, Step 2, etc. Provide final answer.\n\n</reasoning>**Step‑by‑step multiplication**\n\n1. **Break one factor into easier parts**  \n   \\(23 = 20 + 3\\).\n\n2. **Multiply 15 by each part**  \n   - \\(15 \\times 20 = (15 \\times 2) \\times 10 = 30 \\times 10 = 300\\)  \n   - \\(15 \\times 3 = 45\\)\n\n3. **Add the two products together**  \n   \\(300 + 45 = 345\\)\n\n\\[\n\\boxed{15 \\times 23 = 345}\n\\]",
#         "role": "assistant"
#       }
#     }
#   ],
#   "created": 1754494969,
#   "model": "openai.gpt-oss-120b-1:0",
#   "service_tier": "standard",
#   "system_fingerprint": "fp_bc33001493",
#   "object": "chat.completion",
#   "usage": {
#     "completion_tokens": 169,
#     "prompt_tokens": 23,
#     "total_tokens": 192
#   }
# }
# Status: ✅ WORKS - Shows reasoning in <reasoning> tags

# Test 2: Reasoning Effort Parameter
echo "Test 2: Reasoning Effort Parameter"
curl -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"$PRIMARY_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Solve this logic puzzle: Three friends have different colored shirts (red, blue, green). Alice does not wear red. Bob does not wear blue. Charlie wears green. What color does each person wear?\"}
    ],
    \"reasoning_effort\": \"medium\",
    \"max_completion_tokens\": 1024
  }" | jq '.'
#
# Response:
# {
#   "id": "chatcmpl-6dbb62de",
#   "choices": [
#     {
#       "finish_reason": "stop",
#       "index": 0,
#       "message": {
#         "content": "<reasoning>We have a simple logic puzzle. Three friends: Alice, Bob, Charlie. Shirts colors: red, blue, green. Given: Alice does not wear red. Bob does not wear blue. Charlie wears green. Determine each color. Therefore Charlie = green. Remaining colors: red and blue for Alice and Bob. Alice doesn't wear red, so Alice wears blue. Bob can't wear blue, so Bob wears red. So answer: Alice - blue, Bob - red, Charlie - green.\n\nBut maybe we need to present reasoning.\n\nLet's produce a solution.\n\n</reasoning>**Solution**\n\n| Person   | Shirt color |\n|----------|--------------|\n| Alice    | **Blue** |\n| Bob      | **Red** |\n| Charlie  | **Green** |\n\n**Reasoning**\n\n1. The puzzle states that **Charlie wears green**.  \n   → Charlie = green.\n\n2. The remaining colors are red and blue, to be assigned to Alice and Bob.\n\n3. **Alice does not wear red**.  \n   → The only color left for Alice is blue.  \n   → Alice = blue.\n\n4. **Bob does not wear blue**.  \n   The only color not yet taken is red, so Bob must wear red.  \n\nAll conditions are satisfied, giving the assignment above.",
#         "role": "assistant"
#       }
#     }
#   ],
#   "created": 1754494987,
#   "model": "openai.gpt-oss-120b-1:0",
#   "service_tier": "standard",
#   "system_fingerprint": "fp_bc33001493",
#   "object": "chat.completion",
#   "usage": {
#     "completion_tokens": 271,
#     "prompt_tokens": 58,
#     "total_tokens": 329
#   }
# }
# Status: ✅ WORKS - reasoning_effort parameter accepted, shows detailed reasoning

# Test 3: Tools Parameter (Function Calling)
echo "Test 3: Tools Parameter (Function Calling)"
curl -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"$PRIMARY_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"What is the weather like in New York City? Use the get_weather function.\"}
    ],
    \"tools\": [
      {
        \"type\": \"function\",
        \"function\": {
          \"name\": \"get_weather\",
          \"description\": \"Get weather information for a location\",
          \"parameters\": {
            \"type\": \"object\",
            \"properties\": {
              \"location\": {
                \"type\": \"string\",
                \"description\": \"The city and state, e.g. San Francisco, CA\"
              },
              \"unit\": {
                \"type\": \"string\",
                \"enum\": [\"celsius\", \"fahrenheit\"],
                \"description\": \"Temperature unit\"
              }
            },
            \"required\": [\"location\"]
          }
        }
      }
    ],
    \"max_completion_tokens\": 1024
  }" | jq '.'
#
# Response:
# {
#   "id": "chatcmpl-c09750a8",
#   "choices": [
#     {
#       "finish_reason": "stop",
#       "index": 0,
#       "message": {
#         "content": "<reasoning>We need to call get_weather function with location: New York City. Also unit is optional. Let's call.</reasoning>{\n  \"location\": \"New York City, NY\",\n  \"unit\": \"fahrenheit\"\n}",
#         "role": "assistant"
#       }
#     }
#   ],
#   "created": 1754495022,
#   "model": "openai.gpt-oss-120b-1:0",
#   "service_tier": "standard",
#   "system_fingerprint": "fp_bc33001493",
#   "object": "chat.completion",
#   "usage": {
#     "completion_tokens": 47,
#     "prompt_tokens": 28,
#     "total_tokens": 75
#   }
# }
# Status: ❌ PARTIAL - Model understands tools but returns JSON instead of tool_calls format

# Test 4: Tool Choice Parameter
echo "Test 4: Tool Choice Parameter"
curl -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"$PRIMARY_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Get weather for Miami\"}
    ],
    \"tools\": [
      {
        \"type\": \"function\",
        \"function\": {
          \"name\": \"get_weather\",
          \"description\": \"Get weather information\",
          \"parameters\": {
            \"type\": \"object\",
            \"properties\": {
              \"location\": {\"type\": \"string\"}
            },
            \"required\": [\"location\"]
          }
        }
      }
    ],
    \"tool_choice\": {\"type\": \"function\", \"function\": {\"name\": \"get_weather\"}},
    \"max_completion_tokens\": 512
  }" | jq '.'
#
# Response:
# {
#   "id": "chatcmpl-95839a6c",
#   "choices": [
#     {
#       "finish_reason": "stop",
#       "index": 0,
#       "message": {
#         "content": "<reasoning>The user wants get weather for Miami. We have function get_weather that takes location string. So we need to call function.</reasoning>{\n  \"location\": \"Miami\"\n}",
#         "role": "assistant"
#       }
#     }
#   ],
#   "created": 1754495079,
#   "model": "openai.gpt-oss-120b-1:0",
#   "service_tier": "standard",
#   "system_fingerprint": "fp_bc33001493",
#   "object": "chat.completion",
#   "usage": {
#     "completion_tokens": 44,
#     "prompt_tokens": 16,
#     "total_tokens": 60
#   }
# }
# Status: ❌ PARTIAL - tool_choice parameter accepted but still returns JSON instead of tool_calls

# Test 5: Response Format Parameter (JSON Schema)
echo "Test 5: Response Format Parameter (JSON Schema)"
curl -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"$PRIMARY_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Generate a person profile with name, age, and occupation\"}
    ],
    \"response_format\": {
      \"type\": \"json_schema\",
      \"json_schema\": {
        \"name\": \"person_profile\",
        \"schema\": {
          \"type\": \"object\",
          \"properties\": {
            \"name\": {\"type\": \"string\"},
            \"age\": {\"type\": \"integer\"},
            \"occupation\": {\"type\": \"string\"}
          },
          \"required\": [\"name\", \"age\", \"occupation\"]
        }
      }
    },
    \"max_completion_tokens\": 512
  }" | jq '.'
#
# Response:
# {
#   "error": {
#     "message": "{\"error\":{\"message\":\"The 'response_format' parameter is not supported\",\"type\":\"invalid_request_error\",\"param\":null,\"code\":\"unsupported_parameter\"}}",
#     "type": "invalid_request_error",
#     "param": null,
#     "code": "validation_error"
#   }
# }
# Status: ❌ NOT SUPPORTED - response_format parameter not supported

# Test 6: Max Tokens vs Max Completion Tokens
echo "Test 6: Max Tokens vs Max Completion Tokens"
curl -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"$PRIMARY_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Write a short poem about coding\"}
    ],
    \"max_tokens\": 100
  }" | jq '.'
#
# Response:
# {
#   "error": {
#     "message": "{\"error\":{\"message\":\"The 'max_tokens' parameter is not supported, use 'max_completion_tokens' instead\",\"type\":\"invalid_request_error\",\"param\":null,\"code\":\"unsupported_parameter\"}}",
#     "type": "invalid_request_error",
#     "param": null,
#     "code": "validation_error"
#   }
# }
# Status: ❌ PARAMETER NAMING ISSUE - Must use max_completion_tokens instead of max_tokens

# Test 7: Nova Model Compatibility (Should Fail - OpenAI endpoint only supports OpenAI OSS models)
echo "Test 7: Nova Model Compatibility (Should Fail - OpenAI endpoint only supports OpenAI OSS models)"
curl -X POST "$OPENAI_BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"$NOVA_MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Hello\"}
    ],
    \"max_completion_tokens\": 100
  }" | jq '.'
#
# Response:
# {
#   "error": {
#     "message": "The model doesn't exist or doesn't support this API. Retry your request with a different model ID.",
#     "type": "not_found_error",
#     "param": null,
#     "code": "model_not_found"
#   }
# }
# Status: ✅ EXPECTED FAILURE - Nova model correctly rejected (OpenAI endpoint only supports OpenAI OSS models)
