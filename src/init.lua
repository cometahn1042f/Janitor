--!strict
local fastDefer = require(script.fastDefer)
local Promise = require(script.Parent.Promise)
type Promise = any

local LinkToInstanceIndex = setmetatable({}, {
	__tostring = function()
		return "LinkToInstanceIndex"
	end,
})

local INVALID_METHOD_NAME =
	"Object is a %* and as such expected `true?` for the method name and instead got %*. Traceback: %*"
local METHOD_NOT_FOUND_ERROR = "Object %* doesn't have method %*, are you sure you want to add it? Traceback: %*"
local NOT_A_PROMISE = "Invalid argument #1 to 'Janitor:AddPromise' (Promise expected, got %* (%*)) Traceback: %*"

export type Janitor = typeof(setmetatable(
	{} :: {
		CurrentlyCleaning: boolean,
		SuppressInstanceReDestroy: boolean,
		UnsafeThreadCleanup: boolean,

		Add: <T>(self: Janitor, object: T, methodName: BooleanOrString?, index: any?) -> T,
		AddObject: <T, A...>(
			self: Janitor,
			constructor: { new: (A...) -> T },
			methodName: BooleanOrString?,
			index: any?,
			A...
		) -> T,
		AddPromise: (self: Janitor, promiseObject: Promise, index: unknown?) -> Promise,

		Remove: (self: Janitor, index: any) -> Janitor,
		RemoveNoClean: (self: Janitor, index: any) -> Janitor,

		RemoveList: (self: Janitor, ...any) -> Janitor,
		RemoveListNoClean: (self: Janitor, ...any) -> Janitor,

		Get: (self: Janitor, index: any) -> any?,
		GetAll: (self: Janitor) -> { [any]: any },

		Cleanup: (self: Janitor) -> (),
		Destroy: (self: Janitor) -> (),

		LinkToInstance: (self: Janitor, Object: Instance, allowMultiple: boolean?) -> RBXScriptConnection,
		LinkToInstances: (self: Janitor, ...Instance) -> Janitor,
	},
	{} :: { __call: (self: Janitor) -> () }
))
type Private = typeof(setmetatable(
	{} :: {
		CurrentlyCleaning: boolean,
		SuppressInstanceReDestroy: boolean,
		UnsafeThreadCleanup: boolean,

		[any]: BooleanOrString,

		Add: <T>(self: Private, object: T, methodName: BooleanOrString?, index: any?) -> T,
		AddObject: <T, A...>(
			self: Private,
			constructor: { new: (A...) -> T },
			methodName: BooleanOrString?,
			index: any?,
			A...
		) -> T,
		AddPromise: (self: Private, promiseObject: Promise, index: unknown?) -> Promise,

		Remove: (self: Private, index: any) -> Private,
		RemoveNoClean: (self: Private, index: any) -> Private,

		RemoveList: (self: Private, ...any) -> Private,
		RemoveListNoClean: (self: Private, ...any) -> Private,

		Get: (self: Private, index: any) -> any?,
		GetAll: (self: Private) -> { [any]: any },

		Cleanup: (self: Private) -> (),
		Destroy: (self: Private) -> (),

		LinkToInstance: (self: Private, object: Instance, allowMultiple: boolean?) -> RBXScriptConnection,
		LinkToInstances: (self: Private, ...Instance) -> Private,
	},
	{} :: { __call: (self: Private) -> () }
))
type Static = {
	ClassName: "Janitor",

	CurrentlyCleaning: boolean,
	SuppressInstanceReDestroy: boolean,
	UnsafeThreadCleanup: boolean,

	new: () -> Janitor,
	Is: (object: any) -> boolean,
	instanceof: (object: any) -> boolean,
}
type PrivateStatic = Static & {
	__call: (self: Private) -> (),
	__tostring: (self: Private) -> string,
}

local Janitor = {} :: Janitor & Static
local Private = Janitor :: Private & PrivateStatic
Janitor.ClassName = "Janitor"
Janitor.CurrentlyCleaning = true
Janitor.SuppressInstanceReDestroy = false
Janitor.UnsafeThreadCleanup = false
(Janitor :: any).__index = Janitor

local Janitors = setmetatable({} :: { [Private]: { [any]: any } }, { __mode = "ks" })

function Janitor.new(): Janitor
	return setmetatable({
		CurrentlyCleaning = false,
	}, Janitor) :: never
end

function Janitor.Is(object: any): boolean
	return type(object) == "table" and getmetatable(object) == Janitor
end

Janitor.instanceof = Janitor.Is

local function Remove(self: Private, index: any): Janitor
	local this = Janitors[self]

	if this then
		local object = this[index]
		if not object then
			return (self :: any) :: Janitor
		end

		local methodName = self[object]
		if methodName then
			if methodName == true then
				if type(object) == "function" then
					(object :: () -> ())()
				else
					local wasCancelled: boolean? = nil
					if coroutine.running() ~= object then
						wasCancelled = pcall(task.cancel, object)
					end

					if not wasCancelled then
						if self.UnsafeThreadCleanup then
							fastDefer(task.cancel, object)
						else
							task.defer(task.cancel, object)
						end
					end
				end
			else
				if methodName == "Destroy" then
					if typeof(object) == "Instance" then
						if self.SuppressInstanceReDestroy then
							pcall(game.Destroy, object)
						else
							(object :: Instance):Destroy()
						end
					else
						local destroy = (object :: any).Destroy
						if destroy then
							(destroy :: (any) -> ())(object)
						end
					end
				elseif methodName == "Disconnect" then
					if typeof(object) == "RBXScriptConnection" then
						(object :: RBXScriptConnection):Disconnect()
					else
						local disconnect = (object :: any).Disconnect
						if disconnect then
							(disconnect :: (any) -> ())(object)
						end
					end
				else
					local objectMethod = (object :: never)[methodName] :: (object: unknown) -> ()
					if objectMethod then
						objectMethod(object)
					end
				end
			end

			self[object] = nil
		end

		this[index] = nil
	end

	return (self :: any) :: Janitor
end

type BooleanOrString = boolean | string

local function Add<T>(self: Private, object: T, methodName: BooleanOrString?, index: any?): T
	if index then
		Remove(self, index)

		local this = Janitors[self]
		if not this then
			this = {}
			Janitors[self] = this
		end

		this[index] = object
	end

	local typeOf = typeof(object)
	local newMethodName = methodName
	if not newMethodName then
		if typeOf == "function" or typeOf == "thread" then
			newMethodName = true
		elseif typeOf == "RBXScriptConnection" then
			newMethodName = "Disconnect"
		else
			newMethodName = "Destroy"
		end
	end

	if typeOf == "function" or typeOf == "thread" then
		if newMethodName ~= true then
			warn(string.format(INVALID_METHOD_NAME, typeOf, tostring(newMethodName), debug.traceback(nil, 2)))
		end
	else
		if not (object :: any)[newMethodName] then
			warn(
				string.format(
					METHOD_NOT_FOUND_ERROR,
					tostring(object),
					tostring(newMethodName),
					debug.traceback(nil, 2)
				)
			)
		end
	end

	self[object] = newMethodName
	return object
end

Private.Add = Add

function Janitor:AddObject<T, A...>(constructor: { new: (A...) -> T }, methodName: BooleanOrString?, index: any?, ...: A...): T
	return Add((self :: any) :: Private, constructor.new(...), methodName, index)
end

local function Get(self: Private, index: unknown): any?
	local this = Janitors[self]
	return if this then this[index] else nil
end

Janitor.Get = Get :: any

function Janitor:AddPromise(promiseObject: Promise, index: unknown?): Promise
	if not Promise then
		return promiseObject
	end

	if type(promiseObject) ~= "table" or type(promiseObject.andThen) ~= "function" then
		error(string.format(NOT_A_PROMISE, typeof(promiseObject), tostring(promiseObject), debug.traceback(nil, 2)))
	end

	if (promiseObject :: any)._state ~= 0 then
		return promiseObject
	end

	local uniqueId = index
	if uniqueId == nil then
		uniqueId = newproxy(false)
	end

	local newPromise = Add(
		(self :: any) :: Private,
		Promise.new(function(resolve: any, _: any, onCancel: any)
			onCancel(function()
				promiseObject:cancel()
			end)

			resolve(promiseObject)
		end),
		"cancel",
		uniqueId
	)

	newPromise:finally(function()
		if Get((self :: any) :: Private, uniqueId) == newPromise then
			Remove((self :: any) :: Private, uniqueId)
		end
	end)

	return newPromise :: never
end

Private.Remove = Remove :: any

function Private:RemoveNoClean(index: any): Janitor
	local this = Janitors[self]

	if this then
		local object = this[index]
		if object then
			(self :: any)[object] = nil
			this[index] = nil
		end
	end

	return (self :: any) :: Janitor
end

function Janitor:RemoveList(...: any): Janitor
	local this = Janitors[(self :: any) :: Private]
	if this then
		local length = select("#", ...)
		if length == 1 then
			return Remove((self :: any) :: Private, ...)
		end
		if length == 2 then
			local indexA, indexB = ...
			Remove((self :: any) :: Private, indexA)
			Remove((self :: any) :: Private, indexB)
			return self
		end
		if length == 3 then
			local indexA, indexB, indexC = ...
			Remove((self :: any) :: Private, indexA)
			Remove((self :: any) :: Private, indexB)
			Remove((self :: any) :: Private, indexC)
			return self
		end

		for selectIndex = 1, length do
			local removeObject = select(selectIndex, ...)
			Remove((self :: any) :: Private, removeObject)
		end
	end

	return self
end

function Janitor:RemoveListNoClean(...: any): Janitor
	local this = Janitors[(self :: any) :: Private]
	if this then
		local length = select("#", ...)
		if length == 1 then
			local indexA = ...
			local object = this[indexA]
			if object then
				(self :: any)[object] = nil
				this[indexA] = nil
			end
			return self
		end
		if length == 2 then
			local indexA, indexB = ...
			local objectA = this[indexA]
			if objectA then
				(self :: any)[objectA] = nil
				this[indexA] = nil
			end
			local objectB = this[indexB]
			if objectB then
				(self :: any)[objectB] = nil
				this[indexB] = nil
			end
			return self
		end
		if length == 3 then
			local indexA, indexB, indexC = ...
			local objectA = this[indexA]
			if objectA then
				(self :: any)[objectA] = nil
				this[indexA] = nil
			end
			local objectB = this[indexB]
			if objectB then
				(self :: any)[objectB] = nil
				this[indexB] = nil
			end
			local objectC = this[indexC]
			if objectC then
				(self :: any)[objectC] = nil
				this[indexC] = nil
			end
			return self
		end

		for selectIndex = 1, length do
			local index = select(selectIndex, ...)
			local object = this[index]
			if object then
				(self :: any)[object] = nil
				this[index] = nil
			end
		end
	end

	return self
end

function Janitor:GetAll(): { [any]: any }
	local this = Janitors[(self :: any) :: Private]
	return if this then table.freeze(table.clone(this)) else {}
end

local function Cleanup(self: Private): ()
	if not self.CurrentlyCleaning then
		local suppressInstanceReDestroy = self.SuppressInstanceReDestroy
		local unsafeThreadCleanup = self.UnsafeThreadCleanup

		self.CurrentlyCleaning = nil :: never
		self.SuppressInstanceReDestroy = nil :: never
		self.UnsafeThreadCleanup = nil :: never

		for object, methodName in self do
			if methodName == true then
				if type(object) == "function" then
					(object :: () -> ())()
				else
					local wasCancelled: boolean? = nil
					if coroutine.running() ~= object then
						wasCancelled = pcall(task.cancel, object)
					end

					if not wasCancelled then
						if unsafeThreadCleanup then
							fastDefer(task.cancel, object)
						else
							task.defer(task.cancel, object)
						end
					end
				end
			else
				if methodName == "Destroy" then
					if typeof(object) == "Instance" then
						if self.SuppressInstanceReDestroy then
							pcall(game.Destroy, object)
						else
							(object :: Instance):Destroy()
						end
					else
						local destroy = (object :: any).Destroy
						if destroy then
							(destroy :: (any) -> ())(object)
						end
					end
				elseif methodName == "Disconnect" then
					if typeof(object) == "RBXScriptConnection" then
						(object :: RBXScriptConnection):Disconnect()
					else
						local disconnect = (object :: any).Disconnect
						if disconnect then
							(disconnect :: (any) -> ())(object)
						end
					end
				else
					local objectMethod = (object :: never)[methodName] :: (object: unknown) -> ()
					if objectMethod then
						objectMethod(object)
					end
				end
			end

			self[object] = nil
		end

		local this = Janitors[self]
		if this then
			table.clear(this)
			Janitors[self] = nil
		end

		self.CurrentlyCleaning = false
		self.SuppressInstanceReDestroy = suppressInstanceReDestroy
		self.UnsafeThreadCleanup = unsafeThreadCleanup
	end
end
Private.Cleanup = Cleanup

function Janitor:Destroy(): ()
	Cleanup((self :: any) :: Private)
	table.clear(self :: never)
	setmetatable(self :: any, nil)
end

(Private :: any).__call = Cleanup :: any

local function LinkToInstance(self: Private, object: Instance, allowMultiple: boolean?): RBXScriptConnection
	local indexToUse = if allowMultiple then newproxy(false) else LinkToInstanceIndex

	return Add(
		self,
		object.Destroying:Connect(function()
			Cleanup(self)
		end),
		"Disconnect",
		indexToUse
	)
end

Private.LinkToInstance = LinkToInstance;

(Janitor :: never).LegacyLinkToInstance = LinkToInstance

function Janitor:LinkToInstances(...: Instance): Janitor
	local manualCleanup = Janitor.new()
	for index = 1, select("#", ...) do
		local object = select(index, ...)
		if typeof(object) ~= "Instance" then
			continue
		end

		manualCleanup:Add(LinkToInstance((self :: any) :: Private, object, true), "Disconnect")
	end

	return manualCleanup
end

function Private:__tostring()
	return "Janitor"
end

return Janitor :: Static
