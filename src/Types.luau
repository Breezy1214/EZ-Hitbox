local Types = {}

-- Types
export type SignalType = any
export type SignalConnection = RBXScriptConnection
export type JanitorType = any
export type TimerType = any

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

export type Hitbox = {

	-- Fields
	__index: Hitbox,

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
	OnHit: SignalType,
	HitObject: SignalType,
	OnHitWithPoint: SignalType,
	HitObjectWithPoint: SignalType,
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
