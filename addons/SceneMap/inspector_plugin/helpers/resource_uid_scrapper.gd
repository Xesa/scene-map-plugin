class_name SceneMapResourceUIDScrapper extends SceneMapHelper


static func get_uid_from_tscn(scene_path : String) -> String:
	var file = FileAccess.open(scene_path, FileAccess.READ)

	if not file:
		return ""

	var regex = RegEx.new()
	regex.compile('^\\[gd_scene.*uid="uid://([^"]+)"')

	while not file.eof_reached():
		var line = file.get_line()
		var result = regex.search(line)

		if result:
			return result.get_string(1)

	return ""