--!strict
local freeThreads: { thread } = table.create(500) :: { thread }

local function runFunction<Arguments...>(callback: (Arguments...) -> (), thread: thread, ...: Arguments...)
	callback(...)
	table.insert(freeThreads, thread)
end

local function yieldThread()
	while true do
		runFunction(coroutine.yield())
	end
end

local function fastDefer<Arguments...>(callback: (Arguments...) -> (), ...: Arguments...): thread
	local thread: thread
	local freeAmount = #freeThreads

	if freeAmount > 0 then
		thread = freeThreads[freeAmount]
		freeThreads[freeAmount] = nil
	else
		thread = coroutine.create(yieldThread)
		coroutine.resume(thread)
	end

	task.defer(thread, callback, thread, ...)
	return thread
end

return fastDefer
