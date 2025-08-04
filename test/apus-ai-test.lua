--------------------------------------------------------------------------------
-- ApusAI Module
-- Provides simple AI inference API for the APUS AI Inference Service
-- • Send inference requests via token transfers
-- • Receive and process AI responses
-- • Get service information and status
--------------------------------------------------------------------------------
local function ApusAI(json)
    local self = {}
    
    -- Blue color function for SDK prints
    local function DebugPrint(text)
        print("\27[34m" .. text .. "\27[0m")
    end
    
    self.ROUTER_PROCESS = "QwaPu_yGGKtzfRQ9EDdkPulLrCGOIpbIqc40PvFq6YU"
    
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
            "apus-ai-info-response",
            Handlers.utils.hasMatchingTag("Action", "Info-Response"),
            function(msg)
                self._handleInfoResponse(msg)
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
        callback = callback or function(err, res)
            if err then
                DebugPrint("Error: " .. err.message)
            else
                DebugPrint("AI Response in callback: " .. res.data)
            end
        end
        
        -- Generate unique reference
        local reference = options.reference or self.generateReference()
        
        if callback then
            self._callbacks[reference] = callback
        end

        -- Encode options to JSON
        local options_json = ""
        if next(options) then
            options_json = json.encode(options)
            DebugPrint("DEBUG: JSON options being sent: " .. options_json)
        end

        ao.send({
            Target = self.ROUTER_PROCESS,
            Action = "Infer",
            ["X-Prompt"] = prompt,
            ["X-Session"] = options.session or "",
            ["X-Reference"] = reference,
            ["X-Options"] = options_json
        })
        
        DebugPrint("AI inference request sent - Reference: " .. reference)
        return reference
    end
    
    function self.getInfo(callback)
        -- Ensure handlers are initialized
        self.initialize()
        assert(type(callback) == "function", "Callback function is required")
        
        self._info_callback = callback
        
        ao.send({
            Target = self.ROUTER_PROCESS,
            Action = "Info"
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
        assert(type(callback) == "function", "Callback function is required")
        
        local status = {
            status = "unknown",
            message = "Task status not available in current implementation"
        }
        
        callback(nil, status)
    end
    

    
    function self._handleInferenceResponse(msg)
        local session = msg.Tags["X-Session"] or ""
        local reference = msg.Tags["X-Reference"] or ""
        
        local response = {
            data = msg.Data or "",
            session = session,
            attestation = msg.Tags["X-Attestation"] or "",
            reference = reference
        }
        
        if reference and self._callbacks[reference] then
            local callback = self._callbacks[reference]
            self._callbacks[reference] = nil
            callback(nil, response)
        else
            DebugPrint("AI Response From SDK: " .. response.data)
        end
    end
    

    
    function self._handleInfoResponse(msg)
        local info = {
            price = tonumber(msg.Tags["price"]) or 0,
            worker_count = tonumber(msg.Tags["worker_count"]) or 0,
            pending_tasks = tonumber(msg.Tags["pending_tasks"]) or 0
        }
        
        -- Call callback if exists
        if self._info_callback then
            local callback = self._info_callback
            self._info_callback = nil
            callback(nil, info)
        else
            DebugPrint("Service Info - Price: " .. info.price .. ", Workers: " .. info.worker_count .. ", Pending: " .. info.pending_tasks)
        end
    end
    

    
    self.initialize()
    return self
end

return ApusAI 