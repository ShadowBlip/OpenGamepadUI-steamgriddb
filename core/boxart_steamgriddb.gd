extends BoxArtProvider

const base_url := "https://www.steamgriddb.com/api/v2"
const cache_folder := "steamgriddb"

@onready var _api_key: String = SettingsManager.get_value("plugin.steamgriddb", "api_key", "")
@onready var _api_client := $SteamGridApiClient as HTTPAPIClient
@onready var http_image_fetcher := $HTTPImageFetcher as HTTPImageFetcher


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if _api_key == "":
		NotificationManager.show(Notification.new("SteamGridDB API Key required"))
		return
	_api_client.cache_folder = cache_folder
	_api_client.base_url = base_url
	_api_client.headers = ["Authorization: Bearer " + _api_key]
	SettingsManager.setting_changed.connect(_on_setting_changed)


func _on_setting_changed(section: String, key: String, value: Variant) -> void:
	if section != "plugin.steamgriddb":
		return
	if key != "api_key":
		return
	_api_key = value as String
	_api_client.headers = ["Authorization: Bearer " + _api_key]
	logger.info("API Key changed")


# To be implemented by a provider
func get_boxart(item: LibraryItem, kind: LAYOUT) -> Texture2D:
	if _api_key == "":
		return null

	# Search for the game
	var result := await _search(item) as Dictionary
	var game_id := _get_game_id_from_search(result)
	if game_id < 0:
		logger.debug("Unable to find result for: " + item.name)
		return null
	
	# Fetch based on the kind of boxart
	# NOTE: returns the first found image, for now
	var url := ""
	match kind:
		LAYOUT.GRID_PORTRAIT, LAYOUT.GRID_LANDSCAPE:
			var grids := await _get_grids(game_id, kind) as Dictionary
			if "data" in grids and grids["data"] is Array:
				var data := grids["data"] as Array
				if data.size() == 0:
					return null
				var entry := data[0] as Dictionary
				url = entry["url"] as String
		LAYOUT.BANNER:
			var banners := await _get_heroes(game_id) as Dictionary
			if "data" in banners and banners["data"] is Array:
				var data := banners["data"] as Array
				if data.size() == 0:
					return null
				var entry := data[0] as Dictionary
				url = entry["url"] as String
		LAYOUT.LOGO:
			var logos := await _get_logos(game_id) as Dictionary
			if "data" in logos and logos["data"] is Array:
				var data := logos["data"] as Array
				if data.size() == 0:
					return null
				var entry := data[0] as Dictionary
				url = entry["url"] as String
	
	if url != "":
		return await http_image_fetcher.fetch(url, Cache.FLAGS.LOAD|Cache.FLAGS.SAVE)

	return null


func _get_game_id_from_search(search_result: Dictionary) -> int:
	if not "data" in search_result:
		return -1
	if not search_result["data"] is Array:
		return -1
	var data := search_result["data"] as Array
	if data.size() == 0:
		return -1
	var entry := data[0] as Dictionary
	return entry["id"]


# Query any SteamGridDB API
func _query(query: String, caching_flags: int = Cache.FLAGS.LOAD|Cache.FLAGS.SAVE) -> Dictionary:
	# Make the request
	var response := await _api_client.request(query, caching_flags) as HTTPAPIClient.Response
	if response == null:
		logger.debug("Unable to send API request: " + query)
		return {}
	if response.result != OK:
		logger.debug("Got error response for " + query + ": " + str(response.result))
		return {}
	var data := response.get_json()
	if response.code != 200:
		logger.debug("Got non-200 HTTP response for " + query + ": " + str(response.code))
		if data != null:
			logger.debug("Error response: " + str(data))
		return {}

	return data


# Search for games using the given library item name
func _search(item: LibraryItem) -> Dictionary:
	var query := "/search/autocomplete/"+item.name
	var response := await _query(query) as Dictionary
	return response


func _get_grids(game_id: int, kind: LAYOUT) -> Dictionary:
	var params := "?dimensions=600x900"
	if kind == LAYOUT.GRID_LANDSCAPE:
		params = "?dimensions=920x430"
	var query := "/grids/game/"+str(game_id)+params
	var response := await _query(query) as Dictionary
	return response


func _get_heroes(game_id: int):
	var query := "/heroes/game/"+str(game_id)
	var response := await _query(query) as Dictionary
	return response


func _get_logos(game_id: int):
	var query := "/logos/game/"+str(game_id)
	var response := await _query(query) as Dictionary
	return response
