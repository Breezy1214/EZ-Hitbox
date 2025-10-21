--!strict
local Constants = {}

-- Module settings folder
Constants.SETTINGS_FOLDER_NAME = "HitboxSettings"
Constants.ALIVE_FOLDER_SETTING_NAME = "Alive Folder"
Constants.IGNORE_FOLDER_SETTING_NAME = "Ignore Folder"
Constants.VELOCITY_CONSTANT_SETTING_NAME = "Velocity Prediction Constant"
Constants.DebugLog = true

-- Default values
Constants.DEFAULT_VELOCITY_CONSTANT = 6
Constants.DEFAULT_DEBOUNCE_TIME = 0
Constants.DEFAULT_LIFETIME = 0
Constants.DEFAULT_VECTOR_TYPE = "LookVector"
Constants.DEFAULT_DEBUG_MODE = false
Constants.DEFAULT_VELOCITY_PREDICTION = true

-- Hitbox mode types
Constants.HITBOX_MODE = {
	MAGNITUDE = "Magnitude" :: "Magnitude",
	PART = "Part" :: "Part",
}

-- Spatial option types
Constants.SPATIAL_OPTION = {
	IN_BOX = "InBox" :: "InBox",
	IN_RADIUS = "InRadius" :: "InRadius",
	IN_PART = "InPart" :: "InPart",
	MAGNITUDE = "Magnitude" :: "Magnitude",
}

-- Looking for types
Constants.LOOKING_FOR = {
	HUMANOID = "Humanoid" :: "Humanoid",
	OBJECT = "Object" :: "Object",
}

-- Part visualization settings
Constants.DEBUG_PART = {
	COLOR = Color3.new(1, 0, 0),
	VISIBLE_TRANSPARENCY = 0.45,
	INVISIBLE_TRANSPARENCY = 1,
}

return Constants
