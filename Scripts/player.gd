extends CharacterBody2D

const TILE_SIZE = Vector2(32, 16) # Size of one isometric tile
const JUMP_HEIGHT = 10.0 # Maximum height of the jump arc
var target_position: Vector2 # Target position to move toward
var is_moving: bool = false # To control if the player is already moving
var jump_progress: float = 0.0 # Progress along the jump arc (0 to 1)
var start_position: Vector2 # Starting position for the jump

# Placeholder sprite region rects
const SPRITE_RECT_LEFT = Rect2(114, 53, 11, 17)
const SPRITE_RECT_RIGHT = Rect2(50, 53, 11, 17)
const SPRITE_RECT_UP = Rect2(18, 53, 11, 17)
const SPRITE_RECT_DOWN = Rect2(82, 53, 11, 17)

func _ready() -> void:
	# Initialize the target position to the player's current position
	target_position = position

func _process(delta: float) -> void:
	# Listen for input only if the character is not moving
	if not is_moving:
		if Input.is_action_just_pressed("ui_up"):
			update_sprite_direction("up")
			move_to(Vector2(0, -1))
		elif Input.is_action_just_pressed("ui_down"):
			update_sprite_direction("down")
			move_to(Vector2(0, 1))
		elif Input.is_action_just_pressed("ui_left"):
			update_sprite_direction("left")
			move_to(Vector2(-1, 0))
		elif Input.is_action_just_pressed("ui_right"):
			update_sprite_direction("right")
			move_to(Vector2(1, 0))
	
	# Move toward the target position if moving
	if is_moving:
		jump_progress += delta * 2 # Adjust speed as needed
		if jump_progress >= 1.0:
			jump_progress = 1.0
			is_moving = false
		
		# Interpolate the position
		var horizontal_position = start_position.lerp(target_position, jump_progress)
		var arc_height = sin(jump_progress * PI) * JUMP_HEIGHT # Parabolic arc
		position = Vector2(horizontal_position.x, horizontal_position.y - arc_height)

func move_to(direction: Vector2) -> void:
	# Calculate the target position based on the direction and tile size
	target_position = position + Vector2(
		direction.x * TILE_SIZE.x / 2 - direction.y * TILE_SIZE.x / 2,
		direction.x * TILE_SIZE.y / 2 + direction.y * TILE_SIZE.y / 2
	)
	is_moving = true
	jump_progress = 0.0
	start_position = position

func update_sprite_direction(direction: String) -> void:
	var sprite_node = $Sprite2D # Replace with your actual sprite node path
	match direction:
		"left":
			sprite_node.region_rect = SPRITE_RECT_LEFT
		"right":
			sprite_node.region_rect = SPRITE_RECT_RIGHT
		"up":
			sprite_node.region_rect = SPRITE_RECT_UP
		"down":
			sprite_node.region_rect = SPRITE_RECT_DOWN
