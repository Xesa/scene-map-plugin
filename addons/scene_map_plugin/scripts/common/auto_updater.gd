@tool
extends Object

var tree : SceneTree

signal update_completed()


func _init(_tree : SceneTree) -> void:
	tree = _tree


func check_for_updates() -> void:

	# Creates a new request
	var http := HTTPRequest.new()
	var headers := _get_headers()
	tree.root.add_child(http)
	http.request_completed.connect(_on_request_completed)

	# Makes the request
	http.request(SceneMapConstants.GITHUB_API, headers)


func _on_request_completed(result, response_code, response_headers, body) -> void:

	# Checks the response code
	if response_code != 200:
		push_error("Failed to get SceneMap Plugin updates: Error ", response_code)
		update_completed.emit()
		return

	# Parses the json
	var json := JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		push_error("Failed to get SceneMap Plugin updates: ", json.error_string)
		update_completed.emit()
		return

	# Checks if there are any releases
	if json.data.size() == 0:
		update_completed.emit()
		return
	
	# Compares the current version with the latest version
	var latest_release = json.data[0]
	var latest_tag = latest_release["tag_name"]

	if latest_tag == SceneMapConstants.VERSION:
		print("SceneMap Plugin up-to-date - Version " + SceneMapConstants.VERSION)
		update_completed.emit()
		return
	
	# Gets the source code url
	var release_url = str(SceneMapConstants.GITHUB_LINK, "/archive/refs/tags/", latest_tag, ".zip")

	# Prepares a new request to download the source code
	print("Updating SceneMap Plugin to the version " + latest_tag + "...")

	var http := HTTPRequest.new()
	var headers := _get_headers()
	tree.root.add_child(http)
	http.request_completed.connect(_on_zip_downloaded.bind(SceneMapConstants.UPDATE_PATH))

	# Makes the request
	http.request(release_url, headers, HTTPClient.METHOD_GET)
	

func _on_zip_downloaded(result, response_code, response_headers, body, save_path) -> void:
	
	# Checks the response code
	if response_code != 200:
		push_error("Failed to get SceneMap Plugin updates: Error ", response_code)
		update_completed.emit()
		return

	# Creates the zip file
	var zip = FileAccess.open(save_path, FileAccess.WRITE)
	if zip.get_open_error() != OK:
		push_error("Failed to get SceneMap Plugin updates: unable to download source files")
		update_completed.emit()
		return
	
	zip.store_buffer(body)
	zip.close()

	# Opens the zip file
	var zip_reader := ZIPReader.new()
	var zip_result := zip_reader.open(save_path)

	if zip_result != OK:
		push_error("Failed to get SceneMap Plugin updates: unable to unzip source files")
		update_completed.emit()
		return

	# Iterates each file in the zip
	for file_path in zip_reader.get_files():

		var file := zip_reader.read_file(file_path)

		# Defines the file path
		var new_path := strip_prefix(file_path)

		if new_path.split("/").size() == 1:
			new_path = SceneMapConstants.PLUGIN_PATH + new_path
		else:
			new_path = "res://" + new_path

		print(new_path)

	zip_reader.close()


func _get_headers() -> Array:
	return [
		"Accept: application/vnd.github+json",
		"Authorization: Bearer " + SceneMapConstants.GITHUB_TOKEN
	]


func strip_prefix(file_path : String) -> String:
	var parts = file_path.split("/", false)
	parts.remove_at(0)
	return "/".join(parts)