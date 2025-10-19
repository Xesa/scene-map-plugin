class_name SceneMapConstants extends Object

const SM_Enums := preload(ENUMS)

# General
static var VERSION : String

const PLUGIN_NAME := "SceneMap"
const PLUGIN_PATH := "res://addons/scene_map_plugin/"
const CONFIG_PATH := PLUGIN_PATH + "plugin.cfg"

# Folders
const ASSETS_PATH := PLUGIN_PATH + "assets/"
const COMPONENTS_PATH := PLUGIN_PATH + "components/"
const SCRIPTS_PATH := PLUGIN_PATH + "scripts/"
const TSCN_PATH := PLUGIN_PATH + "tscn/"
const USER_DATA_PATH := "res://.plugin_data/scene_map_plugin/"

# Script folders
const COMMON_PATH := SCRIPTS_PATH + "common/"
const GUI_PATH := SCRIPTS_PATH + "gui/"
const HELPERS_PATH := SCRIPTS_PATH + "helpers/"
const MAIN_PATH := SCRIPTS_PATH + "main/"
const RESOURCES_PATH := SCRIPTS_PATH + "resources/"

# Common scripts
const COMPONENT_FINDER := COMMON_PATH + "component_finder.gd"
const CONSTANTS := COMMON_PATH + "constants.gd"
const ENUMS := COMMON_PATH + "enums.gd"
const EVENT_BUS := COMMON_PATH + "event_bus.gd"
const RESOURCE_TOOLS := COMMON_PATH + "resource_tools.gd"
const SCENE_SAVER := COMMON_PATH + "scene_saver.gd"

# GUI scripts
const ABOUT_DIALOG := GUI_PATH + "dialogs/scene_map_about_dialog.gd"
const ADD_DIALOG := GUI_PATH + "dialogs/scene_map_add_dialog.gd"

const GRAPH_ABOUT_BUTTON := GUI_PATH + "graph/graph_about_button.gd"
const GRAPH_ADD_BUTTON := GUI_PATH + "graph/graph_add_button.gd"
const GRAPH_CONFIG_BUTTON := GUI_PATH + "graph/graph_config_button.gd"
const GRAPH_REFRESH_BUTTON := GUI_PATH + "graph/graph_refresh_button.gd"

const GRAPH_NODE_MENU := GUI_PATH + "graph_node/graph_node_menu.gd"

const SLOT_DISCONNECT_BUTTON := GUI_PATH + "graph_slot/slot_button_disconnect.gd"
const SLOT_NAME_BUTTON := GUI_PATH + "graph_slot/slot_button_name.gd"
const SLOT_SIDE_BUTTON := GUI_PATH + "graph_slot/slot_button_side.gd"
const SLOT_TYPE_BUTTON := GUI_PATH + "graph_slot/slot_button_type.gd"
const SLOT_CONTROL := GUI_PATH + "graph_slot/slot_control.gd"
const SLOT_LABEL := GUI_PATH + "graph_slot/slot_label.gd"
const SLOT_LABEL_EDIT := GUI_PATH + "graph_slot/slot_label_edit.gd"

# Helper scripts
const GRAPH_CONNECTION_VALIDATOR := HELPERS_PATH + "graph_connection_validator.gd"
const NODE_PREVIEWER := HELPERS_PATH + "node_previewer.gd"
const NODE_REFRESHER := HELPERS_PATH + "node_refresher.gd"
const NODE_REGISTRATOR := HELPERS_PATH + "node_registrator.gd"
const SLOT_CONNECTOR := HELPERS_PATH + "slot_connector.gd"
const SLOT_REGISTRATOR := HELPERS_PATH + "slot_registrator.gd"

# Main sripts
const SCENE_MAP := MAIN_PATH + "scene_map.gd"
const SCENE_MAP_GRAPH := MAIN_PATH + "scene_map_graph.gd"
const SCENE_MAP_IO := MAIN_PATH + "scene_map_io.gd"
const SCENE_MAP_NODE := MAIN_PATH + "scene_map_node.gd"
const SCENE_MAP_SLOT := MAIN_PATH + "scene_map_slot.gd"

# Resource scripts
const GRAPH_RESOURCE := RESOURCES_PATH + "scene_map_graph_resource.gd"
const NODE_RESOURCE := RESOURCES_PATH + "scene_map_node_resource.gd"
const SLOT_RESOURCE := RESOURCES_PATH + "scene_map_slot_resource.gd"

# Interface
const PANEL_TSCN := TSCN_PATH + "scene_map_panel.tscn"
const ABOUT_DIALOG_TSCN := TSCN_PATH + "scene_map_about_dialog.tscn"

# Assets
const MAP_ICON := ASSETS_PATH + "map-icon.svg"
const ABOUT_ICON := ASSETS_PATH + "about-icon.svg"
const ADD_ICON := ASSETS_PATH + "add-icon.svg"
const REFRESH_ICON := ASSETS_PATH + "refresh-icon.svg"
const CONFIG_ICON := ASSETS_PATH + "config-icon.svg"
const MARKER_ICON := ASSETS_PATH + "marker-icon.svg"

const ARROW_LEFT := ASSETS_PATH + "arrow-left.svg"
const ARROW_RIGHT := ASSETS_PATH + "arrow-right.svg"
const ARROW_DOUBLE := ASSETS_PATH + "arrow-double.svg"

const DISCONNECT_ICON := ASSETS_PATH + "disconnect-icon.svg"
const SIDES_ICON := ASSETS_PATH + "sides-icon.svg"
const TYPE_ICON := ASSETS_PATH + "type-icon.svg"
const EDIT_ICON := ASSETS_PATH + "edit-icon.svg"

# Other
const VIEWPORT_SIZE := Vector2i(320,260)

const GITHUB_LINK := "https://github.com/Xesa/scene-map-plugin"

const SLOT_CONFIG := {
		SM_Enums.Type.ENTRY:	{"label": "Entrance",	"icons": [ARROW_RIGHT, ARROW_LEFT]},
		SM_Enums.Type.EXIT:	{"label": "Exit",		"icons": [ARROW_LEFT, ARROW_RIGHT]},
		SM_Enums.Type.TWO_WAY:	{"label": "Two-way",	"icons": [ARROW_DOUBLE, ARROW_DOUBLE]},
		SM_Enums.Type.FUNNEL:	{"label": "Funnel",		"icons": [ARROW_RIGHT, ARROW_LEFT]},
	}