# capture.gd: plays a scripted game and saves screenshots for the README.
#   godot --path . res://tools/capture.tscn -- <output dir>
extends Node

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	var placement: TowerPlacement = main.get_node("TowerPlacement")
	var waves: WaveManager = main.get_node("WaveManager")
	GameState.earn(400)
	for p in [[0, Vector2i(10, 2)], [0, Vector2i(8, 4)], [1, Vector2i(13, 6)], [2, Vector2i(13, 9)], [0, Vector2i(4, 6)], [1, Vector2i(20, 6)]]:
		placement.place(p[0], p[1])
	await _shot(out + "/01-build.png")
	waves.current = 4
	waves.start_next_wave()
	for i in 60 * 9:
		await get_tree().physics_frame
	placement.select(2)
	placement._update_ghost(placement.level.cell_center(Vector2i(16, 8)))
	await _shot(out + "/02-wave.png")
	placement.select(2)
	for i in 60 * 30:
		if GameState.is_over:
			break
		await get_tree().physics_frame
	await _shot(out + "/03-late.png")
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
	image.save_png(path)
	print("saved ", path)
