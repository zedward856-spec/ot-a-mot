extends Area2D

@export var speed: float = 40.0
@export var max_health: int = 30  
var current_health: int
var knockback: Vector2 = Vector2.ZERO
var player_node: CharacterBody2D = null
var flash_tween: Tween 
# The cooldown timer so they don't instant-kill you
var attack_cooldown: float = 0.0 
var knockback_tween: Tween

func _ready() -> void:
	# 1. SAFETY CHECK: Make sure they always spawn looking normal!
	if has_node("damaged"):
		get_node("damaged").hide()
	if has_node("Sprite2D"):
		get_node("Sprite2D").show()
		
	current_health = max_health
	
	if has_node("ProgressBar"):
		var bar = get_node("ProgressBar") as ProgressBar
		bar.max_value = max_health
		bar.value = current_health

	if get_parent().has_node("player"):
		player_node = get_parent().get_node("player") as CharacterBody2D
func start_flashing() -> void:
	# --- THE FIX: KILL THE OLD ANIMATION ---
	# If the enemy gets hit while ALREADY flashing, stop the old animation immediately!
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
		
	if has_node("Sprite2D") and has_node("damaged"):
		var normal_sprite = get_node("Sprite2D")
		var damaged_sprite = get_node("damaged")
		
		# Force the starting state so it never gets confused
		normal_sprite.hide()
		damaged_sprite.show()
		
		# Create the new animation and save it to our variable
		flash_tween = create_tween()
		
		for i in range(3): # Enemies usually flash fewer times than the player
			flash_tween.tween_interval(0.1)
			flash_tween.tween_callback(func():
				damaged_sprite.hide()
				normal_sprite.show()
			)
			
			flash_tween.tween_interval(0.1)
			flash_tween.tween_callback(func():
				normal_sprite.hide()
				damaged_sprite.show()
			)
			
		# --- THE SAFETY CATCH ---
		# Guarantee that the absolute last thing it does is return to normal!
		flash_tween.tween_interval(0.1)
		flash_tween.tween_callback(func():
			damaged_sprite.hide()
			normal_sprite.show()
		)
func _process(delta: float) -> void:
	# --- THE CINEMATIC STUN LOCK ---
	if knockback.length() > 10.0:
		global_position += knockback * delta
		
		# Hit the brakes MUCH slower, giving you a smooth, dramatic slide.
		knockback = knockback.lerp(Vector2.ZERO, 3.0 * delta)
		
		if attack_cooldown > 0.0:
			attack_cooldown -= delta
			
	else:
		# ONLY run the movement/attack logic if we aren't sliding!
		if attack_cooldown > 0.0:
			attack_cooldown -= delta
			
		if not player_node:
			if get_parent().has_node("player"):
				player_node = get_parent().get_node("player") as CharacterBody2D
				
		if player_node:
			var distance = global_position.distance_to(player_node.global_position)
			
			if distance < 18.0:
				if attack_cooldown <= 0.0:
					if player_node.has_method("take_damage"):
						player_node.take_damage(1) 
					attack_cooldown = 1.0 
				return 
				
			if distance > 3.0:
				var target_dir = global_position.direction_to(player_node.global_position)
				var push_vector = Vector2.ZERO
				var all_enemies = get_tree().get_nodes_in_group("enemies")
				
				for other_enemy in all_enemies:
					if other_enemy != self:
						var enemy_dist = global_position.distance_to(other_enemy.global_position)
						if enemy_dist < 12.0:
							push_vector += other_enemy.global_position.direction_to(global_position)
				
				var final_direction = (target_dir + push_vector).normalized()
				global_position += final_direction * speed * delta
func take_damage(amount: int) -> void:
	current_health -= amount
	
	# --- THE HEALTH BAR FIX ---
	# Updates the visual bar every time they take a hit!
	if has_node("ProgressBar"):
		var bar = get_node("ProgressBar") as ProgressBar
		bar.value = current_health
	
	# --- THE SPRITE SWAP FLASH ---
	# (No red tinting! Just pure image swapping)
	if has_node("Sprite2D") and has_node("damaged"):
		var normal_sprite = get_node("Sprite2D")
		var damaged_sprite = get_node("damaged")
		
		normal_sprite.hide()
		damaged_sprite.show()
		
		var tween = create_tween()
		tween.tween_interval(0.15) 
		tween.tween_callback(func():
			damaged_sprite.hide()
			normal_sprite.show()
		)
	
	if current_health <= 0:
		queue_free()
# --- THE KNOCKBACK RECEIVER ---
func apply_knockback(push_dir: Vector2, force: float) -> void:
	if knockback_tween and knockback_tween.is_valid():
		knockback_tween.kill()
		
	knockback_tween = create_tween()
	
	# Make sure this line ALSO says "push_dir"
	var target_pos = global_position + (push_dir * (force * 0.1))
	
	knockback_tween.tween_property(self, "global_position", target_pos, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
