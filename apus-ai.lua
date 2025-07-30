--------------------------------------------------------------------------------
-- ApusAI Module
-- Provides simple AI inference API for the APUS AI Inference Service
-- • Send inference requests via token transfers
-- • Receive and process AI responses
-- • Get service information and status
--------------------------------------------------------------------------------
local function ApusAI(json)
    
  -- Create a table to hold module functions and data
  local self = {}
  
  ----------------------------------------------------------------------------
  -- Default State Variables
  --   TOKEN_PROCESS   : APUS Token Process ID for payments
  --   ROUTER_PROCESS  : AI-Infer Router Process ID
  --   DEFAULT_PRICE   : Default price in Armstrongs per inference
  --   DEFAULT_OPTIONS : Default inference parameters
  ----------------------------------------------------------------------------
  self.TOKEN_PROCESS =  "AgDV_J8GcSIb6NSJKPjg48aX-7FoebesFQAaWSTpwyo"
  self.ROUTER_PROCESS = "S8jAWRuPlxmdZQOCxxvMsz0_GnLb_4wRWP4fGUhlZr4"
  self.DEFAULT_PRICE = "1000000000000"

  
  -- Internal state
  self._pending_requests = {}
  self._handlers_initialized = false
  
  ----------------------------------------------------------------------------
  -- initialize()
  -- Sets up handlers to listen for AI inference responses and info responses
  ----------------------------------------------------------------------------
  function self.initialize()
      if self._handlers_initialized then return end
      
      print("Initializing ApusAI Module2")
      
      -- Handler for AI inference responses
      Handlers.add(
          "apus-ai-inference-response",
          Handlers.utils.hasMatchingTag("Action", "AI-Infer-Response"),
          function(msg)
              self._handleInferenceResponse(msg)
          end
      )
      
      -- Handler for service info responses
      Handlers.add(
          "apus-ai-info-response",
          Handlers.utils.hasMatchingTag("Action", "AI-Info-Response"),
          function(msg)
              self._handleInfoResponse(msg)
          end
      )
      
      -- Handler for error responses
      Handlers.add(
          "apus-ai-error-response",
          Handlers.utils.hasMatchingTag("Action", "Error"),
          function(msg)
              print("Error response received: " .. (msg.Tags["Message"] or "Unknown error"))
              self._handleErrorResponse(msg)
          end
      )
      
      self._handlers_initialized = true
      print("ApusAI handlers registered")
  end
  
  ----------------------------------------------------------------------------
  -- generateReference()
  -- Creates a unique reference ID for tracking requests
  --
  -- Returns:
  --   A unique reference string
  ----------------------------------------------------------------------------
  function self.generateReference()
      return "apus-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
  end
  
  ----------------------------------------------------------------------------
  -- setConfig(tokenProcess, routerProcess, defaultPrice)
  -- Updates the module's configuration with new process IDs and pricing
  --
  -- Arguments:
  --   tokenProcess  : APUS Token Process ID
  --   routerProcess : AI-Infer Router Process ID  
  --   defaultPrice  : Default price per inference (optional)
  ----------------------------------------------------------------------------
  function self.setConfig(tokenProcess, routerProcess, defaultPrice)
      if tokenProcess then self.TOKEN_PROCESS = tokenProcess end
      if routerProcess then self.ROUTER_PROCESS = routerProcess end
      if defaultPrice then self.DEFAULT_PRICE = defaultPrice end
  end
  
  ----------------------------------------------------------------------------
  -- showConfig()
  -- Simple utility to log the current configuration values for debugging
  ----------------------------------------------------------------------------
  function self.showConfig()
      print("TOKEN_PROCESS: " .. self.TOKEN_PROCESS)
      print("ROUTER_PROCESS: " .. self.ROUTER_PROCESS)
      print("DEFAULT_PRICE: " .. self.DEFAULT_PRICE)
  end
  
  ----------------------------------------------------------------------------
  -- infer(prompt, options, callback)
  -- Sends an AI inference request via token transfer
  --
  -- Arguments:
  --   prompt   : The text prompt for AI inference (required)
  --   options  : Table of inference options (optional)
  --   callback : Function to call with results (optional)
  --
  -- Returns:
  --   Reference ID for tracking the request
  ----------------------------------------------------------------------------
  function self.infer(prompt, options, callback)
      -- Ensure handlers are initialized
      self.initialize()
      -- Input validation
      assert(type(prompt) == "string" and #prompt > 0, "Prompt must be a non-empty string")
      
      -- Handle optional parameters
      if type(options) == "function" then
          callback = options
          options = {}
      end
      options = options or {}
      
      -- Generate unique reference
      local reference = options.reference or self.generateReference()
      
      -- Store request context for response handling
      self._pending_requests[reference] = {
          callback = callback,
          timestamp = os.time(),
          session = options.session,
          type = "inference"
      }

      -- Send transfer to token process
      local send_result = ao.send({
          Target = self.TOKEN_PROCESS,
          Action = "Transfer",
          Recipient = self.ROUTER_PROCESS,
          Quantity =  self.DEFAULT_PRICE,
          ["X-Prompt"] = prompt,
          ["X-Session"] = options.session or "",
          ["X-Reference"] = reference
      })
      
      print("AI inference request sent - Reference: " .. reference)
      return reference
  end
  
  ----------------------------------------------------------------------------
  -- getInfo(callback)
  -- Requests current service information from the AI-Infer Router
  --
  -- Arguments:
  --   callback : Function to call with service info results (required)
  ----------------------------------------------------------------------------
  function self.getInfo(callback)
      -- Ensure handlers are initialized
      self.initialize()
      
      assert(type(callback) == "function", "Callback function is required")
      
      -- Generate reference for tracking
      local reference = self.generateReference()
      
      -- Store callback for response handling
      self._pending_requests[reference] = {
          callback = callback,
          timestamp = os.time(),
          type = "info"
      }
      
      -- Send info request to router
      local send_result = ao.send({
          Target = self.ROUTER_PROCESS,
          Action = "Info",
          ["X-Reference"] = reference
      })
      
      print("Service info request sent")
      return send_result
  end
  
  ----------------------------------------------------------------------------
  -- _handleInferenceResponse(msg)
  -- Internal handler for processing AI inference responses
  --
  -- Arguments:
  --   msg : The message containing the AI response
  ----------------------------------------------------------------------------
  function self._handleInferenceResponse(msg)
      local reference = msg.Tags["X-Reference"]
      print("Inference response received for reference: " .. reference)
      
      -- Get the pending request
      local pending_request = self._pending_requests[reference]
      if not pending_request then
          print("No pending request found for reference: " .. reference)
          return
      end
      
      -- Clean up the pending request
      self._pending_requests[reference] = nil
      
      -- Format response
      local response = {
          data = msg.Data or "",
          session = msg.Tags["X-Session"] or "",
          attestation = msg.Tags["X-Attestation"] or "",
          reference = reference
      }
      
      -- Call user callback or print result
      if pending_request.callback then
          pending_request.callback(nil, response)
      else
          print("AI Response: " .. response.data)
      end
  end
  
  ----------------------------------------------------------------------------
  -- _handleErrorResponse(msg)
  -- Internal handler for processing error responses
  --
  -- Arguments:
  --   msg : The message containing error information
  ----------------------------------------------------------------------------
  function self._handleErrorResponse(msg)
      local reference = msg.Tags["X-Reference"]
      if not reference or reference == "" then
          print("Error response without reference - cannot match to request")
          return
      end
      
      print("Error response received for reference: " .. reference)
      
      -- Get the pending request
      local pending_request = self._pending_requests[reference]
      if not pending_request then
          print("No pending request found for error reference: " .. reference)
          return
      end
      
      -- Clean up the pending request
      self._pending_requests[reference] = nil
      
      -- Create error object
      local error_obj = self._createError(
          msg.Tags["Code"] or "UNKNOWN_ERROR",
          msg.Tags["Message"] or "Unknown error occurred"
      )
      
      -- Add additional error details if available
      if msg.Tags["Details"] and msg.Tags["Details"] ~= "" then
          error_obj.details = msg.Tags["Details"]
      end
      
      -- Call user callback with error
      if pending_request.callback then
          pending_request.callback(error_obj, nil)
      else
          print("❌ Error (no callback): [" .. error_obj.code .. "] " .. error_obj.message)
      end
  end
  
  ----------------------------------------------------------------------------
  -- _handleInfoResponse(msg)
  -- Internal handler for processing service info responses
  --
  -- Arguments:
  --   msg : The message containing service information
  ----------------------------------------------------------------------------
  function self._handleInfoResponse(msg)
      -- Find the latest info request (since info responses don't have references)
      local latest_request = nil
      local latest_time = 0
      
      for ref, request in pairs(self._pending_requests) do
          if request.type == "info" and request.timestamp > latest_time then
              latest_request = request
              latest_time = request.timestamp
          end
      end
      
      if not latest_request then return end
      
      -- Clean up the request (remove all info requests to avoid duplicates)
      for ref, request in pairs(self._pending_requests) do
          if request.type == "info" then
              self._pending_requests[ref] = nil
          end
      end
      
      -- Format info response
      local info = {
          price = tonumber(msg.Tags["price"]) or 0,
          worker_count = tonumber(msg.Tags["worker_count"]) or 0,
          pending_tasks = tonumber(msg.Tags["pending_tasks"]) or 0
      }
      
      -- Call user callback
      if latest_request.callback then
          latest_request.callback(nil, info)
      end
  end
  
  ----------------------------------------------------------------------------
  -- _createError(code, message)
  -- Creates a standardized error object
  --
  -- Arguments:
  --   code    : Error code string
  --   message : Error message string
  --
  -- Returns:
  --   Error object with code and message fields
  ----------------------------------------------------------------------------
  function self._createError(code, message)
      return {
          code = code,
          message = message
      }
  end
  
  -- Auto-initialize when module is loaded
  self.initialize()
  
  -- Return the table so the module can be used
  return self
end

return ApusAI 