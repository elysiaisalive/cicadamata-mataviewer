class_name Freecam extends Node


var camera_ref: WeakRef;
var freecam_fov: float;
var freecam_enabled: bool;
var freecam_speed: float;
var reset_fov: float;
var reset_xform: Transform3D;
var mouse_motion: Vector2;
var scroll_up: int;
var scroll_down: int;
var frame_last: float;
var mouse_move_last: float;
var scroll_last_up: float;
var scroll_last_down: float;

#region Virtual
func _ready()->void:
	freecam_speed = GDPatch.get_config_option('mataviewer', 'camera', 'speed') as float;
	freecam_fov = GDPatch.get_config_option('mataviewer', 'camera', 'fov') as float;
	freecam_enabled = false;


func _process(delta:float)->void:
	if Input.is_action_just_pressed("lookdown"):
		set_freecam(!freecam_enabled);
		return;

	if !freecam_enabled:
		return;

	if (mouse_move_last < frame_last):
		mouse_motion = Vector2.ZERO;

	if (scroll_last_up < frame_last):
		scroll_up = 0;

	if (scroll_last_down < frame_last):
		scroll_down = 0;

	frame_last += delta;


func _physics_process(delta:float)->void:
	update_freecam(delta);


func _input(event:InputEvent)->void:
	if !freecam_enabled:
		return

	if event is InputEventMouseMotion:
		mouse_move_last = frame_last;
		mouse_motion = event.relative;

	elif (event is InputEventMouseButton):
		if (event.button_index == 4):
			scroll_last_up = frame_last;
			scroll_up = 1;
		elif (event.button_index == 5):
			scroll_last_down = frame_last;
			scroll_down = 1;
	get_tree().set_input_as_handled();
#endregion
#region
func get_autoload(autoload:String)->Node:
	return Engine.get_main_loop().root.get_node(autoload);


func get_player_camera()->Camera3D:
	if camera_ref.get_ref() != null:
		return camera_ref.get_ref();

	return null;


func set_freecam(enabled:bool = false)->void:
	if get_autoload('global'):
		var _glob: Node = get_autoload('global');

		if _glob._player != null && _glob._player.camera != null:
			if !enabled:
				_glob._player.camera.global_transform = reset_xform;
				_glob._player.camera.fov = reset_fov;

			freecam_enabled = enabled;
			camera_ref = weakref(_glob._player.camera);
			reset_fov = get_autoload('Config').FOV;
			reset_xform = _glob._player.camera.global_transform;
			_glob._player.camera.fov = freecam_fov;
			_glob._player.set_process_unhandled_input(!enabled);
			_glob._player.set_process_input(!enabled);
			_glob._player.set_process(!enabled);
			_glob._player.active = !enabled;
			_glob._player._gun.visible = !enabled;
			UI.visible = !enabled;
			return;
		freecam_enabled = false;


func update_freecam(delta:float)->void:
	if !freecam_enabled:
		return;

	var _mouse_motion: Vector2 = -mouse_motion;
	#_mouse_motion *= 0.001;
	_mouse_motion *= Config.SENSITIVITY;
	
	if get_player_camera() != null:
		get_player_camera().rotation.x += _mouse_motion.y;
		get_player_camera().rotation.y += _mouse_motion.x;
		get_player_camera().rotation.x = clampf(get_player_camera().rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0));

		var _y_input: float = Input.get_axis("stomp", "jump");
		var _y_dir: Vector3 = get_player_camera().global_basis * Vector3(0.0, _y_input, 0.0);
		var _input_dir: Vector3 = get_input_dir(get_player_camera().global_basis);
		var _move_dir: Vector3 = _input_dir + _y_dir;

		get_player_camera().global_position += _move_dir * freecam_speed * delta;
		freecam_speed = max(1.0, freecam_speed + scroll_up);
		freecam_speed = max(1.0, freecam_speed - scroll_down);


func get_input_dir(from_basis:Basis)->Vector3:
	var _dir: Vector2 = Input.get_vector("left", "right", "forward", "back").normalized();
	return from_basis * Vector3(_dir.x, 0, _dir.y);
#endregion