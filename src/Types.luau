local Types = {}

-- Packages
local Signal = require(script.Parent.Parent.Signal)
local Timer = require(script.Parent.Parent.Timer)
local Janitor = require(script.Parent.Parent.Janitor)

-- Types
export type JanitorType = typeof(Janitor.new())
export type TimerType = typeof(Timer.new())

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
	SizeOrPart: Vector3 | number | BasePart,
	SpatialOption: ("InBox" | "InRadius" | "InPart")?,
	InitialCframe: CFrame?,
	Blacklist: { Model }?,
	DebounceTime: number?,
	DotProductRequirement: DotProductRequirement?,
	ID: (string | number)?,
	VelocityPrediction: boolean?,
	Debug: boolean?,
	LifeTime: number?,
	LookingFor: ("Humanoid" | "Object")?,
	DetectHitPoints: boolean?,

	-- Private fields
	_Tick: number?,
}
type Character = Model&{
	Humanoid:Humanoid&{Animator:Animator},PrimaryPart:Part,HumanoidRootPart:Part,
	--R6
	Torso:Part,["Left Arm"]:Part,["Right Arm"]:Part,["Left Leg"]:Part,["Right Leg"]:Part,
	--R15
	UpperTorso:Part,LowerTorso:Part,["LeftUpperArm"]:Part,["LeftLowerArm"]:Part,["RightUpperArm"]:Part,["RightLowerArm"]:Part,
	["LeftUpperLeg"]:Part,["LeftLowerLeg"]:Part,["RightUpperLeg"]:Part,["RightLowerLeg"]:Part
}
export type Hitbox = {

	-- Fields

	Size: Vector3 | number,
	Mode: "Magnitude" | "Part",
	SpatialOption: "InBox" | "InRadius" | "InPart" | "Magnitude",
	LookingFor: "Humanoid" | "Object",
	DebounceTime: number,
	Part: BasePart?,
	CFrame: CFrame,
	DotProductRequirement: DotProductRequirement?,
	TaggedChars: { [Model]: boolean },
	TaggedObjects: { [BasePart]: boolean },
	ID: (string | number)?,
	TickVal: number,
	Blacklist: {}?,
	SendingChars: { Model },
	SendingObjects: { BasePart },
	OnHit: Signal.Signal<{Character}>,
	HitObject: Signal.Signal<BasePart>,
	OnHitWithPoint: Signal.Signal<{HitPointData}>,
	HitObjectWithPoint: Signal.Signal<{HitPointData}>,
	DetectHitPoints: boolean,
	RunServiceConnection: RBXScriptConnection?,
	PartWeld: BasePart?,
	PartWeldOffset: CFrame?,
	VelocityPrediction: boolean?,
	DebugMode: boolean,
	Lifetime: number,
	_janitor: JanitorType,

	-- Methods

	new: (HitboxParams) -> (Hitbox, boolean),
	LinkToInstance: (self: Hitbox, instance: Instance) -> (),
	ClearHitboxesByID: (ID: string | number) -> (),
	GetHitboxCache: () -> { Hitbox },
	ClearTaggedCharacters: (self: Hitbox) -> (),
	GetParts: (self: Hitbox) -> { Model | BasePart },
	Start: (self: Hitbox) -> (),
	Stop: (self: Hitbox) -> (),
	SetCFrame: (self: Hitbox, Cframe: CFrame) -> (),
	Destroy: (self: Hitbox) -> (),
	WeldTo: (self: Hitbox, PartToWeldTo: BasePart, OffsetCFrame: CFrame?) -> (),
	Unweld: (self: Hitbox) -> (),
	SetWeldOffset: (self: Hitbox, OffsetCFrame: CFrame) -> (),
	EnableVelocityPrediction: (self: Hitbox, state: boolean) -> (),
	EnableDebug: (self: Hitbox, state: boolean) -> (),
	-- Private Methods (Don't touch unless you know what you're doing!)

	_SiftThroughSendingCharsAndFire: (self: Hitbox) -> (),
	_SiftThroughSendingObjectsAndFire: (self: Hitbox) -> (),
	_GeneratePart: (self: Hitbox) -> (),
	-- Private Fields (Don't touch unless you know what you're doing!)
	Timer: TimerType?,
}

return Types
