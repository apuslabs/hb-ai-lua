# apus-ailib-Beta

### `ApusAI.infer(prompt, options, callback)`

Submits an AI inference request. This function is asynchronous.

- **`prompt`** (`string`): **Required.** The text prompt to send to the AI model.
- **`options`** (`table`): **Optional.** A table of parameters to customize the inference.
    - `max_tokens` (`number`): The maximum number of tokens to generate. Defaults to `2000`.
    - `temp` (`number`): The temperature for generation (e.g., `0.7`).
    - `top_p` (`number`): The top-p sampling value (e.g., `0.5`).
    - `system_prompt` (`string`): A system message to guide the model's behavior.
    - `session` (`string`): A session ID from a previous response to continue a conversation.
    - `reference` (`string`): A custom unique ID for the request. If omitted, a unique ID is generated automatically.
- **`callback(err, res)`** (`function`): **Optional.** A function that will be called with the result. If omitted, the result is printed to the console.
    - **`err`** (`table`): An error object if the request fails, otherwise `nil`. The object has the shape `{ code = "ERROR_CODE", message = "Error details" }`.
    - **`res`** (`table`): A result object on success, otherwise `nil`. The object has the shape:
        
        ```lua
        {
          data = "The AI's text response.",
          session = "The-session-id-for-this-conversation",
          attestation = "The-gpu-attestation-string",
          reference = "The-unique-request-reference"
        }
        
        ```
        
- **Returns**: `string` - A unique `taskRef` for this request, which can be used with `getTaskStatus`.
