--------------------------------------------------------------------------------
-- ApusAI Module
-- Provides simple AI inference API for the APUS AI Inference Service
-- • Send inference requests via token transfers
-- • Receive and process AI responses
-- • Get service information and status
--------------------------------------------------------------------------------
ApusAI_Debug = false
ApusAI_Tasks = ApusAI_Tasks or {}
local json = require("json")

-- Create the ApusAI module instance directly
local self = {}

-- Blue color function for SDK prints
local function DebugPrint(text)
    if ApusAI_Debug then
        print("\27[34m" .. text .. "\27[0m")
    end
end
    
self.ROUTER_PROCESS = "D0na6AspYVzZnZNa7lQHnBt_J92EldK_oFtEPLjIexo"

self._handlers_initialized = false
self._callbacks = {}

function self.initialize()
        if self._handlers_initialized then return end
        
        print("╔" .. string.rep("═", 58) .. "╗")
        print("║" .. string.rep(" ", 18) .. "🚀 APUS AI SDK 🚀" .. string.rep(" ", 18) .. "║")
        print("║" .. string.rep(" ", 16) .. "Welcome to the Future!" .. string.rep(" ", 16) .. "║")
        print("╠" .. string.rep("═", 58) .. "╣")
        print("║  ✅ ApusAI SDK Initialized successfully!             ║")
        print("║                                                      ║")
        print("║  🎁 NEW USER BONUS: 5 FREE inference credits!       ║")
        print("║                                                      ║")
        print("║  🔧 How to create an instance:                       ║")
        print("║      ApusAI = require('apus-ai-test')                ║")
        print("║                                                      ║")
        print("║  📋 Available Methods:                               ║")
        print("║    🧠 ApusAI.infer() - AI inference & chat          ║")
        print("║    💰 ApusAI.getBalance() - Check your credits      ║")
        print("║    📊 ApusAI.getTaskStatus() - Monitor tasks        ║")
        print("║                                                      ║")
        print("║  💡 Pro Tip: Enable debug logs with:                ║")
        print("║      ApusAI_Debug = true                             ║")
        print("║                                                      ║")
        print("║  🎯 Ready to build amazing AI applications!         ║")
        print("╚" .. string.rep("═", 58) .. "╝")
        
        Handlers.add(
            "apus-ai-inference-response",
            Handlers.utils.hasMatchingTag("Action", "Infer-Response"),
            function(msg)
                self._handleInferenceResponse(msg)
            end
        )
        
        
        Handlers.add(
            "apus-ai-balance-response",
            Handlers.utils.hasMatchingTag("Action", "Balance-Response"),
            function(msg)
                self._handleBalanceResponse(msg)
            end
        )
        
        self._handlers_initialized = true
    end
    
    function self.generateReference()
        return "apus-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
    end
    
    function self.setRouter(routerProcess)
        if routerProcess then self.ROUTER_PROCESS = routerProcess end
    end
    
    function self.infer(prompt, options, callback)
        self.initialize()
        -- Input validation
        assert(type(prompt) == "string" and #prompt > 0, "Prompt must be a non-empty string")
        
        -- Handle optional parameters
        options = options or {}
        
        -- Generate unique reference
        local reference = options.reference or self.generateReference()
        
        -- Create task entry for tracking
        ApusAI_Tasks[reference] = {
            data = "",
            session = options.session or "",
            attestation = "",
            reference = reference,
            prompt = prompt,
            status = "processing",
            starttime = os.time(),
            endtime = nil
        }
        DebugPrint("DEBUG: Task created with status 'processing': " .. reference)
        
        if callback then
            self._callbacks[reference] = callback
            DebugPrint("DEBUG: Callback stored for: " .. reference)
        else
            DebugPrint("DEBUG: No callback provided")
        end

        local tags = {
            ["Action"] = "Infer",
            ["X-Prompt"] = prompt,
            ["X-Reference"] = reference,
        }
        
        -- Add session if provided
        if options.session then
            tags["X-Session"] = options.session
        end
        
        -- Only add X-Options if there are actual options (excluding session and reference)
        local hasOptions = false
        for key, value in pairs(options) do
            if key ~= "session" and key ~= "reference" then
                hasOptions = true
                break
            end
        end
        
        if hasOptions then
            tags["X-Options"] = json.encode(options)
        end
        DebugPrint("DEBUG: Tags: " .. json.encode(tags))
        ao.send({
            Target = self.ROUTER_PROCESS,
            Tags = tags
        })
        
        DebugPrint("DEBUG : AI inference request sent - Reference: " .. reference)
        return reference
    end
    

    
    function self.getBalance(callback)
        -- Ensure handlers are initialized
        self.initialize()
        
        -- Callback is optional - if not provided, result will be printed
        if callback then
            assert(type(callback) == "function", "Callback must be a function")
        end
        
        self._balance_callback = callback
        
        ao.send({
            Target = self.ROUTER_PROCESS,
            Action = "Balance"
        })
    end
    
    ----------------------------------------------------------------------------
    -- getTaskStatus(taskRef, callback)
    -- Retrieves the cached status of a previously submitted task
    --
    -- Arguments:
    --   taskRef  : The task reference returned by the infer function
    --   callback : Function to call with task status results (required)
    ----------------------------------------------------------------------------
    function self.getTaskStatus(taskRef, callback)
        self.initialize()
        assert(type(taskRef) == "string", "Task reference is required")
        
        -- Allow callback to be nil
        if callback then
            assert(type(callback) == "function", "Callback must be a function")
        end
    
        local task = ApusAI_Tasks[taskRef]
        
        if task then
            local result = {
                data = task.data,
                session = task.session,
                attestation = task.attestation,
                reference = task.reference,
                prompt = task.prompt,
                status = task.status,
                starttime = task.starttime,
                endtime = task.endtime,
            }
            
            if callback then
                callback(nil, result)
            else
                DebugPrint("DEBUG: Task status for " .. taskRef .. " - Status: " .. task.status .. ", Prompt: " .. task.prompt)
            end
        else
            local error_result = {
                status = "not_found",
                message = "Task with reference '" .. taskRef .. "' not found"
            }
            
            if callback then
                callback(nil, error_result)
            else
                DebugPrint("DEBUG: Task not found: " .. taskRef)
            end
        end
    end
    
    

    
    function self._handleInferenceResponse(msg)
        local session = msg.Tags["X-Session"] or ""
        local reference = msg.Tags["X-Reference"] or msg.reference
        DebugPrint("DEBUG: Response received with reference: " .. reference)
        
        -- Check if this is an error response
        if msg.Tags["Code"] then
            local error_message = msg.Tags["Message"] or "Unknown error"
            DebugPrint("DEBUG: Error response received - Code: " .. msg.Tags["Code"] .. ", Message: " .. error_message)

            -- Update task status to failed
            if ApusAI_Tasks[reference] then
                ApusAI_Tasks[reference].status = "failed"
                ApusAI_Tasks[reference].error_message = error_message
                ApusAI_Tasks[reference].error_code = msg.Tags["Code"]
                ApusAI_Tasks[reference].endtime = os.time()
                DebugPrint("DEBUG: Task marked as 'failed': " .. reference)
            end
            
            -- Call callback with error
            if reference and self._callbacks[reference] then
                local callback = self._callbacks[reference]
                self._callbacks[reference] = nil
                callback({
                    code = msg.Tags["Code"],
                    message = error_message
                }, nil)
            else
                DebugPrint("DEBUG: No callback found for reference: " .. reference)
                DebugPrint("DEBUG: Error response from SDK: " .. error_message)
            end
            return
        end
        
        -- Decode JSON from msg.Data for success responses
        local decoded_data = {}
        if msg.Data and msg.Data ~= "" then
            local success, result = pcall(json.decode, msg.Data)
            if success then
                decoded_data = result
            else
                DebugPrint("DEBUG : JSON decode FAILED: " .. tostring(result))
            end
        end
        
        -- Extract attestation (it's a complex nested structure)
        local attestation = json.encode(decoded_data.attestation)
        local response = {
            data = decoded_data.result or msg.Data or "",  -- Note: "result" not "results"
            session = session,
            attestation = attestation,
            reference = reference
        }

        -- Update task status to success and populate data
        if ApusAI_Tasks[reference] then
            ApusAI_Tasks[reference].data = response.data
            ApusAI_Tasks[reference].session = response.session
            ApusAI_Tasks[reference].attestation = response.attestation
            ApusAI_Tasks[reference].status = "success"
            DebugPrint("DEBUG: Task updated to 'success': " .. reference)
        end

        if reference and self._callbacks[reference] then
            local callback = self._callbacks[reference]
            self._callbacks[reference] = nil
            -- Call callback with success
            callback(nil, response)
        else
            DebugPrint("DEBUG : AI Response From SDK: " .. response.data)
        end
    end
    
    
    function self._handleBalanceResponse(msg)
        local balance = {
            balance = msg.Tags["Balance"] or msg.Data or "0",
            account = msg.Tags["Account"] or "",
            data = msg.Data or "0"
        }
        
        -- Call callback if exists
        if self._balance_callback then
            local callback = self._balance_callback
            self._balance_callback = nil
            callback(nil, balance)
        else
            DebugPrint("DEBUG : Balance Info - Account: " .. balance.account .. ", Balance: " .. balance.balance)
        end
    end
    

    
-- Initialize the module
self.initialize()

-- Return the module instance directly
return self 