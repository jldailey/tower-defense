# Tower Defense.

# One thing that is currently fragile that I don't like is that you have to
# extend from Modular if you want to be directly constructable, otherwise the
# init: chain is never bootstrapped.

#include "shims.coffee"
#include "values.coffee"
#include "modular.coffee"

#define EMIT_ON_CHANGE(name,default) name = default; $.defineProperty(@,'name',{get:(->name),set:(v)->@emit 'name', name = v})

class Volume
	init: ->
		proxy @, @vol = $(0,0), 'w', 'h'
		proxy @, @vol, 'width', 'height'
	size: (@w,@h=@w) -> @

class Position
	init: -> proxy @, (@pos = $ 0,0), 'x', 'y'
	position: (@x,@y) -> @
	preDraw: (ctx) ->
		if @x isnt 0 or @y isnt 0
			$.log "translating to #{@x} #{@y}"
			ctx.translate @x, @y

#define VEC_ADD(v,a) [v[0]+a,v[1]+a]
#define VEC_ADD_INPLACE(v,a) (v[0]+=a;v[1]+=a)
#define VEC_ADDV(v,w) [v[0]+w[0],v[1]+w[1]]
#define VEC_ADDV_INPLACE(v,w) (v[0]+=w[0];v[1]+=w[1])
#define VEC_SCALE(v,r) [v[0]*r, v[1]*r]
#define VEC_SCALE_INPLACE(v, r) (v[0]*=r;v[1]*=r)
#define VEC_SUBV(v,w) [v[0]-w[0],v[1]-w[1]]
#define VEC_MAG(v) Math.sqrt((v[0]*v[0]) + (v[1]*v[1]))
#define VEC_REPLACE(v,w) (v[0]=w[0];v[1]=w[1])

class Velocity
	init: -> proxy @, @vel = $(0,0), 'vx', 'vy'
	velocity: (@vx,@vy) -> @
	tick: (dt) ->
		v = VEC_SCALE(@vel, dt)
		VEC_ADDV_INPLACE(@pos, v)
		$.log "pos: #{@pos} x: #{@x} y: #{@y}"

class Acceleration
	init: -> proxy @, @acc = $(0,0), 'ax', 'ay'
	accel: (@ax,@ay) -> @
	tick: (dt) ->
		a = VEC_SCALE(@acc, dt)
		VEC_ADDV_INPLACE(@vel, a)

class Rotation
	init: -> @rot = 0
	rotation: (deg) ->
		@rot = $.deg2rad deg
		@
	preDraw: (ctx) -> ctx.rotate @rot if @rot

class Color
	init: -> @fill null
	fill: (@fillStyle) -> @
	stroke: (@strokeStyle) -> @
	preDraw: (ctx) ->
		ctx.fillStyle = @fillStyle
		ctx.strokeStyle = @strokeStyle
	draw: (ctx) ->
		ctx.fill() if @fillStyle
		ctx.stroke() if @strokeStyle

class Layer
	init: -> EMIT_ON_CHANGE(layer, 0)
	layerUp: (n=1) -> @layer += n; @
	layerDown: (n=1) -> @layer -= n; @

class Destroyable extends Modular
	init: -> EMIT_ON_CHANGE(destroyed, false)
	destroy: -> @destroyed = true

class Drawable extends Modular
	tick: (dt) ->
	draw: (ctx) ->
	preDraw: (ctx) -> ctx.save()
	postDraw: (ctx) -> ctx.restore()
	@has Position
	@has Volume
	@has Rotation
	@has Color
	@has Layer
	@is Destroyable

class window.Label extends Modular
	constructor: (@label = "Hello") ->
		super @
	init: ->
		proxy @, @labelOffset = $(0,0), 'labelX', 'labelY'
	text: (@label) -> @
	textOffset: (@labelX, @labelY=0) ->
	draw: (ctx) -> (ctx.fillText @label, @labelX, @labelY) if @label?.length > 0
	@is Drawable

#include "shapes.coffee"
#include "sprite.coffee"

class Speed
	init: -> @speed 0
	speed: (@spd) -> @
	tick: (dt) ->
		m = VEC_MAG(@vel)
		if m isnt 0
			m = @spd / m
			VEC_SCALE_INPLACE(@vel, m)

#define WAYPOINT_THRESHOLD 4
class Waypoints
	init: ->
		@waypoints = $()
		$.defineProperty @, 'waypoint',
			get: => @waypoints.first()
	addPlan: (points...) ->
		for xy in points
			@addWaypoint(xy[0],xy[1])
	addWaypoint: (x,y, cb) ->
		@waypoints.push [x,y,cb]
		@
	tick: (dt) ->
		wp = @waypoint
		return unless wp
		v = VEC_SUBV(wp, @pos)
		m = VEC_MAG(v)
		VEC_REPLACE(@vel, v)
		if m < WAYPOINT_THRESHOLD
			@waypoints.shift()
			wp[2]?.apply @
		if @waypoints.length is 0
			VEC_SCALE_INPLACE(@vel, 0)

class Game
	constructor: (opts, objects...) ->
		$.extend @, $.extend {
			w: 640
			h: 480
		}, opts
		@canvas = $.synth("canvas[width=#{@w}][height=#{@h}]").appendTo("body").first()
		@context = ctx = @canvas.getContext '2d'
		interval = null
		$.defineProperty @, 'started',
			get: -> interval isnt null
		$.extend @,
			objects: objects = $()
			add: (items...) ->
				for item in items then do (item) ->
					item = $.extend {
						preDraw: ->
						draw: ->
						postDraw: ->
						tick: ->
					}, item
					objects.splice (index = $.sortedIndex objects, item, 'layer'), 0, item
					item.on 'layer', (newLayer) ->
						objects.splice index, 1
						objects.splice (index = $.sortedIndex objects, item, 'layer'), 0, item
					item.on 'destroyed', (destroyed) ->
						if destroyed and (i = objects.indexOf item) > -1
							objects.splice i, 1
				@
			tick: (dt = 16.66) ->
				ctx.clearRect 0,0,@w,@h
				for obj in objects
					obj?.tick dt, @
				for obj in objects
					obj.preDraw ctx, @
					obj.draw ctx, @
					obj.postDraw ctx, @
				null
			start: ->
				return if @started
				t = $.now
				ticker = =>
					t += (dt = $.now - t)
					@tick dt
					interval = requestInterval ticker
				interval = requestInterval ticker
			stop: ->
				return unless @started
				cancelInterval interval
				interval = null
			toggle: ->
				if @started then @stop() else @start()

$(document).ready ->
	class Tracer extends Modular
		init: ->
			@fps = new SmoothValue 30
		tick: (dt) ->
			@fps.value = 1000/Math.max 1, dt
			@label = "FPS: #{@fps.value.toFixed 0} DT: #{dt}"
		@has Label
	
	class Ball extends Circle
		@has Velocity
		@has Speed
	
	class window.Turret extends Modular
		aimAt: (@target) -> @
		tick: (dt, game) ->
		draw: (ctx, game) ->
			return unless @target
			ctx.moveTo @w/2,@h/2
			ctx.lineTo @target.pos[0],@target.pos[1]
		@is Square
	
	class Frames
		init: -> @frame = 0
		tick: (dt) -> @frame++

	window.game = new Game w: 600, h: 400
	readyLatch = Textures.length
	for texture in Textures
		new Sprite().image "img/#{texture}", ->
			if --readyLatch <= 0
				$.provide "images-ready"

	$.depends 'images-ready', ->
		game.add new Tracer().position(10,10).layerUp()
		game.add snow = new TileLayer().image("img/ground-snow1-0.jpg").layerDown().tileSize(256)
		$("body").zap("style.background", "url(img/ground-snow1-0.jpg) top left repeat")
		colors = ["red", "orange", "yellow", "green", "lightblue", "blue"]
		spawn_monster = (n) ->
			(game) ->
				$.log "spawning #{n} monsters"
				for i in [0...n] by 1
					profile = $.random.real(0,1)
					game.add new Ball()
						.fill(colors[Math.floor(profile * colors.length)])
						.radius( 5 + profile*15 )
						.speed( .02 + (1-profile)*.05 )
						.position(40,0)
						.velocity(10,10)
						# .addWaypoint(40,100)
						# .addWaypoint(300,100)
						# .addWaypoint(300,200)
						# .addWaypoint(200,200)
						# .addWaypoint(200,300)
						# .addWaypoint(370,300)
						# .addWaypoint 370, 0, -> @destroy()

		class window.TimedScript extends Modular
			init: ->
				@tasks = []
				@elapsed = 0
			cue: (time, func) ->
				task = { t: time, f: func }
				@tasks.splice ($.sortedIndex @tasks, task, 't'), 0, task
				@
			tick: (dt, game) ->
				@elapsed += dt
				while @tasks.length > 0 and @tasks[0].t < @elapsed
					@tasks.shift().f(game)
			@has Layer
			@is Destroyable

		game.add script = new TimedScript()
			.cue(50, spawn_monster(1))
			# .cue(5000, spawn_monster(20))
			# .cue(15000, spawn_monster(200))
		
		$(game.canvas).click -> game.toggle()

		game.tick(16.66)
