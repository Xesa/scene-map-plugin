@tool
extends Control

const SceneMapGraph := preload(SceneMapConstants.SCENE_MAP_GRAPH)

const SM_AboutButton := preload(SceneMapConstants.GRAPH_ABOUT_BUTTON)
const SM_ConfigButton := preload(SceneMapConstants.GRAPH_CONFIG_BUTTON)
const SM_UpdateButton := preload(SceneMapConstants.GRAPH_UPDATE_BUTTON)

const SM_AddButton := preload(SceneMapConstants.GRAPH_ADD_BUTTON)
const SM_RefreshButton := preload(SceneMapConstants.GRAPH_REFRESH_BUTTON)

const SM_AboutDialog := preload(SceneMapConstants.ABOUT_DIALOG)
const SM_UpdateDialog := preload(SceneMapConstants.UPDATE_DIALOG)
const SM_TokenDialog := preload(SceneMapConstants.TOKEN_DIALOG)

@onready var graph : SceneMapGraph = $SceneMapGraph

@onready var about_button : SM_AboutButton = $TopContainer/AboutButton
@onready var config_button : SM_ConfigButton = $TopContainer/ConfigButton
@onready var update_button : SM_UpdateButton = $TopContainer/UpdateButton

@onready var add_button : SM_AddButton = $BottomContainer/AddButton
@onready var refresh_button : SM_RefreshButton = $BottomContainer/RefreshButton

@onready var about_dialog : SM_AboutDialog = $SceneMapAboutDialog
@onready var update_dialog : SM_UpdateDialog = $SceneMapUpdateDialog
@onready var token_dialog : SM_TokenDialog = $SceneMapTokenDialog

