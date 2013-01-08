-- {{{ Grab environment
local setmetatable = setmetatable
local string = { match = string.match }
local io = { popen = io.popen }
local table = table
local utils = require("utils")
-- }}}

-- Stdout: provides the stdout of a command
-- vicious.widgets.stdout
local stdout = {}

-- {{{ Stdout widget type
-- warg is an array of tables which tells the commands and how to get values
-- the table keys are
-- "command", which is a string with the command to run
-- and optionally the followings:
-- "id", which is any value to know which command are the same (those with same id, are overwritten with time)
--     we need id because the command is run asynchronously in the background
--     this means you can't get the output immediately, the widget gives the last output associated with
--     the given id, if nil "command" is used as id
-- "timeout", the called process has this much time to end, or it will be killed cleanly (TERM and after 2s KILL)
--        deafults to wait forever
-- "timeout_val", this is the value of output when we reach timeout, if nil, the output will be the last
-- "default_val", the value associated with id, when there is no output yet

local outputs = {}
local function worker(format, warg)
   if type(warg) == "table" then
      local ret = {}
      for i, t in ipairs(warg) do
	 -- set default values
	 local c = t.command
	 local id = t.id or c
	 local timeout = t.timeout or nil
	 local timeout_val = t.timeout_val or nil
	 local default_val = t.default_val or ""
	 -- set output for id, if it's not set already
	 if not (outputs[id]) then
	    outputs[id] = default_val
	 end
	 utils.run_bg(c,
		      function (output, _, _) -- called when we have output
			 outputs[id] = output
		      end,
		      nil, -- no custom arg to the callbacks, could be id, but it is already an upvalue
		      timeout, 1,
		      function (_, proc_info) -- called on timeout
			 -- set timeout_val
			 if timeout_val then
			    outputs[id] = timeout_val
			 end
			 -- kill process
			 utils.end_process(proc_info.pid, 2)
		      end)
	 -- add outputs[id] to the table being returned
	 table.insert(ret, outputs[id])
      end
      -- return values associated to ids
      return ret
   end
   -- wrong argument type, not table or string
   return nil
end
-- }}}

return setmetatable(stdout, { __call = function(_, ...) return worker(...) end })
