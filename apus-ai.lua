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
-- Box formatting helpers
local BOX_W = 58
local function box_top()
    print("╔" .. string.rep("═", BOX_W) .. "╗")
end
local function box_sep()
    print("╠" .. string.rep("═", BOX_W) .. "╣")
end
local function box_bottom()
    print("╚" .. string.rep("═", BOX_W) .. "╝")
end
-- Width-aware helpers to keep right edge straight with emojis/UTF-8
local function char_width(cp)
    if cp <= 127 then return 1 end
    -- Assume non-ASCII are wide; good enough for emojis and CJK
    return 2
end
local function display_width(s)
    local w = 0
    for _, cp in utf8.codes(s) do
        w = w + char_width(cp)
    end
    return w
end
local function truncate_to_width(s, maxw)
    local out = {}
    local w = 0
    for _, cp in utf8.codes(s) do
        local cw = char_width(cp)
        if w + cw > maxw then break end
        table.insert(out, utf8.char(cp))
        w = w + cw
    end
    return table.concat(out), w
end
local function line_left(text)
    local s = tostring(text or "")
    local w = display_width(s)
    if w > BOX_W then s, w = truncate_to_width(s, BOX_W) end
    print("║" .. s .. string.rep(" ", BOX_W - w) .. "║")
end
local function line_center(text)
    local s = tostring(text or "")
    local w = display_width(s)
    if w > BOX_W then s, w = truncate_to_width(s, BOX_W) end
    local left = math.floor((BOX_W - w) / 2)
    local right = BOX_W - w - left
    print("║" .. string.rep(" ", left) .. s .. string.rep(" ", right) .. "║")
end
    
self.ROUTER_PROCESS = "ZIc9924GI_wMzPayOZAgVjaxasNq1rIQwdSZseGoh7M"

self._handlers_initialized = false
self._callbacks = {}

function self.initialize()
        if self._handlers_initialized then return end
        
        box_top()
        line_center("🚀 APUS AI SDK 🚀")
        line_center("Welcome to the Future!")
        box_sep()
        line_left("  ✅ ApusAI SDK Initialized successfully!")
        line_left("")
        line_left("  🎁 NEW USER BONUS: 5 FREE inference credits!")
        line_left("")
        line_left("  🔧 How to create an instance:")
        line_left("      ApusAI = require('apus-ai-test')")
        line_left("")
        line_left("  📋 Available Methods:")
        line_left("    🧠 ApusAI.infer() - AI inference & chat")
        line_left("    💰 ApusAI.getBalance() - Check your credits")
        line_left("    📊 ApusAI.getTaskStatus() - Monitor tasks")
        line_left("")
        line_left("  💡 Pro Tip: Enable debug logs with:")
        line_left("      ApusAI_Debug = true")
        line_left("")
        line_left("  🎯 Ready to build amazing AI applications!")
        box_bottom()
        
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
