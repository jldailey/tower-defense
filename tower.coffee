
Towers =
	basic:
		name: "Basic Tower"
		cost: 100
		dps: 1.0
		range: 10

class Tower extends Sprite
	constructor: (@kind) ->
		super @
		$.extend @, Towers[@kind]

