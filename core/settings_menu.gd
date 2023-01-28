extends Control

@onready var text_edit: LineEdit = $VBoxContainer/HBoxContainer/LineEdit
@onready var _api_key: String = SettingsManager.get_value("plugin.steamgriddb", "api_key", "")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_edit.text = _api_key


func _on_line_edit_focus_exited() -> void:
	SettingsManager.set_value("plugin.steamgriddb", "api_key", text_edit.text)


func _on_line_edit_text_submitted(new_text: String) -> void:
	SettingsManager.set_value("plugin.steamgriddb", "api_key", new_text)
