--!strict
local Constants = {}

-- Remote event settings
Constants.REMOTE_EVENT_NAME = "HitboxClassRemote"
Constants.HITBOX_GUI_NAME = "HitboxClassContainer"

-- Module settings folder
Constants.SETTINGS_FOLDER_NAME = "HitboxSettings"
Constants.ALIVE_FOLDER_SETTING_NAME = "Alive Folder"
Constants.PROJECTILE_FOLDER_SETTING_NAME = "Projectile Folder"
Constants.VELOCITY_CONSTANT_SETTING_NAME = "Velocity Prediction Constant"

-- Default values
Constants.DEFAULT_VELOCITY_CONSTANT = 6
Constants.DEFAULT_DEBOUNCE_TIME = 0
Constants.DEFAULT_LIFETIME = 0
Constants.DEFAULT_VECTOR_TYPE = "LookVector"
Constants.DEFAULT_DEBUG_MODE = false
Constants.DEFAULT_VELOCITY_PREDICTION = true

-- Hitbox mode types
Constants.HITBOX_MODE = {
	MAGNITUDE = "Magnitude",
	PART = "Part",
}

-- Spatial option types
Constants.SPATIAL_OPTION = {
	IN_BOX = "InBox",
	IN_RADIUS = "InRadius",
	IN_PART = "InPart",
	MAGNITUDE = "Magnitude",
}

-- Looking for types
Constants.LOOKING_FOR = {
	HUMANOID = "Humanoid",
	OBJECT = "Object",
}

-- Remote event modes
Constants.REMOTE_MODE = {
	CLEAR = "Clr",
	NEW = "New",
	START = "Start",
	STOP = "Stop",
	CLEAR_TAG = "ClrTag",
	WELD = "Weld",
	WELD_OFFSET = "WeldOfs",
	UNWELD = "Unweld",
	POSITION_CHANGE = "PosCh",
	DEBUG = "Dbg",
	DESTROY = "Des",
}

-- Part visualization settings
Constants.DEBUG_PART = {
	COLOR = Color3.new(1, 0, 0),
	VISIBLE_TRANSPARENCY = 0.45,
	INVISIBLE_TRANSPARENCY = 1,
}

-- Client response timeout
Constants.CLIENT_RESPONSE_TIMEOUT = 1.5

return Constants
