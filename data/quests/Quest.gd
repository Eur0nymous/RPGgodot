extends Resource
class_name Quest

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var target_flag: String = ""      # что должно случиться (убийство, флаг)
@export var reward_item: Item
@export var reward_amount: int = 1

func is_complete_check(flag_name: String) -> bool:
	return target_flag != "" and target_flag == flag_name
