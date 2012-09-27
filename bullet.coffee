
Bullets =
	basic:
		name: "Basic Bullet"
		damage: 10
		speed: 5
		shape: new Circle().radius(3).fillStyle("grey")

class Bullet extends Sprite
	constructor: (@kind, @target) ->
		super @
		@ready = false
		$.extend @, Bullets[@kind]
	aim: (@target) ->
		@
	release: ->
		@ready = true
	tick: (dt) ->
		if @ready
			d = target.pos.minus @pos # vector from us to the target
			dm = d.magnitude()
			@pos = @pos.plus d.normalize().scale @speed # move
			if dm - @speed <= 0
				@target.emit 'impact', @

new Bullet('basic')
	.position(5, 5)
	.aim( pos: $(10,10) )
	.release()
