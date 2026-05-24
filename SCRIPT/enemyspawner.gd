extends Node

@export var spawn_cooldown: float = 0.3 # Spawns a new enemy every x seconds!
var spawn_timer: float = 0.0
func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_cooldown:
		spawn_timer = 0.0
		spawn_random_enemy()
func spawn_random_enemy() -> void:
	if get_parent().has_node("enemy"):
		var template = get_parent().get_node("enemy")
		var new_enemy = template.duplicate() as Area2D
		
		# --- RANDOM BORDER COORDINATES MATH ---
		var edge = randi() % 4
		var spawn_pos = Vector2.ZERO
		
		match edge:
			0: # Top Edge
				spawn_pos = Vector2(randf_range(10, 310), 10)
			1: # Bottom Edge
				spawn_pos = Vector2(randf_range(10, 310), 170)
			2: # Left Edge
				spawn_pos = Vector2(10, randf_range(10, 170))
			3: # Right Edge
				spawn_pos = Vector2(310, randf_range(10, 170))
		
		new_enemy.global_position = spawn_pos
		new_enemy.show()
		new_enemy.process_mode = Node.PROCESS_MODE_INHERIT
		
		# 1. THE FIX: Add the unique name change so Godot knows it's a clone
		new_enemy.name = "enemy_clone"
		
		# 2. Add ONLY this new clone to the target group!
		new_enemy.add_to_group("enemies")
		
		get_parent().add_child(new_enemy)
