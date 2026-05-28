extends EnemyBase

@export var damage_att_1: float
@export var damage_att_2: float

@onready var special_attack_2   = $Special_attack_2

var phase: float = 1

func take_damage(amount: float, damage_type: String = "physical") -> void:
	super(amount, damage_type)
	
	if health <= max_health * 0.5 and phase == 1:
		phase2()
		
func phase2():
	phase = 2
	
	speed *= 1.5
	shoot_cooldown *= 0.7 
