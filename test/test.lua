-- ApusAI SDK Test Functions
-- Demonstrates how to use the ApusAI module for AI inference

-- Load the ApusAI module (assuming json is available)
local json = require('json')
local ApusAI = require('apus-ai-test')(json)

-- Test 1: Simple inference (matches README exactly)
function Test1_simple_inference()
    print("=== Test 1: Simple Inference ===")
    print("Prompt: 'What is Arweave?'")
    print("---")
    ApusAI.infer("What is Arweave?")
    print("Waiting for response...")
end

-- Test 2: Inference with options and callback
function Test2_advanced_inference()
    print("=== Test 2: Advanced Inference ===")
    local prompt = "Translate the following to French: 'The future is decentralized.'"
    local options = {
        temp = 0.5,
    }

    local taskRef = ApusAI.infer(prompt, options, function(err, res)
        if err then
            print("Error: " .. err.message)
            return
        end
        print("Response: " .. res)
        print("Translation received: " .. res.data)
        print("Session ID for follow-up: " .. res.session)
    end)

    print("Inference task submitted. Task Reference: " .. taskRef)
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

-- Test 4: Get service info
function Test4_get_info()
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

-- Test 6: Test setRouter function
function Test6_set_router()
    print("=== Test 6: Set Router ===")
    local newRouter = "new-router-process-id"
    
    print("Original router: " .. ApusAI.ROUTER_PROCESS)
    ApusAI.setRouter(newRouter)
    print("New router: " .. ApusAI.ROUTER_PROCESS)
    
    -- Reset to original
    ApusAI.setRouter("QwaPu_yGGKtzfRQ9EDdkPulLrCGOIpbIqc40PvFq6YU")
    print("Reset router: " .. ApusAI.ROUTER_PROCESS)
end

-- Test 7: Test session handling
function Test7_session_handling()
    print("=== Test 7: Session Handling ===")
    local sessionId = "test-session-" .. tostring(os.time())
    
    local taskRef = ApusAI.infer("What is the weather like?", {
        session = sessionId,
        max_tokens = 30
    }, function(err, res)
        if err then
            print("Error: " .. err.message)
            return
        end
        
        print("Response: " .. res.data)
        print("Session: " .. res.session)
        print("Session matches: " .. tostring(res.session == sessionId))
    end)
    
    print("Session test submitted with reference: " .. taskRef)
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
    
    -- Test invalid callback for getInfo
    success, err = pcall(function()
        ApusAI.getInfo(nil)
    end)
    
    if not success then
        print("✅ Correctly caught invalid callback error: " .. err)
    else
        print("❌ Should have caught invalid callback error")
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
        print("Custom reference: " .. res.reference)
        print("Reference matches: " .. tostring(res.reference == customRef))
    end)
    
    print("Custom reference test submitted. Task Reference: " .. taskRef)
end

-- Function to run all tests
function Run_all()
    print("🚀 Starting ApusAI SDK Tests")
    print("=" .. string.rep("=", 50))
    print()

    Test1_simple_inference()
    print()

    Test2_advanced_inference()
    print()

    Test3_prompt_with_callback()
    print()

    Test4_get_info()
    print()

    Test5_get_task_status()
    print()

    Test6_set_router()
    print()

    Test7_session_handling()
    print()

    Test8_error_handling()
    print()

    Test9_custom_reference()
    print()

    print("=" .. string.rep("=", 50))
    print("✅ All tests completed!")
end





