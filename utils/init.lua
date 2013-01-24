local naughty = require("naughty")

local io = { popen = io.popen,
	     open = io.open}
local os = { execute = os.execute ,
	     tmpname = os.tmpname,
	     remove = os.remove }
local table = { pack = table.pack,
		unpack = table.unpack }

local utils = {}

function utils.dbg (exp, title)
   naughty.notify({title = title or "Debug", text = tostring(exp)})
end

function utils.safedofile (file)
      local f, err = loadfile(file)
      if f then
         local b, err = pcall(f)
         if b then
            return err
         else
            utils.dbg(err, "Error")
            return
         end
      end
end

-- run_bg function --
-- run function in background and gives output to funtocall after the program terminated,
--    along with farg and a table with info about the command like
--    funtocall(output, farg, proc_info), where
--     proc_info = { cmd = ..., file = logfile (deleted already at functoin call), pid = pid_of_the_background_process, timer = #timer_object, time = elapsed_time_since_start }
-- wait for timeout time, nil means infinite, if it's over send TERM to process, and after 2 sec send KILL or call
-- timeout_func(farg, proc_info) instead if it's not nil
-- poll_freq every freq seconds for process termination, default is 1

function utils.run_bg(cmd, funtocall, farg, timeout, poll_freq, timeout_func)
   -- function aliases
   local is_running = utils.is_running

   local logfile = os.tmpname()
   -- execute program with redirecting output to logfile in background and write out pid
   local cmdstr = cmd .. " &> '" .. logfile .. "' & echo $!"
   local cmdf = io.popen(cmdstr)
   local pid = cmdf:read("*n")
   cmdf:close()

   -- set optional args to default value
   poll_freq = poll_freq or 1
   timeout_func = timeout_func or
      function (_, proc_info)
         utils.end_process(proc_info.pid, 2)
      end

   -- bg_timer upvalue this will be all the data that the timeout callback needs
   local proc_info = {
      cmd = cmd,
      pid = pid,
      file  = logfile,
      timer = timer{ timeout = poll_freq },
      time = 0
   }

   -- set the polling callback
   proc_info.timer:connect_signal("timeout",
				 function()
				    proc_info.time = proc_info.time + poll_freq
				    -- check for timeout, I know using the timeout word here can be confusing,
				    -- this timeout means that, the process did not ended in the time it should have
				    -- already
				    if timeout and proc_info.time > timeout then
				       proc_info.timer:stop()
				       os.remove(proc_info.file)
				       timeout_func(farg, proc_info)
				       return
				    end
				    -- check if process has ended
				    if ( not is_running(proc_info.pid) ) then
				       proc_info.timer:stop()
				       local lf = io.open(proc_info.file)
				       -- just save output for now, clean up before calling funtocall
				       local output = lf:read("*a")
				       lf:close()
				       os.remove(proc_info.file)
				       funtocall(output, farg, proc_info)
				    end
				 end)
   proc_info.timer:start()
end

-- check whether process with pid is running
function utils.is_running(pid)
   return os.execute("ps " .. pid) == true
end

-- send signal to pid
-- exmaple: send_signal(pid_of_daemon, "HUP")
function utils.send_signal(pid, signal)
      os.execute("kill -" .. signal .. " " .. pid)
end

-- run func after delay sec, with remaining arguments
function utils.delay_call(delay, func, ...)
   local t = timer { timeout = delay }
   local args = table.pack(...)
   t:connect_signal("timeout",
		    function ()
		       t:stop()
		       func(table.unpack(args))
		    end)
   t:start()
end

-- send TERM then after killtime seconds KILL signal to pid, if killtime is 0, then send only KILL
-- killtime defaults to 2
function utils.end_process(pid, killtime)
   -- function aliases
   local send_signal = utils.send_signal
   local delay_call = utils.delay_call

   -- set dafult parameters
   killtime = killtime or 2

   if killtime > 0 then
      send_signal(pid, "TERM")
      delay_call(2, send_signal, pid, "KILL")
   else
      send_signal(pid, "KILL")
   end
end

return utils
