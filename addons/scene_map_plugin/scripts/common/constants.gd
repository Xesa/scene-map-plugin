extends Node

static var VERSION : String

const PLUGIN_NAME := "SceneMap"
const PLUGIN_PATH := "res://addons/scene_map_plugin/"

const CONFIG_PATH := PLUGIN_PATH + "plugin.cfg"
const SCRIPTS_PATH := PLUGIN_PATH + "scripts/"
const ASSETS_PATH := PLUGIN_PATH + "assets/"
const USER_DATA_PATH := PLUGIN_PATH + "user_data/"

const PANEL_PATH := SCRIPTS_PATH + "gui/dialogs/scene_map_panel.tscn"

const MAP_ICON := ASSETS_PATH + "map-icon.svg"
const ADD_ICON := ASSETS_PATH + "add-icon.svg"
const ARROW_LEFT := ASSETS_PATH + "arrow-left.svg"
const ARROW_RIGHT := ASSETS_PATH + "arrow-right.svg"
const ARROW_DOUBLE := ASSETS_PATH + "arrow-double.svg"

const VIEWPORT_SIZE := Vector2i(256,256)

const GITHUB_LINK := "http://www.google.com/"

const SLOT_CONFIG := {
		SceneMapComponent.Type.ENTRY:	{"label": "Entrance",	"icons": [ARROW_RIGHT, ARROW_LEFT]},
		SceneMapComponent.Type.EXIT:	{"label": "Exit",		"icons": [ARROW_LEFT, ARROW_RIGHT]},
		SceneMapComponent.Type.TWO_WAY:	{"label": "Two-way",	"icons": [ARROW_DOUBLE, ARROW_DOUBLE]},
		SceneMapComponent.Type.FUNNEL:	{"label": "Funnel",		"icons": [ARROW_RIGHT, ARROW_LEFT]},
	}