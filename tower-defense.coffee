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

if not require?
	require = (lib) ->
		script = document.createElement "script"
		script.src = "js/#{lib}.js"
		document.head.appendChild script

require 'bling'

deg2rad = (deg) ->
	deg*Math.PI/180

Rules =
	startingGold: 500

waitingImages = 0
Images = { }
for asset in Assets
	GetImage(url)
	# could do this old-school arcade style and tile them across the screen

GetImage = (url, callback) ->
	if not url of Images
		waitingImages += 1
		Images[url] = new Image(url) # pre-load asset images
		Images[url].on 'load', (args...) ->
			waitingImages -= 1
			callback.apply @, args
	else callback.apply @, args

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
		super.call @, (x, dt) => x + (dt*@rate)

chain = (f) -> (args...) -> (f args...); @
GameObjects = {}
class GameObject extends $.EventEmitter
	constructor: ->
		GameObjects[@guid or= $.random.string 16] = @
		@valid = True
	destroy: ->
		@valid = False
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
			$.defineProperty obj, name,
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
	constructor: (args...) -> super.apply @, args
	image: (url, onload=->) ->
		@img = new Image url
		@img.on 'load', onload
		@
	draw: (ctx) ->
		ctx.drawImage @img, 0, 0, @w, @h

class Shape extends GameObject
	constructor: (args...) -> super.apply @, args
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
	constructor: (args...) -> super.apply @, args
	radius: (deg) ->
		@radius = deg
	draw: (ctx) ->
		ctx.beginPath()
		ctx.arc 0,0,r,0,2*Math.PI
		ctx.fill()
		ctx.stroke()
		ctx.closePath()

new Circle().position(10,10).radius(10)

Bullets =
	basic:
		name: "Basic Bullet"
		damage: 10
		speed: 5
		shape: new Circle().radius(5).fillStyle("white")

class Bullet extends Sprite
	constructor: (@kind, @target) ->
		@ready = False
		$.extend @, Bullets[@kind]
	aim: (@target) ->
	release: ->
		@ready = True
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
