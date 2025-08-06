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
    
self.ROUTER_PROCESS = "9I9F1IHS94oUABzKclMW8f2oj7_6_X9zGA_fnMZ_AzY"

self._handlers_initialized = false
self._callbacks = {}

function self.initialize()
        if self._handlers_initialized then return end
        
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
        local complete_reference = ao.id .. "-" .. reference
        
        -- Create task entry for tracking
        ApusAI_Tasks[complete_reference] = {
            data = "",
            session = options.session or "",
            attestation = "",
            reference = reference,
            prompt = prompt,
            status = "processing",
            starttime = os.time(),
            endtime = nil
        }
        DebugPrint("DEBUG: Task created with status 'processing': " .. complete_reference)
        
        if callback then
            self._callbacks[complete_reference] = callback
            DebugPrint("DEBUG: Callback stored for: " .. complete_reference)
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
        
        DebugPrint("DEBUG : AI inference request sent - Reference: " .. complete_reference)
        return complete_reference
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
        local reference = msg.Tags["X-Reference"] or ""
        DebugPrint("DEBUG: Response received with reference: " .. reference)
        
        -- Check if this is an error response
        if msg.Tags["Code"] and msg.Tags["Code"] == "Error" then
            local error_message = msg.Tags["Message"] or "Unknown error"
            DebugPrint("DEBUG: Error response received - Code: " .. msg.Tags["Code"] .. ", Message: " .. error_message)
            
            -- For error responses, server returns original reference, but we store callbacks with complete reference
            local complete_reference = ao.id .. "-" .. reference
            
            -- Update task status to failed
            if ApusAI_Tasks[complete_reference] then
                ApusAI_Tasks[complete_reference].status = "failed"
                ApusAI_Tasks[complete_reference].error_message = error_message
                ApusAI_Tasks[complete_reference].error_code = msg.Tags["Code"]
                ApusAI_Tasks[complete_reference].endtime = os.time()
                DebugPrint("DEBUG: Task marked as 'failed': " .. complete_reference)
            end
            
            -- Call callback with error
            if complete_reference and self._callbacks[complete_reference] then
                local callback = self._callbacks[complete_reference]
                self._callbacks[complete_reference] = nil
                callback({
                    code = msg.Tags["Code"],
                    message = error_message
                }, nil)
            else
                DebugPrint("DEBUG: No callback found for reference: " .. complete_reference)
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
        local attestation = ""
        if decoded_data.attestation and type(decoded_data.attestation) == "table" then
            -- The attestation is nested, try to extract the JWT token
            if decoded_data.attestation[1] and decoded_data.attestation[1][2] then
                attestation = decoded_data.attestation[1][2]
            end
        end
        
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