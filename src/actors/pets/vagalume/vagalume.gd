class_name Vagalume
extends Pet
## GDD: Faíscas every 1.2 s; RB combat = Clarão (stun 3 tiles for 1.5 s,
## 8 s cooldown); RB exploration = Luz (opens darkness gates).

@export_group("Vagalume")
@export var spark_damage := 1
@export var spark_speed := 170.0
## 3 tiles.
@export var flash_radius := 48.0
@export var flash_stun_time := 1.5


func _auto_attack(target: Node2D) -> void:
	var spark := Spark.new()
	spark.target = target
	spark.speed = spark_speed
	spark.damage = spark_damage
	spark.source = self
	spark.color = color
	spark.global_position = global_position + visual.position
	get_parent().add_child(spark)
	Fx.sfx(&"spark")


func _combat_ability() -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.global_position.distance_to(global_position) <= flash_radius:
			enemy.stun(flash_stun_time)
	Fx.ring(global_position + visual.position, flash_radius, Color(1.0, 0.95, 0.6))
	Fx.sfx(&"flash")
	Fx.shake(0.2)
