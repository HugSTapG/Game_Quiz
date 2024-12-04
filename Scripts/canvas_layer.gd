extends Control

func _ready() -> void:
	# Get the Panel node
	var panel_node = get_node("Panel")
	
	# Check if the Panel node exists
	if panel_node:
		# Loop through all the child nodes and print their names
		for child in panel_node.get_children():
			print(child.name)
	else:
		print("Panel node not found.")
