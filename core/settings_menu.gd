extends Control

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
@onready var text_edit: ComponentTextInput = $%TextInput
@onready var _api_key: String = settings_manager.get_value("plugin.steamgriddb", "api_key", "")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_edit.text = _api_key
	text_edit.text_submitted.connect(_on_line_edit_text_submitted)
	text_edit.focus_exited.connect(_on_line_edit_focus_exited)


func _on_line_edit_focus_exited() -> void:
	settings_manager.set_value("plugin.steamgriddb", "api_key", text_edit.text)


func _on_line_edit_text_submitted(new_text: String) -> void:
	settings_manager.set_value("plugin.steamgriddb", "api_key", new_text)
