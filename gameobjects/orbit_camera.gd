extends Node3D

@export var watching : Node3D : 
	set(x):
		watching = x
		trackball_camera.zoom_minimum = watching.scale_radius + 1
		trackball_camera.zoom_maximum = watching.scale_radius + 100

@onready var trackball_camera: Camera3D = $TrackballCamera

@export var detail_view := false

func _ready() -> void:
	WorldController.camera = self

func _physics_process(_delta: float) -> void:
	position = watching.position if watching else Vector3.ZERO
	
	if detail_view:
		trackball_camera.fov = lerp(trackball_camera.fov, 16.0, 0.5)
	else:
		trackball_camera.fov = lerp(trackball_camera.fov, 75.0, 0.5)

func _on_toggle_detail_view_pressed() -> void:
	detail_view = not detail_view
	WorldController.detail_view = detail_view
