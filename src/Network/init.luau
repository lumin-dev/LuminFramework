-- Credit to Redblox for most of the original code, this is a bit modified and improved
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	if not ReplicatedStorage:FindFirstChild("FrameworkReliable") then
		local Reliable = Instance.new("RemoteEvent")
		Reliable.Name = "FrameworkReliable"
		Reliable.Parent = ReplicatedStorage
	end

	if not ReplicatedStorage:FindFirstChild("FrameworkUnreliable") then
		local Unreliable = Instance.new("UnreliableRemoteEvent")
		Unreliable.Name = "FrameworkUnreliable"
		Unreliable.Parent = ReplicatedStorage
	end

	require(script.Server).Init()
else
	require(script.Client).Init()
end

return {
	Server = require(script.Server),
	Client = require(script.Client),
	Identifier = require(script.Identifier),
	Interface = require(script.Interface),
}
