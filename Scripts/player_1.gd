extends PlayerMovementBase

var special_moves = {
	10: [Direction.DOWN, 1],
	11: [Direction.UP, 1],
	19: [Direction.RIGHT, 1],
	20: [Direction.LEFT, 1],
	28: [Direction.RIGHT, 1],
	29: [Direction.LEFT, 1],
	34: [Direction.DOWN, 1],
	38: [Direction.RIGHT, 1],
	39: [Direction.LEFT, 1],
	44: [Direction.UP, 2]
}

func _ready() -> void:
	move_sequence = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2,
					 0, 0, 4, 1, 4, 1, 4, 1, 3, 0,
					 0, 3, 1, 3, 1, 3, 1, 2, 0, 0,
					 2, 1, 2, 1, 0, 2, 1, 2, 0, 0,
					 2, 1, 2, 1, 0]
	
	pause_indices = [1, 3, 5, 7, 9, 12, 14, 16, 18, 21, 23, 25, 27, 30, 32, 35, 37, 40, 42, 44]
	
	super._ready()

func prepare_next_move() -> void:
	if current_move_index in special_moves:
		var move = special_moves[current_move_index]
		set_move(move[0], move[1])
	else:
		match current_move_index:
			12, 13, 14, 15, 16, 17, 18:
				set_move(Direction.UP, move_sequence[current_move_index])
			21, 22, 23, 24, 25, 26:
				set_move(Direction.LEFT, move_sequence[current_move_index])
			27:
				set_move(Direction.DOWN, move_sequence[current_move_index])
			30, 31, 32, 33:
				set_move(Direction.LEFT, move_sequence[current_move_index])
			35, 36, 37:
				set_move(Direction.DOWN, move_sequence[current_move_index])
			40, 41, 42, 43:
				set_move(Direction.LEFT, move_sequence[current_move_index])
			_:
				set_move(Direction.RIGHT, move_sequence[current_move_index])
