@tool
extends Object

var tree : SceneTree

static var updates_available := false
static var latest_tag : String
static var latest_url : String

signal updates_checked()
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

	await updates_checked


func _on_request_completed(result, response_code, response_headers, body) -> void:

	# Checks the response code
	if response_code != 200:
		push_error("Failed to get SceneMap Plugin updates: Error ", response_code)
		updates_checked.emit()
		return

	# Parses the json
	var json := JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		push_error("Failed to get SceneMap Plugin updates: ", json.error_string)
		updates_checked.emit()
		return
	
	# Compares the current version with the latest version
	var latest_release = json.data
	latest_tag = latest_release["tag_name"]
	latest_url = latest_release["html_url"]
	
	if latest_tag == SceneMapConstants.VERSION:
		print("SceneMap Plugin up-to-date (" + SceneMapConstants.VERSION + ") - Release notes: " + latest_url)
		updates_available = false

	else:
		print("There is a new SceneMap Plugin version: " + latest_tag + " - Release notes: " + latest_url)
		updates_available = true

	updates_checked.emit()
	

func download_updates() -> void:

	# If didn't check before, checks for updates
	if !latest_tag or latest_tag == "":
		check_for_updates()
		await updates_checked

	# If there are no updates, returns
	if !updates_available:
		print("There are no new updates available for SceneMap Plugin")
		return

	print("Updating SceneMap Plugin to the version " + latest_tag + "...")

	# Gets the source code url
	var release_url = str(SceneMapConstants.GITHUB_LINK, "/archive/refs/tags/", latest_tag, ".zip")

	# Prepares a new request to download the source code
	var http := HTTPRequest.new()
	var headers := _get_headers()
	tree.root.add_child(http)
	http.request_completed.connect(_on_zip_downloaded)

	# Makes the request
	http.request(release_url, headers, HTTPClient.METHOD_GET)


func _on_zip_downloaded(result, response_code, response_headers, body) -> void:
	
	# Checks the response code
	if response_code != 200:
		push_error("Failed to get SceneMap Plugin updates: Error ", response_code)
		update_completed.emit()
		return

	# Creates the zip file
	var zip = FileAccess.open(SceneMapConstants.UPDATE_PATH, FileAccess.WRITE)
	if zip.get_open_error() != OK:
		push_error("Failed to get SceneMap Plugin updates: unable to download source files")
		update_completed.emit()
		return
	
	zip.store_buffer(body)
	zip.close()

	# Opens the zip file
	var zip_reader := ZIPReader.new()
	var zip_result := zip_reader.open(SceneMapConstants.UPDATE_PATH)

	if zip_result != OK:
		push_error("Failed to get SceneMap Plugin updates: unable to unzip source files")
		update_completed.emit()
		return

	# Gets the base path
	var base_path := zip_reader.get_files()[0].split("/")[0] + "/"

	# Iterates each file in the zip
	var folders_to_create := []
	var files_to_create := []

	for file_path in zip_reader.get_files():

		var file := zip_reader.read_file(file_path)

		# Defines the file path
		var new_path := file_path.replace(base_path, "")

		# If the path ends with "/" it's a folder, set it to create
		if new_path.ends_with("/"):
			folders_to_create.append("res://" + new_path)

		# If the path is in the root folder, move it to the plugin's folder
		elif new_path.split("/").size() == 1:
			if new_path == "LICENSE" or new_path == "readme.md":
				files_to_create.append([file, SceneMapConstants.PLUGIN_PATH + new_path])

		# Any other path is okay as it is
		else:
			files_to_create.append([file, "res://" + new_path])

	# Creates the folders
	for folder in folders_to_create:
		var abs_path = ProjectSettings.globalize_path(folder)
		if not DirAccess.dir_exists_absolute(abs_path):
			DirAccess.make_dir_recursive_absolute(abs_path)

	# Creates the files
	for file_info in files_to_create:
		var file := FileAccess.open(file_info[1], FileAccess.WRITE)
		file.store_buffer(file_info[0])

	# Closes the reader and deletes the zip
	zip_reader.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SceneMapConstants.UPDATE_PATH))

	print("SceneMap Plugin succesfully updated!")

	# Resets the editor
	await tree.create_timer(2.0).timeout
	EditorInterface.restart_editor(true)


func _get_headers() -> Array:
	return [
		"Accept: application/vnd.github+json",
		"Authorization: Bearer " + SceneMapConstants.GITHUB_TOKEN
	]