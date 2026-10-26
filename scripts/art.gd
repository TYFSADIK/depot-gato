# art.gd: every sprite in the game, as pixel art written in code.
# Each sprite is a list of rows; each character is one pixel from PALETTE
# ("." is transparent). Textures are built once and cached. Sheets with
# two frames side by side are used with Sprite2D.hframes = 2.
class_name Art
extends RefCounted

const TILE := 16

const PALETTE := {
	"k": Color("1a1c2c"),
	"w": Color("f4f4f4"),
	"o": Color("ef7d57"),
	"O": Color("b13e53"),
	"g": Color("94b0c2"),
	"G": Color("566c86"),
	"y": Color("ffcd75"),
	"Y": Color("e0a040"),
	"p": Color("f4a6b5"),
	"P": Color("c86b85"),
	"b": Color("8a5a3c"),
	"B": Color("5a3a28"),
	"r": Color("c0392b"),
	"e": Color("38b764"),
	"n": Color("000000"),
	"s": Color("f5deb3"),
	"c": Color("4a3428"),
	"l": Color("41a6f6"),
	"L": Color("3b5dc9"),
}

const SPRITES := {
	"tabby": [
		"................",
		"..k..........k..",
		".kOk........kOk.",
		".koOk......kOok.",
		".koookkkkkkoook.",
		".koooooOOoooook.",
		".kooooooooooook.",
		".kooenooooneook.",
		".koooowppwooook.",
		"..koowwwwwwook..",
		"..kooooooooook..",
		".koOooooooooOok.",
		".kooooooooooook.",
		".koOoowwwwooOok.",
		".kwwkowwwwokwwk.",
		"..kkkkkkkkkkkk..",
	],
	"siamese": [
		"................",
		"..k..........k..",
		".kck........kck.",
		".ksck......kcsk.",
		".kssskkkkkksssk.",
		".ksssssccsssssk.",
		".kssssssssssssk.",
		".ksslnssssnlssk.",
		".ksssswppwssssk.",
		"..ksswwwwwwssk..",
		"..kssssssssssk..",
		".kscsssssssscsk.",
		".kssssssssssssk.",
		".kscsswwwwsscsk.",
		".kwwkswwwwskwwk.",
		"..kkkkkkkkkkkk..",
	],
	"yarn_cat": [
		"................",
		"..k..........k..",
		".kGk........kGk.",
		".kgGk......kGgk.",
		".kgggkkkkkkgggk.",
		".kgggggGGgggggk.",
		".kggggggggggggk.",
		".kggynggggnyggk.",
		".kggggwppwggggk.",
		"..kggwwwwwwggk..",
		"..kggggggggggk..",
		".kgGggggggggGgk.",
		".kggggggggggggk.",
		".kgGggwwwwggGgk.",
		".kwwkgwwwwgkwwk.",
		"..kkkkkkkkkkkk..",
	],
	"mouse": [
		"................................",
		"................................",
		"................................",
		"................................",
		"..........kk..............kk....",
		".........kpgk............kpgk...",
		"....kkkkkkggk.......kkkkkkggk...",
		"...kggggggggkk.....kggggggggkk..",
		"..kgggggggggnk....kgggggggggnk..",
		"..kggggggggggpk...kggggggggggpk.",
		"k.kgggggggggkk..k.kgggggggggkk..",
		".kkggggggggk.....kkggggggggk....",
		"...kkkkkkkk........kkkkkkkk.....",
		"....k..k..k........k..k..k......",
		"................................",
		"................................",
	],
	"rat": [
		"................................",
		"................................",
		"................................",
		"................................",
		"..........kk..............kk....",
		".........kpbk............kpbk...",
		"....kkkkkkbbk.......kkkkkkbbk...",
		"...kbbbbbbbbkk.....kbbbbbbbbkk..",
		"..kbbbbbbbbbnk....kbbbbbbbbbnk..",
		"..kbbbbbbbbbbpk...kbbbbbbbbbbpk.",
		"k.kbbbbbbbbbkk..k.kbbbbbbbbbkk..",
		".kkbbbbbbbbk.....kkbbbbbbbbk....",
		"...kkkkkkkk........kkkkkkkk.....",
		"....k..k..k........k..k..k......",
		"................................",
		"................................",
	],
	"armored_rat": [
		"................................",
		"................................",
		"................................",
		"................................",
		"..........kk..............kk....",
		".........kpGk............kpGk...",
		"....kLLLLkGGk.......kLLLLkGGk...",
		"...LLLLLLLGGkk.....LLLLLLLGGkk..",
		"..kGGGGGGGGGnk....kGGGGGGGGGnk..",
		"..kGGGGGGGGGGpk...kGGGGGGGGGGpk.",
		"k.kGGGGGGGGGkk..k.kGGGGGGGGGkk..",
		".kkGGGGGGGGk.....kkGGGGGGGGk....",
		"...kkkkkkkk........kkkkkkkk.....",
		"....k..k..k........k..k..k......",
		"................................",
		"................................",
	],
	"depot": [
		"................",
		".......kk.......",
		".....kkrrkk.....",
		"...kkrrrrrrkk...",
		".kkrrrrrrrrrrkk.",
		"kkkkkkkkkkkkkkkk",
		".kyyyyyyyyyyyyk.",
		".kyykkkkkkkkyyk.",
		".kyykGgGgGgkyyk.",
		".kyykgGgGgGkyyk.",
		".kyykGgGgGgkyyk.",
		".kyykgGgGgGkyyk.",
		".kyykGgGgGgkyyk.",
		".kyykgGgGgGkyyk.",
		".kkkkkkkkkkkkkk.",
		"................",
	],
	"kibble": [
		".bb.",
		"bBBb",
		"bBBb",
		".bb.",
	],
	"fish": [
		"..kkkk.k",
		".klllLkk",
		"klnlllLk",
		".klllLkk",
		"..kkkk.k",
	],
	"yarn": [
		"..kkkk..",
		".kppPPk.",
		"kpPppPpk",
		"kPppPppk",
		"kppPppPk",
		"kpPppPpk",
		".kPppPk.",
		"..kkkk..",
	],
	"coin": [
		"..kkkk..",
		".kyyyyk.",
		"kyyYyyyk",
		"kyyYyyyk",
		"kyyYyyyk",
		"kyyYyyyk",
		".kyyyyk.",
		"..kkkk..",
	],
	"heart": [
		".kk..kk.",
		"krrkkrrk",
		"krrrrrrk",
		"krrrrrrk",
		".krrrrk.",
		"..krrk..",
		"...kk...",
		"........",
	],
	"flag": [
		"kyyyy...",
		"kyyyyyy.",
		"kyyyy...",
		"k.......",
		"k.......",
		"k.......",
		"k.......",
		"kk......",
	],
}

static var _cache := {}


static func texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var rows: Array = SPRITES[name]
	var image := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch != ".":
				image.set_pixel(x, y, PALETTE[ch])
	var tex := ImageTexture.create_from_image(image)
	_cache[name] = tex
	return tex


# The three ground tiles side by side: grass, path, rock. Generated with a fixed
# seed so the map looks the same on every run.
static func tile_atlas() -> Texture2D:
	if _cache.has("_tiles"):
		return _cache["_tiles"]
	var image := Image.create(TILE * 3, TILE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grass := Color("38b764")
	var dirt := Color("c2a26b")
	for y in TILE:
		for x in TILE:
			var r := rng.randf()
			image.set_pixel(x, y, Color("a7f070") if r < 0.04 else Color("257179") if r < 0.08 else grass)
			image.set_pixel(TILE + x, y, Color("9c7a4a") if r < 0.10 else Color("e0c48c") if r < 0.14 else dirt)
			image.set_pixel(TILE * 2 + x, y, grass)
	# Rock: a shaded boulder on grass.
	var centre := Vector2(TILE * 2 + 7.5, 8.5)
	for y in TILE:
		for x in range(TILE * 2, TILE * 3):
			var d := Vector2(x, y).distance_to(centre)
			if d < 6.0:
				image.set_pixel(x, y, Color("94b0c2") if (x - TILE * 2) + y < 15 else Color("566c86"))
			elif d < 7.0:
				image.set_pixel(x, y, Color("1a1c2c"))
	var tex := ImageTexture.create_from_image(image)
	_cache["_tiles"] = tex
	return tex
