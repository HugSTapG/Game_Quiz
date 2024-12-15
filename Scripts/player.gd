extends CharacterBody2D
class_name PlayerMovementBase

enum Direction {
	RIGHT,
	LEFT,
	UP,
	DOWN
}

const TILE_SIZE = Vector2(32, 16)
const JUMP_HEIGHT = 10.0
const MOVE_SPEED = 2.0

@onready var sprite: Sprite2D = $Sprite2D

var move_sequence: Array = []
var pause_indices: Array = []
var current_move_index: int = 0
var is_moving: bool = false
var is_paused: bool = false
var jump_progress: float = 0.0
var start_position: Vector2
var target_position: Vector2
var move_distance: int = 1
var current_direction: Direction = Direction.RIGHT

@export var network_id: int = 1
var sync_target_pos: Vector2

const SPRITE_RECTS = {
	Direction.LEFT: Rect2(50, 53, 11, 17),
	Direction.RIGHT: Rect2(114, 53, 11, 17),
	Direction.UP: Rect2(18, 53, 11, 17),
	Direction.DOWN: Rect2(82, 53, 11, 17)
}

const DIRECTION_VECTORS = {
	Direction.RIGHT: Vector2(1, 0),
	Direction.LEFT: Vector2(-1, 0),
	Direction.UP: Vector2(0, -1),
	Direction.DOWN: Vector2(0, 1)
}

func _ready() -> void:
	target_position = position
	sync_target_pos = position
	network_id = 1 if name == "Player1" else 2
	set_multiplayer_authority(network_id)

func _process(delta: float) -> void:
	update_movement(delta)

func update_movement(delta: float) -> void:
	if is_moving:
		interpolate_movement(delta)
		return
	
	if is_paused:
		var player_username = "Green" if name == "Player1" else "Purple"
		if GameManager.current_username == player_username and current_move_index in pause_indices:
			if GameManager.quiz_ui and not GameManager.quiz_ui.visible:
				GameManager.quiz_ui.update_quiz_visibility(true)
		return
	
	if current_move_index < move_sequence.size():
		if current_move_index in pause_indices:
			is_paused = true
			var player_username = "Green" if name == "Player1" else "Purple"
			if GameManager.current_username == player_username and GameManager.quiz_ui:
				GameManager.quiz_ui.update_quiz_visibility(true)
		else:
			prepare_next_move()

func prepare_next_move() -> void:
	push_error("prepare_next_move() must be implemented by child classes")

func set_move(direction: Direction, distance: int) -> void:
	current_direction = direction
	move_distance = distance
	update_sprite_direction(direction)
	move_to(DIRECTION_VECTORS[direction])

@rpc("any_peer", "call_local")
func sync_movement_state(start_pos: Vector2, end_pos: Vector2, move_idx: int, moving_state: bool, pause_state: bool):
	if not is_moving:
		position = start_pos
		target_position = end_pos
		sync_target_pos = end_pos
		current_move_index = move_idx
		is_moving = moving_state
		is_paused = pause_state
		
		if is_moving:
			start_position = start_pos
			jump_progress = 0.0

func move_to(direction: Vector2) -> void:
	start_position = position
	target_position = position + Vector2(
		(-direction.x * TILE_SIZE.x / 2 - direction.y * TILE_SIZE.x / 2) * move_distance,
		(-direction.x * TILE_SIZE.y / 2 + direction.y * TILE_SIZE.y / 2) * move_distance
	)
	sync_target_pos = target_position
	is_moving = true
	jump_progress = 0.0
	
	rpc("sync_movement_state", start_position, target_position, current_move_index, true, is_paused)

func interpolate_movement(delta: float) -> void:
	jump_progress += delta * MOVE_SPEED
	
	if jump_progress >= 1.0:
		finalize_move()
		return
	
	var horizontal_position = start_position.lerp(target_position, jump_progress)
	var arc_height = sin(jump_progress * PI) * JUMP_HEIGHT
	position = Vector2(horizontal_position.x, horizontal_position.y - arc_height)

func finalize_move() -> void:
	jump_progress = 1.0
	is_moving = false
	position = target_position
	
	current_move_index += 1
	
	rpc("sync_movement_state", target_position, target_position, current_move_index, false, is_paused)
	
	if current_move_index in pause_indices:
		is_paused = true
		var player_username = "Green" if name == "Player1" else "Purple"
		if GameManager.current_username == player_username and GameManager.quiz_ui:
			GameManager.quiz_ui.update_quiz_visibility(true)
	else:
		prepare_next_move()

func update_sprite_direction(direction: Direction) -> void:
	sprite.region_rect = SPRITE_RECTS[direction]

func external_resume() -> void:
	is_paused = false
	
	rpc("sync_movement_state", position, sync_target_pos, current_move_index, is_moving, false)
	
	if current_move_index < move_sequence.size() and not is_moving:
		prepare_next_move()

func external_pause() -> void:
	is_paused = true
	
	rpc("sync_movement_state", position, sync_target_pos, current_move_index, is_moving, true)
