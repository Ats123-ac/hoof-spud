## CanvasModulate that follows [GameClock], dimming the farm at dusk and blueing it
## at night.
##
## Lives in the world rather than the HUD because [CanvasModulate] tints the 2D
## canvas it sits in, which a UI layer is not part of.

extends CanvasModulate


func _ready() -> void:
	_apply()


func _process(_delta: float) -> void:
	_apply()


func _apply() -> void:
	color = GameClock.tint()
