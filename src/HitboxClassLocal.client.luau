--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitboxModule = script.HitboxClassPointer.Value
local ConstantsModule = HitboxModule:WaitForChild("Constants", 3)
local TypesModule = HitboxModule:WaitForChild("Types", 3)
local HitboxClass = require(HitboxModule)
local Constants = require(ConstantsModule)
local Types = require(TypesModule)
local HitboxClassRemote: RemoteEvent = ReplicatedStorage:WaitForChild(Constants.REMOTE_EVENT_NAME)

local currentHitboxes = {}

-- Helper function to perform raycast and get hit point data on client
local function GetHitPointData(hitboxCFrame: CFrame, targetPart: BasePart): Types.HitPointData?
	local rayOrigin = hitboxCFrame.Position
	local rayDirection
	
	-- Calculate direction from hitbox center to the target part
	if targetPart.Parent then
		rayDirection = (targetPart.Position - rayOrigin).Unit * 100 -- Ray distance of 100 studs
	else
		return nil
	end
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {targetPart}
	
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		local hitData: Types.HitPointData = {
			Object = targetPart,
			Position = raycastResult.Position,
			Normal = raycastResult.Normal,
			Material = raycastResult.Material,
		}
		return hitData
	end
	
	return nil
end

-- Helper function to get hit point data for character on client
local function GetCharacterHitPointData(hitboxCFrame: CFrame, character: Model): Types.HitPointData?
	if not character.PrimaryPart then
		return nil
	end
	
	local rayOrigin = hitboxCFrame.Position
	local rayDirection = (character.PrimaryPart.Position - rayOrigin).Unit * 100
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {character}
	
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		local hitData: Types.HitPointData = {
			Object = character,
			Position = raycastResult.Position,
			Normal = raycastResult.Normal,
			Material = raycastResult.Material,
		}
		return hitData
	end
	
	return nil
end

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
		
		-- Override the hit detection methods if hit point detection is enabled
		if packet.DetectHitPoints then
			-- Override _SiftThroughSendingCharsAndFire
			newHitbox._SiftThroughSendingCharsAndFire = function(self)
				if #self.SendingChars <= 0 then
					return
				end

				local shallowObjectTable = {}
				local hitPointDataTable = {}

				for _, character: Model in pairs(self.SendingChars) do
					table.insert(shallowObjectTable, character)					-- Get hit point data
					local hitData = GetCharacterHitPointData(self.CFrame, character)
					if hitData then
						table.insert(hitPointDataTable, hitData)
					end

					self.TaggedChars[character] = true

					if self.DebounceTime > 0 then
						self._janitor:Add(task.delay(self.DebounceTime, function()
							self.TaggedChars[character] = nil
						end))
					end
				end

				if #shallowObjectTable > 0 then
					-- Send both regular hit data and hit point data to server
					local dataToSend = {
						HitTable = shallowObjectTable,
						HitPointData = #hitPointDataTable > 0 and hitPointDataTable or nil
					}
					HitboxClassRemote:FireServer(self.TickVal, dataToSend)

					self.OnHit:Fire(shallowObjectTable)
					
					-- Fire hit point signal if we have hit point data
					if #hitPointDataTable > 0 then
						self.OnHitWithPoint:Fire(hitPointDataTable)
					end
				end

				if self.SendingChars then
					table.clear(self.SendingChars)
				end
			end
			
			-- Override _SiftThroughSendingObjectsAndFire
			newHitbox._SiftThroughSendingObjectsAndFire = function(self)
				if #self.SendingObjects <= 0 then
					return
				end

				local shallowObjectTable = {}
				local hitPointDataTable = {}

				for _, object in pairs(self.SendingObjects) do
					table.insert(shallowObjectTable, object)					-- Get hit point data
					local hitData = GetHitPointData(self.CFrame, object)
					if hitData then
						table.insert(hitPointDataTable, hitData)
					end

					self.TaggedObjects[object] = true

					if self.DebounceTime > 0 then
						self._janitor:Add(task.delay(self.DebounceTime, function()
							self.TaggedObjects[object] = nil
						end))
					end
				end

				if #shallowObjectTable > 0 then
					-- Send both regular hit data and hit point data to server
					local dataToSend = {
						HitTable = shallowObjectTable,
						HitPointData = #hitPointDataTable > 0 and hitPointDataTable or nil
					}
					HitboxClassRemote:FireServer(self.TickVal, dataToSend)

					self.HitObject:Fire(shallowObjectTable)
					
					-- Fire hit point signal if we have hit point data
					if #hitPointDataTable > 0 then
						self.HitObjectWithPoint:Fire(hitPointDataTable)
					end
				end

				if self.SendingObjects then
					table.clear(self.SendingObjects)
				end
			end
		end
		
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
		currentHitboxes[packet._Tick]:ClearTaggedCharacters()
	end

	if mode == Constants.REMOTE_MODE.WELD then
		currentHitboxes[packet._Tick]:WeldTo(packet.WeldTo, packet.Offset)
	end

	if mode == Constants.REMOTE_MODE.WELD_OFFSET then
		currentHitboxes[packet._Tick]:SetWeldOffset(packet.Offset)
	end

	if mode == Constants.REMOTE_MODE.UNWELD then
		currentHitboxes[packet._Tick]:Unweld()
	end

	if mode == Constants.REMOTE_MODE.POSITION_CHANGE then
		currentHitboxes[packet._Tick]:SetCFrame(packet.CFrame)
	end

	if mode == Constants.REMOTE_MODE.DEBUG then
		currentHitboxes[packet._Tick]:EnableDebug(packet.Debug)
	end

	if mode == Constants.REMOTE_MODE.DESTROY then
		currentHitboxes[packet._Tick]:Destroy()
		currentHitboxes[packet._Tick] = nil
	end
end)
