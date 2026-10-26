# level.gd: the map as data, and the TileMapLayer built from it.
#   .  grass, buildable      #  path      S  spawn (on the path)
#   D  depot (path end)      x  rock, not buildable
# Path tiles carry a navigation polygon, so the TileMapLayer itself becomes the
# navigation mesh that every enemy's NavigationAgent2D follows.
class_name Level
extends Node2D

const MAP := [
	"..............................",
	"S#########..............x.....",
	".........#....................",
	".....x...#....########.......x",
	".........#....#......#........",
	"...#######....#......#........",
	"...#..........#......#........",
	"x..#.......x..#..x...#....##D.",
	"...#..x.......#......#....#...",
	"...#..........#......#...x#...",
	"...############......#....#...",
	".....................#....#...",
	".....................######...",
	".x..........x.....x.........x.",
	"..............................",
]
const TILE := Art.TILE
const GRASS := Vector2i(0, 0)
const PATH := Vector2i(1, 0)
const ROCK := Vector2i(2, 0)

var spawn_cell := Vector2i.ZERO
var depot_cell := Vector2i.ZERO
var occupied := {}
var ground: TileMapLayer


func _ready() -> void:
	ground = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = _make_tile_set()
	add_child(ground)
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			match ch:
				"S":
					spawn_cell = cell
				"D":
					depot_cell = cell
			ground.set_cell(cell, 0, PATH if ch in "#SD" else ROCK if ch == "x" else GRASS)
	var depot := Sprite2D.new()
	depot.name = "Depot"
	depot.texture = Art.texture("depot")
	depot.position = cell_center(depot_cell)
	add_child(depot)


func _make_tile_set() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	tiles.add_navigation_layer()
	var source := TileSetAtlasSource.new()
	source.texture = Art.tile_atlas()
	source.texture_region_size = Vector2i(TILE, TILE)
	tiles.add_source(source, 0)
	for coords in [GRASS, PATH, ROCK]:
		source.create_tile(coords)
	# A full-tile square on path tiles only. Neighbouring squares share edges,
	# so the navigation map joins them into one walkable corridor.
	var h := TILE / 2.0
	var nav := NavigationPolygon.new()
	nav.vertices = PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	source.get_tile_data(PATH, 0).set_navigation_polygon(0, nav)
	return tiles


func cell_center(cell: Vector2i) -> Vector2:
	return position + Vector2(cell * TILE) + Vector2(TILE, TILE) / 2.0


func world_to_cell(world: Vector2) -> Vector2i:
	return Vector2i(((world - position) / TILE).floor())


func in_bounds(cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < MAP.size() and cell.x >= 0 and cell.x < MAP[0].length()


func is_buildable(cell: Vector2i) -> bool:
	return in_bounds(cell) and MAP[cell.y][cell.x] == "." and not occupied.has(cell)
