--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(script.Constants)

-- Module setup and configuration
local moduleSettings = ReplicatedStorage:WaitForChild(Constants.SETTINGS_FOLDER_NAME, 3)
assert(moduleSettings, "HitboxClass settings not found! Make sure the HitboxSettings Folder is in ReplicatedStorage!")

-- Initial error checking for Alive Folder
assert(
	moduleSettings:FindFirstChild(Constants.ALIVE_FOLDER_SETTING_NAME),
	"No Alive Folder setting found in HitboxClass settings! Make an object value and name it 'Alive Folder' and parent it there!"
)

local aliveFolder = moduleSettings[Constants.ALIVE_FOLDER_SETTING_NAME].Value

-- Initial error checking for Ignore Folder
assert(
	moduleSettings:FindFirstChild(Constants.IGNORE_FOLDER_SETTING_NAME),
	"No Ignore Folder setting found in HitboxClass settings! Make an object value and name it 'Ignore Folder' and parent it there!"
)

local ignoreFolder = moduleSettings[Constants.IGNORE_FOLDER_SETTING_NAME].Value

-- Get velocity constant setting
local velocityConstant = moduleSettings:FindFirstChild(Constants.VELOCITY_CONSTANT_SETTING_NAME)

if not velocityConstant then
	warn("Velocity Constant Setting has been deleted! 6 will be used as a default. (HitboxClass)")
end

assert(aliveFolder ~= nil, "Set the alive characters folder in the HitboxClass settings!")
assert(ignoreFolder ~= nil, "Set the Ignore folder in the HitboxClass settings!")
assert(aliveFolder:IsDescendantOf(workspace), "The alive folder must be a descendant of workspace! (HitboxClass)")
assert(ignoreFolder:IsDescendantOf(workspace), "The Ignore folder must be a descendant of workspace! (HitboxClass)")

-- now we initialize the class
local Types = require(script.Types)
local Packages = script.Parent
local Signal = require(Packages.Signal)
local Timer = require(Packages.Timer)
local Janitor = require(Packages.Janitor)

local overlapParamsHumanoid = OverlapParams.new()
overlapParamsHumanoid.FilterDescendantsInstances = { aliveFolder }
overlapParamsHumanoid.FilterType = Enum.RaycastFilterType.Include

local overlapParamsObject = OverlapParams.new()
overlapParamsObject.FilterDescendantsInstances = { ignoreFolder }
overlapParamsObject.FilterType = Enum.RaycastFilterType.Exclude

local CFrameZero = CFrame.new(Vector3.zero)

local RunService = game:GetService("RunService")

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
	raycastParams.FilterDescendantsInstances = { targetPart }

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

-- Helper function to get hit point data for character
local function GetCharacterHitPointData(hitboxCFrame: CFrame, character: Model): Types.HitPointData?
	if not character.PrimaryPart then
		return nil
	end

	local rayOrigin = hitboxCFrame.Position
	local rayDirection = (character.PrimaryPart.Position - rayOrigin).Unit * 100

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { character }

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

local Hitbox = {} :: Types.Hitbox
Hitbox.__index = Hitbox
local HitboxCache = {} :: { Types.Hitbox }

function Hitbox.new(HitboxParams: Types.HitboxParams)
	local self = (setmetatable({}, Hitbox) :: unknown) :: Types.Hitbox

	self._janitor = Janitor.new()

	self.TaggedChars = {}
	self.TaggedObjects = {}
	self.SendingChars = {}
	self.SendingObjects = {}

	if RunService:IsClient() and HitboxParams._Tick then
		self.TickVal = HitboxParams._Tick
	else
		self.TickVal = workspace:GetServerTimeNow()
	end

	if HitboxParams.ID then
		self.ID = HitboxParams.ID
	end

	self.Blacklist = HitboxParams.Blacklist

	self.OnHit = self._janitor:Add(Signal.new())
	self.HitObject = self._janitor:Add(Signal.new())
	self.OnHitWithPoint = self._janitor:Add(Signal.new())
	self.HitObjectWithPoint = self._janitor:Add(Signal.new())

	self.DebugMode = HitboxParams.Debug or Constants.DEFAULT_DEBUG_MODE
	self.DetectHitPoints = HitboxParams.DetectHitPoints or false

	self.Lifetime = HitboxParams.LifeTime or Constants.DEFAULT_LIFETIME

	self.LookingFor = HitboxParams.LookingFor or Constants.LOOKING_FOR.HUMANOID

	self.CFrame = HitboxParams.InitialCframe or CFrameZero
	self.DebounceTime = HitboxParams.DebounceTime or Constants.DEFAULT_DEBOUNCE_TIME
	self.VelocityPrediction = HitboxParams.VelocityPrediction

	if self.VelocityPrediction == nil then
		self.VelocityPrediction = Constants.DEFAULT_VELOCITY_PREDICTION
	end

	self.DotProductRequirement = HitboxParams.DotProductRequirement

	self.DebugMode = HitboxParams.Debug or false

	if typeof(HitboxParams.SizeOrPart) == "Vector3" then
		self.SpatialOption = HitboxParams.SpatialOption or Constants.SPATIAL_OPTION.IN_BOX

		assert(
			self.SpatialOption ~= Constants.SPATIAL_OPTION.IN_RADIUS,
			"You can't use InRadius as the SpatialOption if a Vector3 is passed! Only InPart and InBox! (HitboxClass)"
		)

		self.Mode = Constants.HITBOX_MODE.PART
		self.Size = HitboxParams.SizeOrPart

		if self.SpatialOption == Constants.SPATIAL_OPTION.IN_PART then
			self:_GeneratePart()
		end
	elseif type(HitboxParams.SizeOrPart) == "number" then
		self.SpatialOption = HitboxParams.SpatialOption or Constants.SPATIAL_OPTION.MAGNITUDE

		if self.SpatialOption == Constants.SPATIAL_OPTION.IN_RADIUS then
			self.Mode = Constants.HITBOX_MODE.PART
			self.Size = HitboxParams.SizeOrPart
		elseif self.SpatialOption == Constants.SPATIAL_OPTION.IN_PART then
			self.Mode = Constants.HITBOX_MODE.PART
			self.Size = Vector3.new(HitboxParams.SizeOrPart, HitboxParams.SizeOrPart, HitboxParams.SizeOrPart)
			self:_GeneratePart()
		elseif self.SpatialOption == Constants.SPATIAL_OPTION.IN_BOX then
			self.Mode = Constants.HITBOX_MODE.PART
			self.Size = Vector3.new(HitboxParams.SizeOrPart, HitboxParams.SizeOrPart, HitboxParams.SizeOrPart)
		else
			self.Mode = Constants.HITBOX_MODE.MAGNITUDE
			self.Size = HitboxParams.SizeOrPart
		end
	else
		self.Mode = Constants.HITBOX_MODE.PART
		self.Size = HitboxParams.SizeOrPart.Size
		self.Part = self._janitor:Add(HitboxParams.SizeOrPart:Clone())

		self.SpatialOption = Constants.SPATIAL_OPTION.IN_PART

		assert(self.Part, "No part provided?")

		assert(self.Part and self.Part:IsA("Part"), "Part provided wasn't a part! (HitboxClass)")

		self.Part.Color = Constants.DEBUG_PART.COLOR
		self.Part.Name = "Hitbox" .. self.TickVal
	end

	if self.DebugMode then
		self:EnableDebug(true)
	end

	table.insert(HitboxCache, self)

	return self, true
end

function Hitbox:ClearTaggedCharacters()
	table.clear(self.TaggedChars)
end

-- This method returns what's currently inside the hitbox without using events
-- Returns either characters (Models) or objects (BaseParts) depending on LookingFor setting
function Hitbox:GetParts()
	local foundItems: { Model | BasePart } = {}

	if self.Mode == Constants.HITBOX_MODE.MAGNITUDE then
		-- Magnitude-based hitbox detection
		if typeof(self.Size) ~= "number" then
			warn("GetParts() called on magnitude hitbox but Size is not a number")
			return foundItems
		end

		for _, Character: Instance in pairs(aliveFolder:GetChildren()) do
			if
				Character:IsA("Model")
				and Character.PrimaryPart ~= nil
				and Character:FindFirstChildOfClass("Humanoid")
			then
				local magnitude = (self.CFrame.Position - Character.PrimaryPart.Position).Magnitude

				if magnitude <= self.Size then
					if self.Blacklist and table.find(self.Blacklist, Character) then
						continue
					end

					-- Check dot product if required
					if self.DotProductRequirement then
						local VectorToCompare = (
							Character.PrimaryPart.CFrame.Position
							- self.DotProductRequirement.PartForVector.CFrame.Position
						).Unit

						local VectorOfUser: Vector3

						if self.DotProductRequirement.VectorType then
							if self.DotProductRequirement.VectorType == "LookVector" then
								VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.LookVector
							elseif self.DotProductRequirement.VectorType == "UpVector" then
								VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.UpVector
							elseif self.DotProductRequirement.VectorType == "RightVector" then
								VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.RightVector
							end
						else
							VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.LookVector
						end

						if self.DotProductRequirement.Negative then
							VectorOfUser *= -1
						end

						if VectorToCompare:Dot(VectorOfUser) < self.DotProductRequirement.DotProduct then
							continue
						end
					end

					table.insert(foundItems, Character)
				end
			end
		end
	else
		-- Part-based hitbox detection (InBox, InRadius, InPart)
		local spatialResults

		if self.SpatialOption == Constants.SPATIAL_OPTION.IN_BOX then
			if self.LookingFor == Constants.LOOKING_FOR.HUMANOID then
				spatialResults = workspace:GetPartBoundsInBox(self.CFrame, self.Size, overlapParamsHumanoid)
			else
				spatialResults = workspace:GetPartBoundsInBox(self.CFrame, self.Size, overlapParamsObject)
			end
		elseif self.SpatialOption == Constants.SPATIAL_OPTION.IN_RADIUS then
			if self.LookingFor == Constants.LOOKING_FOR.HUMANOID then
				spatialResults = workspace:GetPartBoundsInRadius(self.CFrame.Position, self.Size, overlapParamsHumanoid)
			else
				spatialResults = workspace:GetPartBoundsInRadius(self.CFrame.Position, self.Size, overlapParamsObject)
			end
		else -- IN_PART
			if self.LookingFor == Constants.LOOKING_FOR.HUMANOID then
				spatialResults = workspace:GetPartsInPart(self.Part, overlapParamsHumanoid)
			else
				spatialResults = workspace:GetPartsInPart(self.Part, overlapParamsObject)
			end
		end

		for _, part: BasePart in pairs(spatialResults) do
			if not part.Parent then
				continue
			end

			if self.LookingFor == Constants.LOOKING_FOR.HUMANOID then
				local character = part.Parent

				if
					not character:IsA("Model")
					or character.PrimaryPart == nil
					or not character:FindFirstChildOfClass("Humanoid")
				then
					continue
				end

				if self.Blacklist and table.find(self.Blacklist, character) then
					continue
				end

				-- Avoid duplicates
				if not table.find(foundItems, character) then
					table.insert(foundItems, character)
				end
			else
				local blacklistFound = false

				if self.Blacklist then
					for _, blacklistedItem in pairs(self.Blacklist) do
						local blacklistedInstance = blacklistedItem :: Instance
						if part == blacklistedInstance or part:IsDescendantOf(blacklistedInstance) then
							blacklistFound = true
							break
						end
					end
				end

				if not blacklistFound and not table.find(foundItems, part) then
					table.insert(foundItems, part)
				end
			end
		end
	end

	return foundItems
end

function Hitbox:Start()
	if self.Lifetime > 0 then
		-- check to see if there's a timer, if there is one, then start it
		if not self.Timer then
			self.Timer = Timer.Simple(0.1, function()
				self.Lifetime -= 0.1
				if self.Lifetime <= 0 then
					self:Destroy()
				end
			end, true)

			if self._janitor then
				self._janitor:Add(self.Timer)
			end
		else
			self.Timer:Start()
		end
	end

	if self.Mode == Constants.HITBOX_MODE.MAGNITUDE then
		assert(
			typeof(self.Size) == "number",
			"Magnitude hitbox wasn't given a number! Type given: " .. typeof(self.Size)
		)

		if self.Part and self.DebugMode then
			self.Part.Parent = ignoreFolder
		end

		self.RunServiceConnection = self._janitor:Add(RunService.Heartbeat:Connect(function()
			if self.PartWeld then
				self:SetCFrame(self.PartWeld.CFrame * (self.PartWeldOffset or CFrameZero))
			end

			-- go through the alive folder
			for _, Character: Instance in pairs(aliveFolder:GetChildren()) do
				-- check to see if it's a model with a primary part that also has a humanoid
				if
					Character:IsA("Model")
					and Character.PrimaryPart ~= nil
					and Character:FindFirstChildOfClass("Humanoid")
				then
					local magnitude = (self.CFrame.Position - Character.PrimaryPart.Position).Magnitude

					-- if they're greater than the distance of the hitbox, skip them
					if magnitude > self.Size then
						continue
					end

					-- if they're in the blacklist, skip them
					if self.Blacklist then
						if table.find(self.Blacklist, Character) then
							continue
						end
					end

					-- check the dot product if one is given
					if self.DotProductRequirement then
						local VectorToCompare = (
							Character.PrimaryPart.CFrame.Position
							- self.DotProductRequirement.PartForVector.CFrame.Position
						).Unit

						local VectorOfUser: Vector3

						-- changed to a long if statement block cause strict mode was throwing a hissy fit
						-- "attempting a dynamic property access on type 'CFrame' is unsafe and may cause exceptions at runtime"

						if self.DotProductRequirement.VectorType then
							if self.DotProductRequirement.VectorType == "LookVector" then
								VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.LookVector
							elseif self.DotProductRequirement.VectorType == "UpVector" then
								VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.UpVector
							elseif self.DotProductRequirement.VectorType == "RightVector" then
								VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.RightVector
							end
						else
							VectorOfUser = self.DotProductRequirement.PartForVector.CFrame.LookVector
						end

						if self.DotProductRequirement.Negative then
							VectorOfUser *= -1
						end

						if VectorToCompare:Dot(VectorOfUser) < self.DotProductRequirement.DotProduct then
							continue
						end
					end

					-- if they've already been tagged, skip them
					if self.TaggedChars[Character] then
						continue
					end

					if magnitude <= self.Size then
						table.insert(self.SendingChars, Character)
					end
				end
			end

			self:_SiftThroughSendingCharsAndFire()
		end))
	else
		if (self.SpatialOption == "InPart") or (self.Part and self.DebugMode == true) then
			self.Part.Parent = ignoreFolder
		end
		self.RunServiceConnection = self._janitor:Add(RunService.Heartbeat:Connect(function()
			if self.PartWeld then
				self:SetCFrame(self.PartWeld.CFrame * (self.PartWeldOffset or CFrameZero))
			end

			local results

			if self.SpatialOption == "InBox" then
				if self.LookingFor == "Humanoid" then
					results = workspace:GetPartBoundsInBox(self.CFrame, self.Size, overlapParamsHumanoid)
				else
					results = workspace:GetPartBoundsInBox(self.CFrame, self.Size, overlapParamsObject)
				end
			elseif self.SpatialOption == "InRadius" then
				if self.LookingFor == "Humanoid" then
					results = workspace:GetPartBoundsInRadius(self.CFrame.Position, self.Size, overlapParamsHumanoid)
				else
					results = workspace:GetPartBoundsInRadius(self.CFrame.Position, self.Size, overlapParamsObject)
				end
			else
				if self.LookingFor == "Humanoid" then
					results = workspace:GetPartsInPart(self.Part, overlapParamsHumanoid)
				else
					results = workspace:GetPartsInPart(self.Part, overlapParamsObject)
				end
			end

			for _, part: BasePart in pairs(results) do
				if not part.Parent then
					continue
				end

				if self.LookingFor == "Humanoid" then
					local character = part.Parent

					if
						not character:IsA("Model")
						or character.PrimaryPart == nil
						or not character:FindFirstChildOfClass("Humanoid")
					then
						continue
					end

					-- Check blacklist
					if self.Blacklist and table.find(self.Blacklist, character) then
						continue
					end

					-- Check if already processed
					if not table.find(self.SendingChars, character) and not self.TaggedChars[character] then
						table.insert(self.SendingChars, character)
					end
				else
					local blacklistFound = false

					if self.Blacklist then
						-- Check against blacklist with early termination
						for _, blacklistedItem in pairs(self.Blacklist) do
							local blacklistedInstance = blacklistedItem :: Instance
							if part == blacklistedInstance or part:IsDescendantOf(blacklistedInstance) then
								blacklistFound = true
								break
							end
						end
					end

					-- Add to sending objects if not blacklisted or already tracked
					if
						not blacklistFound
						and not table.find(self.SendingObjects, part)
						and not self.TaggedObjects[part]
					then
						table.insert(self.SendingObjects, part)
					end
				end
			end

			if self.LookingFor == "Humanoid" then
				self:_SiftThroughSendingCharsAndFire()
			elseif self.LookingFor == "Object" then
				self:_SiftThroughSendingObjectsAndFire()
			end
		end))
	end
end

function Hitbox:Stop()
	if self.Timer then
		self.Timer:Stop()
	end

	if self.Part then
		self.Part.Parent = nil
	end

	if self.RunServiceConnection then
		self.RunServiceConnection:Disconnect()
		self.RunServiceConnection = nil
	end
end

function Hitbox:SetCFrame(newCframe: CFrame)
	local constant

	if velocityConstant then
		constant = velocityConstant.Value or Constants.DEFAULT_VELOCITY_CONSTANT
	else
		constant = Constants.DEFAULT_VELOCITY_CONSTANT
	end

	if RunService:IsServer() and self.PartWeld and self.VelocityPrediction then
		local velocityVector = newCframe:VectorToObjectSpace(self.PartWeld.AssemblyLinearVelocity) / constant
		newCframe = newCframe * CFrame.new(velocityVector)
	end

	self.CFrame = newCframe

	if self.Part then
		self.Part.CFrame = newCframe
	elseif self.DebugMode then
		-- Generate debug part if it doesn't exist but debug mode is enabled
		self:_GeneratePart()
		if self.Part then
			self.Part.CFrame = newCframe
			self.Part.Parent = ignoreFolder
		end
	end
end

function Hitbox:WeldTo(PartToWeldTo: BasePart, OffsetCFrame: CFrame?)
	self.PartWeld = PartToWeldTo
	self.PartWeldOffset = OffsetCFrame
end

function Hitbox:Unweld()
	self.PartWeld = nil
	self.PartWeldOffset = nil
end

function Hitbox:SetWeldOffset(OffsetCFrame: CFrame)
	self.PartWeldOffset = OffsetCFrame
end

function Hitbox:EnableVelocityPrediction(state: boolean)
	self.VelocityPrediction = state
end

function Hitbox:EnableDebug(state: boolean)
	self.DebugMode = state

	if self.DebugMode then
		if not self.Part then
			self:_GeneratePart()
			assert(self.Part, "Part wasn't generated after the GeneratePart method?")
		end

		if self.Part then
			self.Part.Transparency = Constants.DEBUG_PART.VISIBLE_TRANSPARENCY

			-- Parent the part to ignoreFolder if it's not already parented
			if not self.Part.Parent then
				self.Part.Parent = ignoreFolder
			end
		end
	else
		if self.Part then
			if self.SpatialOption ~= Constants.SPATIAL_OPTION.IN_PART then
				self.Part.Parent = nil
			end

			self.Part.Transparency = Constants.DEBUG_PART.INVISIBLE_TRANSPARENCY
		end
	end
end

function Hitbox.ClearHitboxesByID(ID: number | string)
	if RunService:IsClient() then
		return
	end

	-- go through the cache and destroy any hitboxes with the ID provided
	for i = #HitboxCache, 1, -1 do
		local checkingHitbox = HitboxCache[i]

		if checkingHitbox.ID and checkingHitbox.ID == ID then
			pcall(function()
				checkingHitbox:Destroy()
			end)
		end
	end
end

function Hitbox.GetHitboxCache()
	return HitboxCache
end

function Hitbox:_SiftThroughSendingObjectsAndFire()
	if #self.SendingObjects <= 0 then
		return
	end

	local shallowObjectTable = {}
	local hitPointDataTable = {}

	for _, object in pairs(self.SendingObjects) do
		table.insert(shallowObjectTable, object)
		-- Get hit point data if enabled
		if self.DetectHitPoints then
			local hitData = GetHitPointData(self.CFrame, object)
			if hitData then
				table.insert(hitPointDataTable, hitData)
			end
		end

		self.TaggedObjects[object] = true

		if self.DebounceTime > 0 then
			self._janitor:Add(task.delay(self.DebounceTime, function()
				self.TaggedObjects[object] = nil
			end))
		end
	end

	if #shallowObjectTable > 0 then
		self.HitObject:Fire(shallowObjectTable)

		-- Fire hit point signal if we have hit point data
		if self.DetectHitPoints and #hitPointDataTable > 0 then
			self.HitObjectWithPoint:Fire(hitPointDataTable)
		end
	end

	if self.SendingObjects then
		table.clear(self.SendingObjects)
	end
end

function Hitbox:_SiftThroughSendingCharsAndFire()
	if #self.SendingChars <= 0 then
		return
	end

	local shallowObjectTable = {}
	local hitPointDataTable = {}

	for _, character: Model in pairs(self.SendingChars) do
		table.insert(shallowObjectTable, character)
		-- Get hit point data if enabled
		if self.DetectHitPoints then
			local hitData = GetCharacterHitPointData(self.CFrame, character)
			if hitData then
				table.insert(hitPointDataTable, hitData)
			end
		end

		self.TaggedChars[character] = true

		if self.DebounceTime > 0 then
			self._janitor:Add(task.delay(self.DebounceTime, function()
				self.TaggedChars[character] = nil
			end))
		end
	end

	if #shallowObjectTable > 0 then
		self.OnHit:Fire(shallowObjectTable)

		-- Fire hit point signal if we have hit point data
		if self.DetectHitPoints and #hitPointDataTable > 0 then
			self.OnHitWithPoint:Fire(hitPointDataTable)
		end
	end

	if self.SendingChars then
		table.clear(self.SendingChars)
	end
end

function Hitbox:_GeneratePart()
	if self.Part then
		return
	end

	if typeof(self.Size) == "Vector3" then
		self.Mode = "Part"
		self.Part = self._janitor:Add(Instance.new("Part"))

		assert(self.Part, "Part was nil!")
		assert(typeof(self.Size) == "Vector3", "self.Size wasn't a vector3 when making a part!") -- you shouldn't get here, but just in case

		self.Part.Color = Color3.new(1, 0, 0)

		if self.DebugMode then
			self.Part.Transparency = 0.45
		else
			self.Part.Transparency = 1
		end

		self.Part.Anchored = true
		self.Part.Massless = true
		self.Part.CanCollide = false

		self.Part.Size = self.Size
		self.Part.CFrame = self.CFrame

		self.Part.Name = "Hitbox" .. self.TickVal
	elseif type(self.Size) == "number" then
		self.Part = self._janitor:Add(Instance.new("Part"))

		assert(self.Part and self.Part:IsA("Part"), "Part provided wasn't a part! (HitboxClass)")
		assert(typeof(self.Size) == "number", "self.Size wasn't a number when making a sphere part!") -- you shouldn't get here, but just in case

		self.Part.Shape = Enum.PartType.Ball
		self.Part.Anchored = true
		self.Part.Massless = true
		self.Part.CanCollide = false
		self.Part.Size = Vector3.new(self.Size * 2, self.Size * 2, self.Size * 2)
		self.Part.Transparency = 0.45
		self.Part.Color = Color3.new(1, 0, 0)
		self.Part.CFrame = self.CFrame
		self.Part.Name = "Hitbox" .. self.TickVal
	end
end

function Hitbox:Destroy()
	-- Remove the hitbox from the cache
	local index = table.find(HitboxCache, self)
	if index then
		table.remove(HitboxCache, index)
	end

	self.TaggedChars = {}
	self.SendingChars = {}
	self.TaggedObjects = {}
	self.SendingObjects = {}

	-- Cleanup all resources with janitor
	if self._janitor then
		self._janitor:Destroy()
	end
end

return Hitbox
