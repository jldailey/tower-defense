# Tower Defense.
# Definition:
# Monsters spawn at point(s) on a game board and attack target point(s).
# Player must create towers to defend the target point(s).
#
# Entities:
# Players. Game board. Spawn points. Monsters. Towers. Projectiles.

# Game board.
#  A ground tile map (how to draw the ground).
#  A tower map (where have towers been placed).
# Each map is a list of indices into data arrays.
# A ground tile needs to know: an Image, 

deg2rad = (deg) ->
	deg*Math.PI/180

Rules =
	startingGold: 500

Textures =
	grass:
		image: new Image("img/grass.jpg")
	dirt:
		image: new Image("img/dirt.jpg")

class TimeValue # a value that changes at a constant rate
	constructor: (func) ->
		baseValue = baseTime = 0
		$.defineProperty @, 'value',
			get: -> func baseValue, $.now - baseTime
			set: (v) ->
				baseTime = $.now
				baseValue = v
		@value = 0
		@valueAt = (t) -> func baseValue, $.date.stamp(t) - baseTime
class LinearValue extends TimeValue
	constructor: (@rate) ->
		super (x, dt) => x + (dt*@rate)

chain = (f) -> (args...) -> (f args...); @
GameObjects = {}
class GameObject extends $.EventEmitter
	constructor: ->
		GameObjects[@guid or= $.random.string 16] = @
		@valid = true
	destroy: ->
		@valid = false
		@emit 'destroy' # signal the game to forget about us
	tick: (dt) -> # should update your state based on a dt amount of time having passed
	preDraw: (ctx) ->
		ctx.save()
		if @x?
			ctx.translate @x, @y
		if @rot?
			ctx.rotate deg2rad @rot
	draw: (ctx) -> # (optional) draw yourself
	postDraw: (ctx) ->
		ctx.restore()
	rotation: chain (deg) ->
		@rot = deg
	position: (x, y) ->
		@proxy @pos = $(x,y), 'x', 'y'
	size: (w, h) ->
		@proxy @size = $(w, h), "w", "h"
	proxy: chain (array, names...) ->
		for i in [0...names.length] by 1 then do (i) ->
			name = names[i]
			$.defineProperty @, name,
				get: -> arr[i]
				set: (v) -> arr[i] = v

class Game
	constructor: (objs...) ->
		@objects = objs
		@index = {}
		for i in [0...@objects.length] by 1
			@index[@objects[i].guid] = i
			@objects[i].on 'destroy', (guid) =>
				if guid of @index
					@objects.splice @index[guid], 1
					delete @index[guid]

	tick: (dt) ->
		for obj in @objects
			obj.tick(dt)
	draw: (ctx) ->
		for obj in @objects
			obj.preDraw ctx
			obj.draw ctx
			obj.postDraw ctx

class Sprite extends GameObject
	image: (url, onload=->) ->
		@img = new Image url
		@img.on 'load', onload
		@
	draw: (ctx) ->
		ctx.drawImage @img, 0, 0, @w, @h

class Shape extends GameObject
	fillStyle: (style) ->
		@fillStyle = style
		@
	strokeStyle: (style) ->
		@strokeStyle = style
		@
	preDraw: (ctx) ->
		super.call @, ctx
		if @fillStyle?
			ctx.fillStyle @fillStyle
		if @strokeStyle?
			ctx.strokeStyle @strokeStyle

class Circle extends Shape
	radius: (deg) ->
		@rad = deg
		@
	draw: (ctx) ->
		ctx.beginPath()
		ctx.arc 0,0,@rad,0,2*Math.PI
		ctx.fill()
		ctx.stroke()
		ctx.closePath()

new Circle().position(10,10).radius(10)

Bullets =
	basic:
		name: "Basic Bullet"
		damage: 10
		speed: 5
		shape: new Circle().radius(3).fillStyle("grey")

class Bullet extends Sprite
	constructor: (@kind, @target) ->
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

Towers =
	basic:
		name: "Basic Tower"
		cost: 100
		dps: 1.0
		range: 10

class Tower extends Sprite
	constructor: (@kind) ->
		$.extend @, Towers[@kind]

class Player
	constructor: (@name) ->
		@money = new LinearValue 0
		@money.value = Rules.startingGold
		@towers = []
		@inHand = null
	toString: -> "#{@name} (#{@money.value}gp)"
	tick: (dt) ->
		tower.tick(ctx) for tower in towers
	draw: (ctx) ->
	adjustIncome: (amt) ->
		@money.value = @money.value # reset the base time so the rate change is not retroactive
		@money.rate += amt / 1000
	adjustBalance: (amt) ->
		@money.value -= amt
	purchaseTower: (towerCode) ->
		if towerCode of Towers
			tower = Towers[towerCode]
			if @money.value > tower.cost
				@inHand = tower
		null
	placeInHand: (map, pos...) ->
		if @inHand
			map.placeItem @inHand, pos...
		null
	cancelPurchase: ->
		if @inHand
			@adjustBalance +@inHand.cost
		@inHand = null
