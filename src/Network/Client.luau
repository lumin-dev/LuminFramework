-- Variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Reliable: RemoteEvent = ReplicatedStorage:WaitForChild("FrameworkReliable")
local Unreliable: UnreliableRemoteEvent = ReplicatedStorage:WaitForChild("FrameworkUnreliable")

local RemotePacketSizeCounter = require(script.Parent.Parent.Parent.remotepacketsizecounter)

local Listeners: { [string]: ({ any }) -> () } = {}
local Calls: { [string]: thread } = {}
local Outgoing: {
	Unreliable: { [string]: { { any } } },
	Reliable: { [string]: { { any } } },
	Call: { [string]: { { any } } },
} =
	{
		Reliable = {},
		Call = {},
		Unreliable = {},
	}

-- Functions

-- Normally sends a reliable event
local function SendReliable(id: string, args: { any })
	if not Outgoing.Reliable[id] then
		Outgoing.Reliable[id] = {}
	end

	table.insert(Outgoing.Reliable[id], args)
end

-- Sends the event without batching (waiting an extra frame)
local function SendReliableNow(id: string, args: { any })
	Reliable:FireServer({ [id] = { args } })
end

-- Sends an unreliable event with batching, but packet size protection is offered
local function SendUnreliable(player: Player, id: string, args: { any })
	if not Outgoing.Unreliable[id] then
		Outgoing.Unreliable[id] = {}
	end

	local OutgoingMimic = Outgoing.Unreliable
	table.insert(OutgoingMimic[id], args)

	local PacketSize = RemotePacketSizeCounter.GetPacketSize({
		RunContext = "Client",
		RemoteType = "RemoteEvent",
		PacketData = {OutgoingMimic},
	})

	-- Since unreliable events have a limit of 900 bytes, we cannot batch all data
	if PacketSize >= 840 then
		Unreliable:FireServer({ [id] = { args } })
	else
		table.insert(Outgoing.Unreliable[id], args)
	end
end

-- Similar to `SendReliableNow`
local function SendUnreliableNow(player: Player, id: string, args: { any })
	Unreliable:FireServer({ [id] = { args } })
end

-- Sends a call to be recieved by the server and then back to the client
local function SendReliableCallAsync(id: string, args: { any }): { any }
	if not Outgoing.Call[id] then
		Outgoing.Call[id] = {}
	end

	table.insert(Outgoing.Call[id], args)
	Calls[args[1]] = coroutine.running()

	return coroutine.yield()
end

-- Sets a callback to listen for when an event/function is recieved by the client
local function Listen(id: string, callback: ({ any }) -> ())
	Listeners[id] = callback
end

local function Init()
	Reliable.OnClientEvent:Connect(function(incomingFires, incomingCalls)
		-- reliable remote events
		if incomingFires then
			for id, callList in incomingFires do
				local Callback = Listeners[id]
				if Callback then
					for _, call in callList do
						Callback(call)
					end
				end
			end
		end
		-- remote functions
		if incomingCalls then
			for id, callList in incomingCalls do
				local thread = Calls[id]
				if thread then
					Calls[id] = nil
					coroutine.resume(thread, callList)
				end
			end
		end
	end)

	Unreliable.OnClientEvent:Connect(function(incomingFires)
		-- unreliable remote events
		for id, callList in incomingFires do
			local Callback = Listeners[id]
			if Callback then
				for _, call in callList do
					Callback(call)
				end
			end
		end
	end)

	RunService.Heartbeat:Connect(function()
		if next(Outgoing.Reliable) or next(Outgoing.Call) then
			Reliable:FireServer(Outgoing.Reliable, Outgoing.Call)
			Outgoing.Reliable = {}
			Outgoing.Call = {}
		end

		if next(Outgoing.Unreliable) then
			Unreliable:FireServer(Outgoing.Unreliable)
			Outgoing.Unreliable = {}
		end
	end)
end

return {
	Init = Init,
	Listen = Listen,

	SendReliable = SendReliable,
	SendReliableNow = SendReliableNow,

	SendUnreliable = SendUnreliable,
	SendUnreliableNow = SendUnreliableNow,

	SendReliableCallAsync = SendReliableCallAsync,
}
