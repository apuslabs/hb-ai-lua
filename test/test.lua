-- ApusAI SDK Test Functions
-- Demonstrates how to use the ApusAI module for AI inference

-- Load the ApusAI module (assuming json is available)
local json = require('json')
local ApusAI = require('apus-ai')(json)



-- Test 1: Simple inference (matches README exactly)
function test1_simple_inference()
    print("=== Test 1: Simple Inference ===")
    print("Prompt: 'What is Arweave?'")
    print("---")
    
    local taskRef = ApusAI.infer("What is Arweave?", function(err, res)
        if err then
            print("❌ TEST 1 FAILED - Error: " .. err.message)
            return
        end
        print("📝 AI Response: " .. res.data)
        print("🔗 Reference: " .. res.reference)
        print("🔐 Attestation: " .. res.attestation)
        if res.session and res.session ~= "" then
            print("💬 Session: " .. res.session)
        end
        print("--- Test 1 Complete ---")
    end)
    
    print("📤 Request submitted with task reference: " .. taskRef)
end

-- Test 2: Inference with options and callback
function test2_advanced_inference()
    print("=== Test 2: Advanced Inference ===")
    local prompt = "Translate the following to French: 'The future is decentralized.'"
    local options = {
        max_tokens = 50,
        temp = 0.5,
        system_prompt = "You are a helpful translation assistant."
    }

    local taskRef = ApusAI.infer(prompt, options, function(err, res)
        if err then
            print("Error: " .. err.message)
            return
        end
        
        print("Translation received: " .. res.data)
        print("Session ID for follow-up: " .. res.session)
        print("Attestation: " .. res.attestation)
    end)

    print("Inference task submitted. Task Reference: " .. taskRef)
end

-- Test 3: Just prompt with callback
function test3_prompt_with_callback()
    print("=== Test 3: Prompt with Callback ===")
    ApusAI.infer("Hello, how are you?", function(err, res)
        if err then
            print("Error: " .. err.message)
            return
        end
        print("Response: " .. res.data)
    end)
end

-- Test 4: Get service info
function test4_get_info()
    print("=== Test 4: Get Service Info ===")
    ApusAI.getInfo(function(err, info)
        if err then
            print("Failed to get info: " .. err.message)
            return
        end
        
        print("Price: " .. info.price .. " Armstrongs")
        print("Workers: " .. info.worker_count)
        print("Pending: " .. info.pending_tasks)
    end)
end




