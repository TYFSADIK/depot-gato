# game_state.gd: autoload singleton, the shared data bus.
# Owns lives, currency and wave number. Gameplay nodes call its methods;
# the HUD only listens to its signals, so nothing holds a reference to the HUD.
extends Node

signal currency_changed(new_value: int)
signal lives_changed(new_value: int)
signal wave_changed(wave: int, total: int)
signal countdown_changed(seconds_left: int)
signal game_over(won: bool)

const START_CURRENCY := 120
const START_LIVES := 20

var currency := START_CURRENCY
var lives := START_LIVES
var wave := 0
var total_waves := 0
var is_over := false


func reset(waves: int) -> void:
	currency = START_CURRENCY
	lives = START_LIVES
	wave = 0
	total_waves = waves
	is_over = false
	currency_changed.emit(currency)
	lives_changed.emit(lives)
	wave_changed.emit(wave, total_waves)


func can_afford(cost: int) -> bool:
	return currency >= cost


func spend(cost: int) -> bool:
	if is_over or currency < cost:
		return false
	currency -= cost
	currency_changed.emit(currency)
	return true


func earn(amount: int) -> void:
	if is_over:
		return
	currency += amount
	currency_changed.emit(currency)


func lose_lives(amount: int) -> void:
	if is_over:
		return
	lives = maxi(0, lives - amount)
	lives_changed.emit(lives)
	if lives == 0:
		finish(false)


func set_wave(number: int) -> void:
	wave = number
	wave_changed.emit(wave, total_waves)


func finish(won: bool) -> void:
	if is_over:
		return
	is_over = true
	game_over.emit(won)
