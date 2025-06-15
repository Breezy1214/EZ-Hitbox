--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitboxModule = script.HitboxClassPointer.Value
local ConstantsModule = HitboxModule:WaitForChild("Constants", 3)
local HitboxClass = require(HitboxModule)
local Constants = require(ConstantsModule)
local HitboxClassRemote: RemoteEvent = ReplicatedStorage:WaitForChild(Constants.REMOTE_EVENT_NAME)

local currentHitboxes = {}

HitboxClassRemote.OnClientEvent:Connect(function(mode, packet)
	if mode == Constants.REMOTE_MODE.CLEAR then
		for i, Hitbox in pairs(currentHitboxes) do
			Hitbox:Destroy()
			currentHitboxes[i] = nil
		end
		return
	end

	if mode ~= Constants.REMOTE_MODE.NEW and not currentHitboxes[packet._Tick] then
		warn(
			"No hitbox found on the client for tick value sent. Don't change the tick value manually, change the ID instead. (HitboxClass)"
		)
		return
	end
	if mode == Constants.REMOTE_MODE.NEW then
		local newHitbox = HitboxClass.new(packet)
		currentHitboxes[packet._Tick] = newHitbox
		HitboxClassRemote:FireServer(packet._Tick)
	end

	if mode == Constants.REMOTE_MODE.START then
		currentHitboxes[packet._Tick]:Start()
	end

	if mode == Constants.REMOTE_MODE.STOP then
		currentHitboxes[packet._Tick]:Stop()
	end

	if mode == Constants.REMOTE_MODE.CLEAR_TAG then
		currentHitboxes[packet._Tick]:ClearTaggedChars()
	end

	if mode == Constants.REMOTE_MODE.WELD then
		currentHitboxes[packet._Tick]:WeldTo(packet.WeldTo, packet.Offset)
	end

	if mode == Constants.REMOTE_MODE.WELD_OFFSET then
		currentHitboxes[packet._Tick]:ChangeWeldOffset(packet.Offset)
	end

	if mode == Constants.REMOTE_MODE.UNWELD then
		currentHitboxes[packet._Tick]:Unweld()
	end

	if mode == Constants.REMOTE_MODE.POSITION_CHANGE then
		currentHitboxes[packet._Tick]:SetPosition(packet.Position)
	end

	if mode == Constants.REMOTE_MODE.DEBUG then
		currentHitboxes[packet._Tick]:SetDebug(packet.Debug)
	end

	if mode == Constants.REMOTE_MODE.DESTROY then
		currentHitboxes[packet._Tick]:Destroy()
		currentHitboxes[packet._Tick] = nil
	end
end)
