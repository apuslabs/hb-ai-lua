-- ApusAI SDK Test Functions
-- Demonstrates how to use the ApusAI module for AI inference

local ApusAI = require('apus-ai-test')
ApusAI_Debug = true
-- Test 1: Simple inference (matches README exactly)
function Test1_simple_inference()
    print("=== Test 1: Simple Inference ===")
    print("Prompt: 'How are you?'")
    print("---")
    ApusAI.infer("How are you?")
    print("Waiting for response...")
end

-- Test 2: Inference with options and callback
function Test2_advanced_inference()
    print("=== Test 2: Advanced Inference ===")
    print("Prompt: 'Translate the following to French: 'The future is decentralized.'")
    local prompt = "Translate the following to French: 'The future is decentralized.'"
    local options = [[{"max_tokens":512}]]
    print("Options: " .. options)
    local taskRef = ApusAI.infer(prompt, options, function(err, res)
        if err then
            print("Error: " .. err.message)
            return
        end
        print("Attestation: " .. res.attestation)
        print("Reference: " .. res.reference)
        print("Session ID for follow-up: " .. res.session)
        print("Translation received: " .. res.data)
    end)
    print("Task Reference: " .. taskRef)
end

-- Test 3: Just prompt with callback
function Test3_prompt_with_callback()
    print("=== Test 3: Prompt with Callback ===")
    ApusAI.infer("Hello, how are you?", nil, function(err, res)
        if err then
            print("Error: " .. err.message)
            return
        end
        print("Response: " .. res.data)
    end)
end


-- Test 4.5: Get balance info with callback
function Test4_get_balance()
    print("=== Test 4: Get Balance ===")
    ApusAI.getBalance(function(err, balance)
        if err then
            print("❌ Failed to get balance: " .. err.message)
            return
        end
        
        print("✅ Balance retrieved successfully:")
        print("✅ Account: " .. balance.account)
        print("✅ Balance: " .. balance.balance .. " Credits")
        print("✅ Data: " .. balance.data)
    end)
end

-- Test 5: Get balance info without callback (auto-print)
function Test5_get_balance_no_callback()
    print("=== Test 5: Get Balance without Callback ===")
    print("Should automatically print balance to console...")
    ApusAI.getBalance()
    print("Balance request sent (will auto-print response)")
end

-- Test 5: Test getTaskStatus function
function Test5_get_task_status()
    print("=== Test 5: Get Task Status ===")
    local taskRef = "test-reference-123"
    
    ApusAI.getTaskStatus(taskRef, function(err, status)
        if err then
            print("Error getting task status: " .. err.message)
            return
        end
        
        print("Task Status: " .. status.status)
        print("Message: " .. status.message)
    end)
end

-- Test 7: Test session handling - Simple conversation
function Test7_session_handling()
    print("=== Test 7: Session Handling ===")
    
    -- Simple state for 2-question conversation
    local state = {
        session = "Test-session1",
        currentQuestion = 1
    }
    
    local questions = {
        "What is the weather?",
        "What was my last question?"
    }
    
    -- Forward declare askQuestion
    local askQuestion
    
    local function handleResponse(err, res)
        if err then
            print("❌ Session Error: " .. err.message)
            return
        end
        
        print("🤖 AI: " .. res.data)
        print("📍 Session: " .. (res.session or "none"))
        
        -- Save session for next question
        state.session = res.session
        state.currentQuestion = state.currentQuestion + 1
        
        -- Ask next question if available
        if state.currentQuestion <= #questions then
            askQuestion()
        else
            print("✅ Session conversation completed!")
        end
    end
    
    askQuestion = function()
        local question = questions[state.currentQuestion]
        print("👤 You: " .. question)
        
        local options = {
            session = state.session -- Pass current session (nil for first question)
        }
        
        ApusAI.infer(question, options, handleResponse)
    end
    
    -- Start the conversation
    askQuestion()
end

-- Test 8: Test error handling for invalid inputs
function Test8_error_handling()
    print("=== Test 8: Error Handling ===")
    
    -- Test empty prompt
    local success, err = pcall(function()
        ApusAI.infer("", nil, function(err, res)
            print("This should not be called")
        end)
    end)
    
    if not success then
        print("✅ Correctly caught empty prompt error: " .. err)
    else
        print("❌ Should have caught empty prompt error")
    end
    
    -- Test nil prompt
    success, err = pcall(function()
        ApusAI.infer(nil, nil, function(err, res)
            print("This should not be called")
        end)
    end)
    
    if not success then
        print("✅ Correctly caught nil prompt error: " .. err)
    else
        print("❌ Should have caught nil prompt error")
    end
    
end

-- Test 9: Test custom reference
function Test9_custom_reference()
    print("=== Test 9: Custom Reference ===")
    local customRef = "custom-ref-" .. tostring(os.time())
    local taskRef = ApusAI.infer("Tell me a joke", {
        reference = customRef
    }, function(err, res)
        if err then
            print("Error: " .. err.message)
            return
        end
        
        print("Response: " .. res.data)
        print("Custom final reference: " .. res.reference)
    end)
    
    print("Custom reference test submitted. Task Reference: " .. taskRef)
    print("the final reference should be: " .. ao.id .. "-" .. customRef)
end






