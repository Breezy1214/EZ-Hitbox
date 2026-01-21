--!strict
local Types = {}

-- Packages
local Janitor = require(script.Parent.Parent.Janitor)

-- Types
export type JanitorType = typeof(Janitor.new())

export type DotProductRequirement = {
	DotProduct: number,
	PartForVector: BasePart,
	VectorType: ("LookVector" | "UpVector" | "RightVector")?,
	Negative: boolean?,
}

export type HitPointData = {
	Object: Model | BasePart,
	Position: Vector3,
	Normal: Vector3,
	Material: Enum.Material,
}


export type HitboxParams = {
	-- Shape definition
	Size: (Vector3 | number)?, -- Vector3 for box, number for sphere/radius
	Part: BasePart?, -- Use existing part's shape

	-- Legacy support (deprecated, use Size instead)
	SizeOrPart: (Vector3 | number | BasePart)?,
	InitialCframe: CFrame?, -- Deprecated: use CFrame instead
	LifeTime: number?, -- Deprecated: use Lifetime instead

	-- Core settings 
	CFrame: CFrame?, -- Initial position (default: CFrame.identity)
	SpatialOption: ("InBox" | "InRadius" | "InPart" | "Magnitude")?, -- Detection method (auto-detected)
	LookingFor: ("Humanoid" | "Object")?, -- What to detect (default: "Humanoid")

	-- Filtering
	Blacklist: { Instance }?, -- Instances to ignore
	Tag: string?, -- Only detect instances with this CollectionService tag (optional)

	-- Timing
	DebounceTime: number?, -- Cooldown per target (default: 0)
	Lifetime: number?, -- Auto-destroy after N seconds (default: 0 = never)
	AutoStart: boolean?, -- Start detection immediately (default: false)

	-- Features
	Debug: boolean?, -- Show visual hitbox (default: false)
	DetectHitPoints: boolean?, -- Enable hit position data (default: false)
	VelocityPrediction: boolean?, -- Predict movement (default: true)
	VelocityConstant: number?, -- Velocity prediction divisor (default: 6)
	DotProductRequirement: DotProductRequirement?, -- Directional filtering

	-- Internal
	ID: (string | number)?, -- For batch operations
}

type Character = Model & {
	Humanoid: Humanoid & { Animator: Animator },
	PrimaryPart: Part,
	HumanoidRootPart: Part,
	--R6
	Torso: Part,
	["Left Arm"]: Part,
	["Right Arm"]: Part,
	["Left Leg"]: Part,
	["Right Leg"]: Part,
	--R15
	UpperTorso: Part,
	LowerTorso: Part,
	["LeftUpperArm"]: Part,
	["LeftLowerArm"]: Part,
	["RightUpperArm"]: Part,
	["RightLowerArm"]: Part,
	["LeftUpperLeg"]: Part,
	["LeftLowerLeg"]: Part,
	["RightUpperLeg"]: Part,
	["RightLowerLeg"]: Part,
}

export type Hitbox = {
	-- Public Fields
	Size: Vector3 | number,
	CFrame: CFrame,
	SpatialOption: "InBox" | "InRadius" | "InPart" | "Magnitude",
	LookingFor: "Humanoid" | "Object",
	DebounceTime: number,
	Part: BasePart?,
	DotProductRequirement: DotProductRequirement?,
	ID: (string | number)?,
	Blacklist: { Instance }?,
	Tag: string?,
	VelocityPrediction: boolean,
	VelocityConstant: number,
	DebugMode: boolean,
	Lifetime: number,
	DetectHitPoints: boolean,

	-- Events 
	OnHit: any,
	HitObject: any,
	OnHitWithPoint: any,
	HitObjectWithPoint: any,

	-- Internal
	TaggedChars: { [Model]: boolean },
	TaggedObjects: { [BasePart]: boolean },
	SendingChars: { Model },
	SendingObjects: { BasePart },
	RunServiceConnection: RBXScriptConnection?,
	PartWeld: BasePart?,
	PartWeldOffset: CFrame?,
	_janitor: JanitorType,
	_destroyed: boolean?,
	_lifetimeThread: thread?,

	-- Constructor & Factory Methods
	new: (HitboxParams) -> Hitbox,
	sphere: (radius: number, cframe: CFrame?, params: HitboxParams?) -> Hitbox,
	box: (size: Vector3, cframe: CFrame?, params: HitboxParams?) -> Hitbox,
	fromPart: (part: BasePart, params: HitboxParams?) -> Hitbox,

	-- Instance Methods
	Start: (self: Hitbox) -> (),
	Stop: (self: Hitbox) -> (),
	Destroy: (self: Hitbox) -> (),
	GetParts: (self: Hitbox) -> { Model | BasePart },
	SetCFrame: (self: Hitbox, cframe: CFrame) -> (),
	WeldTo: (self: Hitbox, part: BasePart, offset: CFrame?) -> (),
	Unweld: (self: Hitbox) -> (),
	SetWeldOffset: (self: Hitbox, offset: CFrame) -> (),
	LinkToInstance: (self: Hitbox, instance: Instance) -> (),
	ClearTaggedCharacters: (self: Hitbox) -> (),
	ClearTaggedObjects: (self: Hitbox) -> (),
	EnableDebug: (self: Hitbox, enabled: boolean) -> (),
	EnableVelocityPrediction: (self: Hitbox, enabled: boolean) -> (),

	-- Static Methods
	ClearHitboxesByID: (id: string | number) -> (),
	GetHitboxCache: () -> { Hitbox },

	-- Private
	_ProcessTargets: (self: Hitbox, results: { BasePart }) -> (),
	_ProcessMagnitude: (self: Hitbox) -> (),
	_FireEvents: (self: Hitbox) -> (),
	_GeneratePart: (self: Hitbox) -> (),
	_GetSpatialResults: (self: Hitbox) -> { BasePart },
	_CheckDotProduct: (self: Hitbox, targetPosition: Vector3) -> boolean,
}

return Types
