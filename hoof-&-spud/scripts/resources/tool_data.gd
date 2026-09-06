## One entry in the tool bar.
##
## The player owns an array of these instead of bare tool names, so the bar renders
## an icon without a second lookup table and a new tool is a resource file rather
## than a code change. [member id] is what reaches
## [member HurtboxComponent.accepted_tools], so an axe and a mallet stay
## distinguishable even though the mallet borrows the axe's swing.

class_name ToolData
extends Resource

enum Kind {
	## Damages any hurtbox that accepts [member id]: axe, mallet.
	STRIKE,
	## Turns plain ground into tilled soil.
	TILL,
	## Waters tilled soil so whatever is planted there grows overnight.
	WATER,
	## Sows [member crop] into tilled soil, spending one seed.
	SEED,
}

@export var id: StringName = &""

@export var display_name: String = ""

## 16x16 icon for the tool bar.
@export var icon: Texture2D

@export var kind: Kind = Kind.STRIKE

## Clip block on the player's [SpriteFrames]; several tools share one, since
## sowing reuses the hoe stoop.
@export var animation: StringName = &"chop"

## Damage dealt to a hurtbox that accepts this tool.
@export_range(0, 10) var damage: int = 1

## Crop sown when [member kind] is [constant Kind.SEED].
@export var crop: CropData

