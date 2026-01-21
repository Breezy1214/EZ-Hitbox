--!strict
--[[
	Quick Start:
		local Hitbox = require(path.to.Hitbox)
		
		-- Sphere hitbox (simplest)
		local hit = Hitbox.sphere(10, character.HumanoidRootPart.CFrame)
		hit.OnHit:Connect(function(characters) ... end)
		hit:Start()
		
		-- Box hitbox
		local hit = Hitbox.box(Vector3.new(10, 5, 10), CFrame.new(0, 5, 0))
		
		-- Full constructor (all params optional except size)
		local hit = Hitbox.new({
			Size = Vector3.new(10, 10, 10),
			CFrame = CFrame.new(0, 5, 0),
			DebounceTime = 0.5,
			Lifetime = 5,
			Debug = true,
		})
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Constants = require(script.Constants)
local Types = require(script.Types)

local Packages = script.Parent
local Signal = require(Packages.Signal)
local Janitor = require(Packages.Janitor)

-- Cache
local HitboxCache: { Types.Hitbox } = {}
local CFrameZero = CFrame.identity

-- Overlap params
local defaultOverlapParams = OverlapParams.new()
defaultOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
defaultOverlapParams.FilterDescendantsInstances = {}

--[[ Helper Functions ]]

local function GetHitPointData(hitboxCFrame: CFrame, targetPart: BasePart): Types.HitPointData?
	if not targetPart.Parent then
		return nil
	end

	local rayOrigin = hitboxCFrame.Position
	local rayDirection = (targetPart.Position - rayOrigin).Unit * 100

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { targetPart }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return {
			Object = targetPart,
			Position = result.Position,
			Normal = result.Normal,
			Material = result.Material,
		}
	end
	return nil
end

local function GetCharacterHitPointData(hitboxCFrame: CFrame, character: Model): Types.HitPointData?
	local pivot = character:GetPivot()
	local rayOrigin = hitboxCFrame.Position
	local rayDirection = (pivot.Position - rayOrigin).Unit * 100

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return {
			Object = character,
			Position = result.Position,
			Normal = result.Normal,
			Material = result.Material,
		}
	end
	return nil
end

local function GetVectorFromType(cframe: CFrame, vectorType: string?): Vector3
	if vectorType == "UpVector" then
		return cframe.UpVector
	elseif vectorType == "RightVector" then
		return cframe.RightVector
	end
	return cframe.LookVector
end

--[[ Hitbox Class ]]

local Hitbox = {} :: Types.Hitbox
Hitbox.__index = Hitbox

--[[
	Creates a new hitbox with the given parameters.
	
	@param params HitboxParams - Configuration table
	@return Hitbox - The created hitbox instance
	
	Example:
		local hitbox = Hitbox.new({
			Size = Vector3.new(10, 10, 10),
			CFrame = CFrame.new(0, 5, 0),
			LookingFor = "Humanoid",
			DebounceTime = 0.5,
			Debug = true,
		})
]]
function Hitbox.new(params: Types.HitboxParams): Types.Hitbox
	local self = setmetatable({}, Hitbox) :: any

	self._janitor = Janitor.new()
	self._destroyed = false

	self.TaggedChars = {}
	self.TaggedObjects = {}
	self.SendingChars = {}
	self.SendingObjects = {}
	self["Destroy"] = self.Destroy

	-- Parse size/shape (support legacy SizeOrPart and new Size/Part)
	local sizeOrPart = params.Size or params.Part or params.SizeOrPart
	assert(sizeOrPart, "[EZ-Hitbox] Must provide Size, Part, or SizeOrPart!")

	if typeof(sizeOrPart) == "Vector3" then
		self.Size = sizeOrPart
		self.SpatialOption = params.SpatialOption or Constants.SPATIAL_OPTION.IN_BOX
	elseif typeof(sizeOrPart) == "number" then
		self.Size = sizeOrPart
		-- Number can be radius (InRadius) or magnitude
		if
			params.SpatialOption == Constants.SPATIAL_OPTION.IN_BOX
			or params.SpatialOption == Constants.SPATIAL_OPTION.IN_PART
		then
			self.Size = Vector3.new(sizeOrPart, sizeOrPart, sizeOrPart)
			self.SpatialOption = params.SpatialOption
		elseif params.SpatialOption == Constants.SPATIAL_OPTION.MAGNITUDE then
			self.SpatialOption = Constants.SPATIAL_OPTION.MAGNITUDE
		else
			self.SpatialOption = Constants.SPATIAL_OPTION.IN_RADIUS
		end
	elseif typeof(sizeOrPart) == "Instance" and sizeOrPart:IsA("BasePart") then
		self.Part = self._janitor:Add(sizeOrPart:Clone())
		self.Size = self.Part.Size
		self.SpatialOption = Constants.SPATIAL_OPTION.IN_PART
		self.Part.Color = Constants.DEBUG_PART.COLOR
		self.Part.CanCollide = false
		self.Part.Anchored = true
	else
		error("[EZ-Hitbox] Invalid Size/Part type: " .. typeof(sizeOrPart))
	end

	-- Generate part for InPart spatial option if needed
	if self.SpatialOption == Constants.SPATIAL_OPTION.IN_PART and not self.Part then
		self:_GeneratePart()
	end

	-- Core settings with defaults
	self.CFrame = params.CFrame or params.InitialCframe or CFrameZero
	self.LookingFor = params.LookingFor or Constants.DEFAULT_LOOKING_FOR
	self.DebounceTime = params.DebounceTime or Constants.DEFAULT_DEBOUNCE_TIME
	self.Lifetime = params.Lifetime or params.LifeTime or Constants.DEFAULT_LIFETIME
	self.DebugMode = params.Debug or Constants.DEFAULT_DEBUG_MODE
	self.DetectHitPoints = params.DetectHitPoints or false
	self.VelocityPrediction = if params.VelocityPrediction ~= nil
		then params.VelocityPrediction
		else Constants.DEFAULT_VELOCITY_PREDICTION
	self.VelocityConstant = params.VelocityConstant or Constants.DEFAULT_VELOCITY_CONSTANT

	-- Optional features
	self.Blacklist = params.Blacklist
	self.Tag = params.Tag
	self.ID = params.ID
	self.DotProductRequirement = params.DotProductRequirement

	-- Create signals
	self.OnHit = self._janitor:Add(Signal.new())
	self.HitObject = self._janitor:Add(Signal.new())
	self.OnHitWithPoint = self._janitor:Add(Signal.new())
	self.HitObjectWithPoint = self._janitor:Add(Signal.new())

	-- Enable debug visualization
	if self.DebugMode then
		self:EnableDebug(true)
	end

	table.insert(HitboxCache, self)

	-- Auto-start if requested
	if params.AutoStart then
		self:Start()
	end

	return self
end

--[[
	Creates a sphere-shaped hitbox.
	
	@param radius number - The radius of the sphere
	@param cframe CFrame? - Position (optional, defaults to origin)
	@param params HitboxParams? - Additional parameters (optional)
	@return Hitbox
	
	Example:
		local hitbox = Hitbox.sphere(10, character.HumanoidRootPart.CFrame)
]]
function Hitbox.sphere(radius: number, cframe: CFrame?, params: Types.HitboxParams?): Types.Hitbox
	local p = params or {} :: Types.HitboxParams
	p.Size = radius
	p.CFrame = cframe or p.CFrame
	p.SpatialOption = Constants.SPATIAL_OPTION.IN_RADIUS
	return Hitbox.new(p)
end

--[[
	Creates a box-shaped hitbox.
	
	@param size Vector3 - The size of the box
	@param cframe CFrame? - Position (optional, defaults to origin)
	@param params HitboxParams? - Additional parameters (optional)
	@return Hitbox
	
	Example:
		local hitbox = Hitbox.box(Vector3.new(10, 5, 10), CFrame.new(0, 5, 0))
]]
function Hitbox.box(size: Vector3, cframe: CFrame?, params: Types.HitboxParams?): Types.Hitbox
	local p = params or {} :: Types.HitboxParams
	p.Size = size
	p.CFrame = cframe or p.CFrame
	p.SpatialOption = Constants.SPATIAL_OPTION.IN_BOX
	return Hitbox.new(p)
end

--[[
	Creates a hitbox from an existing part's shape.
	
	@param part BasePart - The part to use as the hitbox shape
	@param params HitboxParams? - Additional parameters (optional)
	@return Hitbox
	
	Example:
		local hitbox = Hitbox.fromPart(workspace.SwordHitbox)
]]
function Hitbox.fromPart(part: BasePart, params: Types.HitboxParams?): Types.Hitbox
	local p = params or {} :: Types.HitboxParams
	p.Part = part
	p.CFrame = p.CFrame or part.CFrame
	return Hitbox.new(p)
end

--[[ Instance Methods ]]

function Hitbox:LinkToInstance(instance: Instance)
	assert(instance, "[EZ-Hitbox] No instance provided to link to!")
	self._janitor:LinkToInstance(instance)
end

function Hitbox:ClearTaggedCharacters()
	table.clear(self.TaggedChars)
end

function Hitbox:ClearTaggedObjects()
	table.clear(self.TaggedObjects)
end

-- Check if target passes dot product requirement
function Hitbox:_CheckDotProduct(targetPosition: Vector3): boolean
	local req = self.DotProductRequirement
	if not req then
		return true
	end

	local vectorToTarget = (targetPosition - req.PartForVector.CFrame.Position).Unit
	local userVector = GetVectorFromType(req.PartForVector.CFrame, req.VectorType)

	if req.Negative then
		userVector = userVector * -1
	end

	return vectorToTarget:Dot(userVector) >= req.DotProduct
end

-- Get spatial query results based on current settings
function Hitbox:_GetSpatialResults(): { BasePart }
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local exclusions = {}
	if self.Blacklist then
		for _, item in self.Blacklist do
			table.insert(exclusions, item)
		end
	end

	if self.Part then
		table.insert(exclusions, self.Part)
	end

	overlapParams.FilterDescendantsInstances = exclusions

	if self.SpatialOption == Constants.SPATIAL_OPTION.IN_BOX then
		return workspace:GetPartBoundsInBox(self.CFrame, self.Size :: Vector3, overlapParams)
	elseif self.SpatialOption == Constants.SPATIAL_OPTION.IN_RADIUS then
		return workspace:GetPartBoundsInRadius(self.CFrame.Position, self.Size :: number, overlapParams)
	elseif self.SpatialOption == Constants.SPATIAL_OPTION.IN_PART and self.Part then
		return workspace:GetPartsInPart(self.Part, overlapParams)
	end

	return {}
end

-- Process detected parts into characters or objects
function Hitbox:_ProcessTargets(results: { BasePart })
	for _, part in results do
		if not part.Parent then
			continue
		end

		if self.LookingFor == Constants.LOOKING_FOR.HUMANOID then
			local character = part.Parent
			if not character:IsA("Model") then
				continue
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				continue
			end

			-- Tag filtering (if specified)
			if self.Tag and not CollectionService:HasTag(character, self.Tag) then
				continue
			end

			-- Blacklist check
			if self.Blacklist and table.find(self.Blacklist, character) then
				continue
			end

			-- Dot product check
			if not self:_CheckDotProduct(character:GetPivot().Position) then
				continue
			end

			-- Skip if already tagged or in sending queue
			if self.TaggedChars[character] or table.find(self.SendingChars, character) then
				continue
			end

			table.insert(self.SendingChars, character)
		else
			-- Object mode
			if self.Tag and not CollectionService:HasTag(part, self.Tag) then
				continue
			end

			-- Blacklist check (also check if descendant of blacklisted)
			if self.Blacklist then
				local blacklisted = false
				for _, item in self.Blacklist do
					if part == item or part:IsDescendantOf(item :: Instance) then
						blacklisted = true
						break
					end
				end
				if blacklisted then
					continue
				end
			end

			if self.TaggedObjects[part] or table.find(self.SendingObjects, part) then
				continue
			end

			table.insert(self.SendingObjects, part)
		end
	end
end

-- Fire events for accumulated targets
function Hitbox:_FireEvents()
	-- Handle characters
	if #self.SendingChars > 0 then
		local characters = {}
		local hitPointData = {}

		for _, character in self.SendingChars do
			table.insert(characters, character)
			self.TaggedChars[character] = true

			if self.DetectHitPoints then
				local data = GetCharacterHitPointData(self.CFrame, character)
				if data then
					table.insert(hitPointData, data)
				end
			end

			-- Schedule debounce reset
			if self.DebounceTime > 0 then
				task.delay(self.DebounceTime, function()
					if self.TaggedChars and self.TaggedChars[character] then
						self.TaggedChars[character] = nil
					end
				end)
			end
		end

		self.OnHit:Fire(characters)
		if self.DetectHitPoints and #hitPointData > 0 then
			self.OnHitWithPoint:Fire(hitPointData)
		end

		table.clear(self.SendingChars)
	end

	-- Handle objects
	if #self.SendingObjects > 0 then
		local objects = {}
		local hitPointData = {}

		for _, object in self.SendingObjects do
			table.insert(objects, object)
			self.TaggedObjects[object] = true

			if self.DetectHitPoints then
				local data = GetHitPointData(self.CFrame, object)
				if data then
					table.insert(hitPointData, data)
				end
			end

			if self.DebounceTime > 0 then
				task.delay(self.DebounceTime, function()
					self.TaggedObjects[object] = nil
				end)
			end
		end

		self.HitObject:Fire(objects)
		if self.DetectHitPoints and #hitPointData > 0 then
			self.HitObjectWithPoint:Fire(hitPointData)
		end

		table.clear(self.SendingObjects)
	end
end

-- Magnitude-based detection
function Hitbox:_ProcessMagnitude()
	local radius = self.Size :: number
	local position = self.CFrame.Position
	local Players = game:GetService("Players")

	if self.LookingFor ~= Constants.LOOKING_FOR.HUMANOID then
		-- If using tag filtering, use CollectionService
		if self.Tag then
			for _, object in CollectionService:GetTagged(self.Tag) do
				if not object:IsA("BasePart") or not object.Parent then
					continue
				end

				local distance = (position - object.Position).Magnitude
				if distance > radius then
					continue
				end

				-- Blacklist check
				if self.Blacklist then
					local blacklisted = false
					for _, item in self.Blacklist do
						if object == item or object:IsDescendantOf(item :: Instance) then
							blacklisted = true
							break
						end
					end

					if blacklisted then
						continue
					end
				end

				if self.TaggedObjects[object] or table.find(self.SendingObjects, object) then
					continue
				end

				table.insert(self.SendingObjects, object)
			end
		else
			-- Check all parts in workspace (direct children for performance)
			for _, instance in workspace:GetChildren() do
				if not instance:IsA("BasePart") then
					continue
				end

				local distance = (position - instance.Position).Magnitude
				if distance > radius then
					continue
				end

				-- Blacklist check
				if self.Blacklist then
					local blacklisted = false
					for _, item in self.Blacklist do
						if instance == item or instance:IsDescendantOf(item :: Instance) then
							blacklisted = true
							break
						end
					end
					if blacklisted then
						continue
					end
				end

				if self.TaggedObjects[instance] or table.find(self.SendingObjects, instance) then
					continue
				end

				table.insert(self.SendingObjects, instance)
			end
		end

		return
	end

	-- Humanoid detection mode
	-- If using tag filtering, use CollectionService
	if self.Tag then
		for _, instance in CollectionService:GetTagged(self.Tag) do
			local character = if instance:IsA("Model") then instance else instance.Parent
			if not character or not character:IsA("Model") then
				continue
			end

			if not character:FindFirstChildOfClass("Humanoid") then
				continue
			end

			local pivot = character:GetPivot()
			local distance = (position - pivot.Position).Magnitude

			if distance > radius then
				continue
			end

			if self.Blacklist and table.find(self.Blacklist, character) then
				continue
			end

			if not self:_CheckDotProduct(pivot.Position) then
				continue
			end

			if self.TaggedChars[character] or table.find(self.SendingChars, character) then
				continue
			end

			table.insert(self.SendingChars, character)
		end
		return
	end

	-- Check player characters
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character or not character:FindFirstChildOfClass("Humanoid") then
			continue
		end

		local pivot = character:GetPivot()
		local distance = (position - pivot.Position).Magnitude

		if distance > radius then
			continue
		end

		if self.Blacklist and table.find(self.Blacklist, character) then
			continue
		end

		if not self:_CheckDotProduct(pivot.Position) then
			continue
		end

		if self.TaggedChars[character] or table.find(self.SendingChars, character) then
			continue
		end

		table.insert(self.SendingChars, character)
	end

	-- Check NPCs in workspace (only direct children for performance)
	for _, instance in workspace:GetChildren() do
		if not instance:IsA("Model") then
			continue
		end

		local humanoid = instance:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			continue
		end

		-- Skip if it's a player character (already checked)
		local player = Players:GetPlayerFromCharacter(instance)
		if player then
			continue
		end

		local pivot = instance:GetPivot()
		local distance = (position - pivot.Position).Magnitude

		if distance > radius then
			continue
		end

		if self.Blacklist and table.find(self.Blacklist, instance) then
			continue
		end

		if not self:_CheckDotProduct(pivot.Position) then
			continue
		end

		if self.TaggedChars[instance] or table.find(self.SendingChars, instance) then
			continue
		end

		table.insert(self.SendingChars, instance)
	end
end

--[[
	Returns all targets currently inside the hitbox.
	
	@return {Model | BasePart} - Array of characters or objects in the hitbox
]]
function Hitbox:GetParts(): { Model | BasePart }
	local found: { Model | BasePart } = {}

	if self.SpatialOption == Constants.SPATIAL_OPTION.MAGNITUDE then
		self:_ProcessMagnitude()
		for _, char in self.SendingChars do
			table.insert(found, char)
		end
		table.clear(self.SendingChars)
	else
		local results = self:_GetSpatialResults()
		local seen: { [Instance]: boolean } = {}

		for _, part in results do
			if not part.Parent then
				continue
			end

			if self.LookingFor == Constants.LOOKING_FOR.HUMANOID then
				local character = part.Parent
				if not character:IsA("Model") or seen[character] then
					continue
				end
				if not character:FindFirstChildOfClass("Humanoid") then
					continue
				end
				if self.Tag and not CollectionService:HasTag(character, self.Tag) then
					continue
				end
				if self.Blacklist and table.find(self.Blacklist, character) then
					continue
				end
				if not self:_CheckDotProduct(character:GetPivot().Position) then
					continue
				end
				seen[character] = true
				table.insert(found, character)
			else
				if seen[part] then
					continue
				end
				if self.Tag and not CollectionService:HasTag(part, self.Tag) then
					continue
				end
				if self.Blacklist then
					local blacklisted = false
					for _, item in self.Blacklist do
						if part == item or part:IsDescendantOf(item :: Instance) then
							blacklisted = true
							break
						end
					end
					if blacklisted then
						continue
					end
				end
				seen[part] = true
				table.insert(found, part)
			end
		end
	end

	return found
end

--[[
	Starts the hitbox
]]
function Hitbox:Start()
	-- Handle lifetime auto-destroy
	if self.Lifetime > 0 then
		self._lifetimeThread = self._janitor:Add(
			task.delay(self.Lifetime, function()
				if not self._destroyed then
					self:Destroy()
				end
			end),
			nil,
			"lifetimeThread"
		)
	end

	if self.Part and self.DebugMode then
		self.Part.Parent = workspace
	end

	self.RunServiceConnection = self._janitor:Add(RunService.Heartbeat:Connect(function()
		if self.PartWeld then
			self:SetCFrame(self.PartWeld.CFrame * (self.PartWeldOffset or CFrameZero))
		end

		if self.SpatialOption == Constants.SPATIAL_OPTION.MAGNITUDE then
			self:_ProcessMagnitude()
		else
			local results = self:_GetSpatialResults()
			self:_ProcessTargets(results)
		end

		self:_FireEvents()
	end))
end

--[[
	Stops the hitbox detection without destroying it.
]]
function Hitbox:Stop()
	self._janitor:Remove("lifetimeThread")

	if self.RunServiceConnection then
		self.RunServiceConnection:Disconnect()
		self.RunServiceConnection = nil
	end

	if self.Part then
		self.Part.Parent = nil
	end
end

--[[
	Sets the hitbox position
	
	@param newCFrame CFrame - The new position/orientation
]]
function Hitbox:SetCFrame(newCFrame: CFrame)
	if self.VelocityPrediction and self.PartWeld and RunService:IsServer() then
		local velocity = newCFrame:VectorToObjectSpace(self.PartWeld.AssemblyLinearVelocity)
		newCFrame = newCFrame * CFrame.new(velocity / self.VelocityConstant)
	end

	self.CFrame = newCFrame

	if self.Part then
		self.Part.CFrame = newCFrame
	end
end

--[[
	Welds the hitbox to follow a part.
	
	@param part BasePart - The part to follow
	@param offset CFrame? - Optional offset from the part
]]
function Hitbox:WeldTo(part: BasePart, offset: CFrame?)
	self.PartWeld = part
	self.PartWeldOffset = offset
end

function Hitbox:Unweld()
	self.PartWeld = nil
	self.PartWeldOffset = nil
end

function Hitbox:SetWeldOffset(offset: CFrame)
	self.PartWeldOffset = offset
end

function Hitbox:EnableVelocityPrediction(enabled: boolean)
	self.VelocityPrediction = enabled
end

--[[
	Enables or disables debug visualization.
	
	@param enabled boolean - Whether to show the debug part
]]
function Hitbox:EnableDebug(enabled: boolean)
	self.DebugMode = enabled

	if enabled then
		if not self.Part then
			self:_GeneratePart()
		end

		if self.Part then
			self.Part.Transparency = Constants.DEBUG_PART.VISIBLE_TRANSPARENCY
			self.Part.Parent = workspace
		end
	else
		if self.Part then
			self.Part.Transparency = Constants.DEBUG_PART.INVISIBLE_TRANSPARENCY
			if self.SpatialOption ~= Constants.SPATIAL_OPTION.IN_PART then
				self.Part.Parent = nil
			end
		end
	end
end

function Hitbox:_GeneratePart()
	if self.Part then
		return
	end

	local part = Instance.new("Part")
	part.Name = "Hitbox_Debug"
	part.Color = Constants.DEBUG_PART.COLOR
	part.Transparency = if self.DebugMode
		then Constants.DEBUG_PART.VISIBLE_TRANSPARENCY
		else Constants.DEBUG_PART.INVISIBLE_TRANSPARENCY
	part.Anchored = true
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CFrame = self.CFrame

	if typeof(self.Size) == "Vector3" then
		part.Size = self.Size
	elseif typeof(self.Size) == "number" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(self.Size * 2, self.Size * 2, self.Size * 2)
	end

	self.Part = self._janitor:Add(part)
end

--[[ Static Methods ]]

--[[
	Destroys all hitboxes with the specified ID.
	
	@param id string | number - The ID to match
]]
function Hitbox.ClearHitboxesByID(id: string | number)
	for i = #HitboxCache, 1, -1 do
		local hitbox = HitboxCache[i]
		if hitbox.ID == id then
			hitbox:Destroy()
		end
	end
end

--[[
	Returns the cache of all active hitboxes.
	
	@return {Hitbox}
]]
function Hitbox.GetHitboxCache(): { Types.Hitbox }
	return HitboxCache
end

--[[
	Destroys the hitbox and cleans up all resources.
]]
function Hitbox:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	-- Remove the hitbox from the cache
	local index = table.find(HitboxCache, self)
	if index then
		table.remove(HitboxCache, index)
	end

	if self._janitor and not self._janitor.CurrentlyCleaning then
		self._janitor:Destroy()
	end

	table.clear(self)
	setmetatable(self :: any, nil)
	self = nil
end

return Hitbox
