extends Plugin

const settings := preload("res://plugins/steamgriddb/core/settings_menu.tscn")
const boxart := preload("res://plugins/steamgriddb/core/boxart_steamgriddb.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(boxart.instantiate())
	
	logger = Log.get_logger("SteamGridDB", Log.LEVEL.DEBUG)
	logger.info("SteamGridDB plugin ready")


func get_settings_menu() -> Control:
	return settings.instantiate()
