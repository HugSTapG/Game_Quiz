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
const PAUSE_DURATION = 1.0

@onready var sprite: Sprite2D = $Sprite2D
var pause_timer: Timer

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
	
	pause_timer = Timer.new()
	pause_timer.one_shot = true
	pause_timer.wait_time = PAUSE_DURATION
	pause_timer.connect("timeout", Callable(self, "_on_pause_timer_timeout"))
	add_child(pause_timer)

func _process(delta: float) -> void:
	update_movement(delta)

func update_movement(delta: float) -> void:
	if is_paused:
		return
	
	if not is_moving and current_move_index < move_sequence.size():
		if current_move_index in pause_indices:
			is_paused = true
			pause_timer.start()
			return
		
		prepare_next_move()
	
	if is_moving:
		interpolate_movement(delta)

func _on_pause_timer_timeout() -> void:
	is_paused = false
	prepare_next_move()

func prepare_next_move() -> void:
	push_error("prepare_next_move() must be implemented by child classes")

func set_move(direction: Direction, distance: int) -> void:
	current_direction = direction
	move_distance = distance
	update_sprite_direction(direction)
	move_to(DIRECTION_VECTORS[direction])

func move_to(direction: Vector2) -> void:
	target_position = position + Vector2(
		(-direction.x * TILE_SIZE.x / 2 - direction.y * TILE_SIZE.x / 2) * move_distance,
		(-direction.x * TILE_SIZE.y / 2 + direction.y * TILE_SIZE.y / 2) * move_distance
	)
	is_moving = true
	jump_progress = 0.0
	start_position = position

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
	current_move_index += 1
	position = target_position

func update_sprite_direction(direction: Direction) -> void:
	sprite.region_rect = SPRITE_RECTS[direction]
