# wave_data.gd: one wave as a resource (data/waves/*.tres). Each entry is
#   {"enemy": "res://scenes/enemies/mouse.tscn", "count": 8, "interval": 0.9, "hp_scale": 1.0}
# Entries spawn one after another. Adding or rebalancing a wave is a data edit.
class_name WaveData
extends Resource

@export var entries: Array[Dictionary] = []
@export var clear_bonus := 20


func enemy_count() -> int:
	var total := 0
	for entry in entries:
		total += int(entry["count"])
	return total
