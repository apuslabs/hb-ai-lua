# Apus AI Lua SDK

A Lua library for `ao` processes to interact with the Apus AI Process. This SDK simplifies sending inference requests and handling responses, enabling seamless integration of AI capabilities into your `ao` applications.

## Features

-   **Simple Inference API**: A straightforward interface to send prompts for AI inference.
-   **Asynchronous Operations**: Supports callbacks for handling asynchronous AI responses.
-   **Easy Integration**: Designed for easy use within the `ao` environment.
-   **Task Management**: Functions to query the status of inference tasks.

## Installation

1.  Install `APM` if you haven't already: `.load-blueprint apm`
2.  Install the Apus AI library: `apm.install "@apus/ai"`

## Usage

Here is a basic example of how to use the Apus AI SDK in your `ao` process.

````lua
-- Require the ApusAI module
local ApusAI = require('apus-ai')

-- Initialize the SDK (optional, called automatically on first use)
ApusAI.initialize()

-- ---
-- Example 1: Simple Inference
-- ---
print("Sending a simple inference request...")
ApusAI.infer("How are you today?")


-- ---
-- Example 2: Advanced Inference with Options and Callback
-- ---
local prompt = "Translate the following to French: 'The future is decentralized.'"
local options = { max_tokens = 512 }

print("Sending an advanced inference request with a callback...")
ApusAI.infer(prompt, options, function(err, res)
    if err then
        print("Error receiving response: " .. err.message)
        return
    end
    print("Received AI Response: " .. res)
end)