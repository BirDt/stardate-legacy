extends Node

signal tick_propagate(t)

var detail_view = false

var camera

var tick : float = 0 :
	set(x):
		tick = x
		tick_propagate.emit(tick)

const FREEZE = 0
const ONE_MINUTE = ((1.0/365.0)/24.0)/60.0 # 1 minute every 4 seconds
const ONE_HOUR = (1.0/365.0)/24.0
const ONE_DAY = 1.0/365.0
const ONE_MONTH = (1.0/365.0)*30
const ONE_YEAR = 1/365.0*30*12

var timescale_index = 1:
	set(x):
		timescale_index = clamp(x, 0, 5)
		timescale = [FREEZE, ONE_MINUTE, ONE_HOUR, ONE_DAY, ONE_MONTH, ONE_YEAR][timescale_index]

var timescale = [FREEZE, ONE_MINUTE, ONE_HOUR, ONE_DAY, ONE_MONTH, ONE_YEAR][timescale_index] # 1 = 1 year / 4 seconds
# 1 hour is 0.00000190258752 * 60 * 4

func _physics_process(delta: float) -> void:
	tick += delta * timescale
