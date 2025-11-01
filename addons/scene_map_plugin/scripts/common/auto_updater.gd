@tool
extends Object
## SM_AutoUpdater
##
##This script is responsible for checking and downloading updates of the SceneMap Plugin from GitHub.
## 
## Main methods:[br]
## - check_for_updates(): checks GitHub for new plugin releases[br]
## - download_updates(): downloads and installs the latest release[br]
## - check_token_validity(): verifies the GitHub token[br]

const SM_ResourceTools := preload(SceneMapConstants.RESOURCE_TOOLS)
const SceneMap := preload(SceneMapConstants.SCENE_MAP)

var plugin : SceneMap
var tree : SceneTree
var is_token_valid := false

## Emitted when the script finishes checking for updates, whether if it was succesful or not.
signal updates_checked()
## Emitted when the script finishes downloading and installing the updates, whether if it was succesful or not.
signal update_completed()
## Emitted when the script finishes checking the token's validiy, wheter if it was succesful or not.
signal validity_checked()


func _init() -> void:
	plugin = Engine.get_singleton("SceneMapPlugin")
	tree = plugin.get_tree()

#region CheckUpdates

## Checks GitHub API for new releases of the plugin.
## Once the HTTP request is sent, the [_on_request_completed()] method is fired.
## Emits the signal [updates_checked] when finished.
func check_for_updates() -> void:

	# Checks if the token is available
	if not await parse_token():
		return

	# Creates a new request
	var http := HTTPRequest.new()
	var headers := _get_headers(plugin.GITHUB_TOKEN)
	tree.root.add_child(http)
	http.request_completed.connect(_on_request_completed)

	# Makes the request
	http.request(SceneMapConstants.GITHUB_API, headers)

	await updates_checked


## Callback for GitHub API response after [check_for_updates()] method.
## Parses JSON, extracts tag + release URL and sets [updates_available].
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
	plugin.LATEST_VERSION = latest_release["tag_name"]
	plugin.LATEST_URL = latest_release["html_url"]
	
	if plugin.LATEST_VERSION == plugin.VERSION:
		print("SceneMap Plugin up-to-date (" + plugin.VERSION + ") - Release notes: " + plugin.LATEST_URL)
		plugin.UPDATES_AVAILABLE = false

	else:
		print("There is a new SceneMap Plugin version: " + plugin.LATEST_VERSION + " - Release notes: " + plugin.LATEST_URL)
		plugin.UPDATES_AVAILABLE = true
		plugin.panel.update_button.toggle_visibility(true)

	updates_checked.emit()
	
#endregion

#region DownloadUpdates

## Downloads and installs the latest plugin version if available.
## Once the HTTP request is sent, the [_on_zip_downloaded()] method is fired.
## Emits [update_completed] after the update attempt ends.
func download_updates() -> void:

	if !plugin.GITHUB_TOKEN:
		return

	# If didn't check before, checks for updates
	if !plugin.LATEST_VERSION or plugin.LATEST_VERSION == "":
		check_for_updates()
		await updates_checked

	# If there are no updates, returns
	if !plugin.UPDATES_AVAILABLE:
		print("There are no new updates available for SceneMap Plugin")
		return

	print("Updating SceneMap Plugin to the version " + plugin.LATEST_VERSION + "...")

	# Gets the source code url
	var release_url = str(SceneMapConstants.GITHUB_LINK, "/archive/refs/tags/", plugin.LATEST_VERSION, ".zip")

	# Prepares a new request to download the source code
	var http := HTTPRequest.new()
	var headers := _get_headers(plugin.GITHUB_TOKEN)
	tree.root.add_child(http)
	http.request_completed.connect(_on_zip_downloaded)

	# Makes the request
	http.request(release_url, headers, HTTPClient.METHOD_GET)



## Callback when the ZIP download finishes after the [download_updates()] method.
## Extracts the ZIP, installs plugin files and triggers editor restart.
func _on_zip_downloaded(result, response_code, response_headers, body) -> void:
	
	# Checks the response code
	if response_code != 200:
		push_error("Failed to get SceneMap Plugin updates: Error ", response_code)
		update_completed.emit()
		return

	# Creates the zip file
	var zip = FileAccess.open(plugin.UPDATE_PATH, FileAccess.WRITE)
	if zip.get_open_error() != OK:
		push_error("Failed to get SceneMap Plugin updates: unable to download source files")
		update_completed.emit()
		return
	
	zip.store_buffer(body)
	zip.close()

	# Opens the zip file
	var zip_reader := ZIPReader.new()
	var zip_result := zip_reader.open(plugin.UPDATE_PATH)

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

	# Creates a gitignore
	create_gitignore()

	print("SceneMap Plugin succesfully updated!")

	# Resets the editor
	await tree.create_timer(2.0).timeout
	EditorInterface.restart_editor(true)

#endregion

#region TokenValidity

## Checks if the token is valid by calling GitHub's API.
## Once the HTTP request is sent, the [_on_validity_checked()] method is fired.
## Emits [validity_checked] after the checking attempt ends.
func check_token_validity(token : String) -> bool:

	# Creates a new request
	var http := HTTPRequest.new()
	var headers := _get_headers(token)
	tree.root.add_child(http)
	http.request_completed.connect(_on_validity_checked)

	# Makes the request
	http.request(SceneMapConstants.GITHUB_API, headers)

	await validity_checked

	return is_token_valid


## Callback when the token is validated after the [check_token_validity()] method.
func _on_validity_checked(result, response_code, response_headers, body) -> void:
	is_token_valid = response_code == 200
	validity_checked.emit()

#endregion

#region TokenParsing

## Checks if the token file exists and parses it. If there is no file or the token is not valid,
##  opens the token input dialog by calling the [ask_for_token()] method.
func parse_token() -> bool:

	# Opens the file
	var file := FileAccess.open(SceneMapConstants.TOKEN_PATH, FileAccess.READ)

	# If there is no file, asks for a token
	if !file or file.get_open_error() != OK:
		ask_for_token()
		return false

	# Parses the file
	var token := file.get_as_text()
	file.close

	# Checks the validity of the token
	var is_token_valid := await check_token_validity(token)

	if is_token_valid:
		plugin.GITHUB_TOKEN = token
		return true

	# If the token is not valid, asks for it
	ask_for_token()
	return false


## Opens the token input dialog.
func ask_for_token() -> void:
	var ask_for_token : bool = SM_ResourceTools.load_config("ask_for_token", true)
	if ask_for_token:
		plugin.panel.token_dialog.toggle_visiblity(true)


## Saves the token in a file that won't be tracked by Git.
func save_token(token : String) -> void:

	# Creates the plugin_data folder if doesn't exists
	var base_dir := SceneMapConstants.USER_DATA_PATH.get_base_dir()
	var dir := DirAccess.open("res://")
	var subdirs := base_dir.replace("res://", "").split("/")

	for sub in subdirs:
		if sub == "":
			continue
		if not dir.dir_exists(sub):
			dir.make_dir(sub)
		dir.change_dir(sub)

	# Creates the file
	var file := FileAccess.open(SceneMapConstants.TOKEN_PATH, FileAccess.WRITE)

	if file.get_open_error() != OK:
		push_error("Failed to save the SceneMap Plugin update token.")
		return

	file.store_string(token)
	file.close()

	# Creates a gitignore file
	create_gitignore()

# endregion

#region HelperMethods

## Creates a gitignore file in the plugin_data folder to avoid tracking sensitive information.
func create_gitignore() -> void:
	var gitignore := FileAccess.open(SceneMapConstants.DATA_GITIGNORE, FileAccess.WRITE)

	if gitignore.get_open_error() != OK:
		push_error("Failed to save the SceneMap Plugin gitignore file.")
		return

	gitignore.store_string("token\n*.zip")
	gitignore.close()


## Internal helper that returns the authorization headers for GitHub API.
func _get_headers(token : String) -> Array:
	return [
		"Accept: application/vnd.github+json",
		"Authorization: Bearer " + token
	]

#endregion