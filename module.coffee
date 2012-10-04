try require('bling')

Function::has = Function::is = (cls) ->
		for k,v of cls::
			proto = @::
			proto[k] = switch $.type v
				when "function" then do (v,f=proto[k]) ->
					-> f?.apply @, arguments; v.apply @, arguments
				else v

class Modular extends $.EventEmitter
	constructor: $.trace("Modular-constructor", -> @init() )
	init: $.trace("Modular-init", -> )

	proxy: (array, names...) ->
		for i in [0...names.length] by 1 then do (i) =>
			name = names[i]
			$.defineProperty @, name,
				get: -> array[i]
				set: (v) -> array[i] = v
		@

if require?.main is module
	require('bling')
	class Volume extends Modular
		init: ->
			@proxy @size = $(0,0,0), 'w', 'h', 'd'
			@proxy @size, 'width', 'height', 'depth'

	class Position extends Modular
		init: ->
			@proxy @pos = $(0,0,0), 'x', 'y', 'z'
		position: (@x,@y,@z=0) -> @
		preDraw: (ctx) ->
			ctx.translate @x, @y

	class Velocity extends Modular
		init: -> @proxy @vel = $(0,0,0), 'vx', 'vy', 'vz'
		velocity: (@vx,@vy,@vz=0) -> @
		tick: (dt) -> @pos.add @vel.scale dt

	class Rotation extends Modular
		init: -> @rot = 0
		rotation: (deg) ->
			while deg < 0 then deg += 360
			while deg > 360 then deg -= 360
			@rot = $.deg2rad deg
			@
		preDraw: (ctx) -> ctx.rotate @rot

	class Filling extends Modular
		init: -> @fillStyle = "black"
		fill: (@fillStyle) -> @
		preDraw: (ctx) ->
			ctx.fillStyle = @fillStyle

	class Stroking extends Modular
		init: -> @strokeStyle = "black"
		stroke: (@strokeStyle) -> @
		preDraw: (ctx) ->
			ctx.strokeStyle = @strokeStyle

	class Visible extends Modular
		tick: (dt) ->
		draw: (ctx) ->
		preDraw: (ctx) -> ctx.save()
		postDraw: (ctx) -> ctx.restore()
		@has Position
		@has Volume
		@has Rotation
		@has Filling
		@has Stroking
	
	class Goals
		init: ->
			@goals = $()
			$.defineProperty @, 'goal',
				get: => @goals.first()
		addGoal: (x,y,z=0) ->
			@goals.push $(x,y,z)
		tick: (dt) ->
			if @goal?
				@vel = @goal.minus(@pos).scale(@vel.magnitude())
		@has Velocity

	class Entity extends Modular
		@is Visible
		@has Goals

	ctx =
		save: -> $.log "ctx.save()"
		restore: -> $.log "ctx.restore()"
		translate: -> $.log "ctx.translate()"
		rotate: -> $.log "ctx.rotate()"

	f = new Visible().position(10,10).rotation(320)
	f.preDraw(ctx)
	f.draw(ctx)
	f.postDraw(ctx)
	$.log f


