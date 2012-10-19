# Tower Defense.

# One thing that is currently fragile that I don't like is that you have to
# extend from Modular if you want to be directly constructable, otherwise the
# init: chain is never bootstrapped.

#include "shims.coffee"
#include "values.coffee"
#include "modular.coffee"

#define EMIT_ON_CHANGE(name,default) name = default; $.defineProperty(@,'name',{get:(->name),set:(v)->@emit 'name', name = v})

#include "phys.coffee"

class Destroyable extends Modular
	init: -> EMIT_ON_CHANGE(destroyed, false)
	destroy: -> @destroyed = true

class Highlight extends Modular
	init: -> @highlightTime = 0
	tick: (dt) -> @highlightTime = Math.max(0, @highlightTime - dt)
	highlight: (@highlightTime) -> @
	drawHighlight: (ctx) ->
		$.log "drawing highlight"
		ctx.beginPath()
		ctx.strokeStyle = "red"
		ctx.lineWidth = 2
		ctx.moveTo 0,0
		ctx.lineTo @w,0
		ctx.lineTo @w,@h
		ctx.lineTo 0,@h
		ctx.lineTo 0,0
		ctx.stroke()
		ctx.closePath()
	draw: (ctx) ->
		if @highlightTime > 0
			@drawHighlight(ctx)

class window.Indexed
	index = {}
	init: ->
		index[@guid = $.random.string 16] = @
		@on 'destroy', -> delete index[@guid]
	@find: (guid) -> index[guid]

class Managed extends Modular
	@mixin Size
	@mixin Indexed
	@mixin Highlight
	@mixin Destroyable

class Drawable extends Modular
	@mixin Managed
	@mixin Color
	@mixin Scale
	@mixin Rotation

class Elapsed extends Modular
	init: -> @elapsed = 0
	tick: (dt) -> @elapsed += dt

class Cached extends Modular
	init: ->
		@age = 0
		@ageLimit = 1000
	ttl: (@ageLimit) -> @
	tick: (dt) ->
		if (@age += dt) > @ageLimit
			unless @ageLimit is -1
				delete @cacheData
	draw: (ctx, game) ->
		unless @cacheData
			unless @cacheCanvas
				canvas = document.createElement('canvas')
				canvas.setAttribute('width', @w)
				canvas.setAttribute('height', @h)
				@cacheCanvas = canvas
			ctx2 = @cacheCanvas.getContext('2d')
			ctx2.clearRect 0,0,@w,@h
			@drawUncached(ctx2, game)
			@cacheData = ctx2.getImageData 0,0,@w,@h
			@age = 0
		ctx.putImageData @cacheData, @x, @y


class window.Label extends Modular
	init: ->
		proxy @, @labelOffset = $(0,0), 'labelX', 'labelY'
	text: (@label) -> @
	textOffset: (@labelX, @labelY=0) ->
	draw: (ctx) -> (ctx.fillText @label, @labelX, @labelY) if @label?.length > 0
	@mixin Drawable

#include "shapes.coffee"
#include "sprite.coffee"
#include "art.coffee"

class Waypoints
	init: ->
		@waypoints = $()
		@threshold = 1
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
		if m < @threshold
			@waypoints.shift()
			wp[2]?.apply @
		if @waypoints.length is 0
			VEC_SCALE_INPLACE(@vel, 0)

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
	@mixin Destroyable

class Frames
	init: ->
		@frame = 0
		@frames = []
		@fps = 60
	frames: (@frames...) -> @
	tick: (dt) -> @frame = (@frame + @fps*dt/1000) % @frames.length

class Tracer extends Modular
	init: ->
		@fps = new SmoothValue 30
	message: (@msg) -> @
	tick: (dt) ->
		@fps.value = 1000/Math.max 1, dt
		@label = "FPS: #{@fps.value.toFixed 0} DT: #{dt}" + (if @msg then " Message: #{@msg}" else "")
	@mixin Label

class Ball extends Modular
	@mixin Velocity
	@mixin Waypoints
	@mixin Speed
	@mixin Circle

class window.ProgressBar extends Modular
	init: ->
		@update(0).background("white").border("black").color("red")
	update: (@progress) -> @
	background: (@progressBg) -> @
	border: (@progressBorder) -> @
	color: (@progressColor) -> @
	draw: (ctx) ->
		ctx.fillStyle = @progressBg
		ctx.fillRect 0,0,@w,@h
		ctx.strokeStyle = @progressBorder
		ctx.strokeRect 0,0,@w,@h
		ctx.fillStyle = @progressColor
		$.log "[#{@guid}] filling rect out to #{@w*@progress} #{@progress}"
		ctx.fillRect 1,1,@w*@progress,@h-1
	@mixin Managed

class Game
	constructor: (opts, objects...) ->
		$.extend @, $.extend {
			w: 640
			h: 480
		}, opts
		@canvas = $.synth("canvas[width=#{@w}][height=#{@h}]").appendTo("body").first()
		@context = ctx = $.extend @canvas.getContext('2d'),
			linePath: (points...) ->
				return unless points.length >= 4
				@beginPath()
				[a,b] = points.splice 0,2
				@moveTo a,b
				while points.length > 1
					[a,b] = points.splice 0,2
					@lineTo a,b
				@closePath()
			circlePath: (x,y,r) ->
				@beginPath()
				@arc x,y,r,0,2*Math.PI
				@closePath()
		@context.translate 0.5, 0.5
		@context.webkitImageSmoothingEnabled = false

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
					objects.splice (index = $.sortedIndex objects, item, 'z'), 0, item
					item.on 'layer', (newLayer) ->
						objects.splice index, 1
						objects.splice (index = $.sortedIndex objects, item, 'z'), 0, item
						objects.emit 'change'
					item.on 'destroyed', (destroyed) ->
						if destroyed and (i = objects.indexOf item) > -1
							objects.splice i, 1
							objects.emit 'change'
				objects.emit 'change'
				@
			tick: (dt = 16.66) ->
				ctx.clearRect 0,0,@w,@h
				for obj in objects
					obj?.tick dt, @
				for obj in objects
					try
						ctx.save()
						obj.preDraw ctx, @
						obj.draw ctx, @
						obj.postDraw ctx, @
					finally
						ctx.restore()
				$.now
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

readyLatch = Textures.length
for texture in Textures
	$.log "Caching texture: #{texture}"
	new Sprite().image "img/#{texture}", ->
		if --readyLatch <= 0
			$.provide "images-ready"
$(document).ready ->
	$.depends 'images-ready', ->
		window.game = new Game w: window.innerWidth, h: window.innerHeight
		# game.add window.ground = new TileLayer()
			# .image("img/dirt.jpg")
			# .position(0,0,-1)
			# .tileSize(100)

		points = [
			[40,0],
			[40,100],
			[300,100],
			[300,200],
			[200,200],
			[200,300],
			[370,300],
			[370,0]
		]
		roadWidth = 30
		for i in [0...points.length-1] by 1
			[a,b] = points[i]
			[c,d] = points[i+1]
			v = [c-a,d-b,0]
			r = VEC_XROT(v) # degrees offset from the [1,0,0] vector
			w = VEC_MAG(v)
			halfw = roadWidth / 2
			if v[1] < 0
				r *= -1
				b -= halfw
			if v[1] > 0
				b += halfw
				w -= halfw
			if v[0] > 0
				a += halfw
				w -= halfw
			if v[0] < 0
				a -= halfw
				w -= halfw
			w -= halfw
			d = 0.00001 # decay
			game.add new Road().position(a,b,0).size(w,roadWidth,0).rotation(r).decay(d)
			if i < points.length - 1
				game.add new Intersection().position(a,b,0).size(roadWidth,roadWidth,0).rotation(r).decay(d)
		game.add new Road().position(300,215).size(70,roadWidth).rotation(90)
		# game.add new Intersection().position(300,315).size(roadWidth).rotation(90)

		spawner = ->
			for i in [0...10] by 1
				profile = $.random.real(0,1)
				game.add b = new Ball()
					.fill(colors[Math.floor(profile * colors.length)])
					.radius( 4 + profile*8 )
					.speed( .02 + (1-profile)*.05 )
					.position(40,0)
				for point in points
					b.addWaypoint(point...)

		game.add window.tracer = new Tracer().position(10,10,1000)
		# game.add new Grass().position(0,0,-1).size(game.w,game.h)
		game.add new PineTree().position(100,100,1).size(30,100)
		colors = ["red", "orange", "yellow", "green", "lightblue", "blue"]
		for j in [0...0] by 1
			$.delay j*5000, spawner

		game.add new StreetLight().position(180,85, 10).size(100).scale(-1,1)
		# game.add new StreetLight().position(280,115, 10).size(100).scale(-1,-1)
		game.add new StreetLight().position(385,135, 10).size(100).rotation(90).scale(1,-1)
		game.add new StreetLight().position(385,295, 10).size(100).rotation(90).scale(1,-1)
		game.add new StreetLight().position(315,235, 10).size(100).rotation(90).scale(1,-1)
		game.add new StreetLight().position(185,270, 10).size(100).rotation(90).scale(-1,-1)
		game.add new StreetLight().position(230,315, 10).size(100).rotation(-180).scale(-1,1)
		game.add new Sidewalk().position(55,75).size(260,10)
		game.add new Sidewalk().position(25,115).size(260,10)
		game.add new Sidewalk().position(315,275).size(40,10)
		game.add new Sidewalk().position(185,315).size(200,10)
		game.add new Sidewalk().position(185,175).size(100,10)
		game.add new Sidewalk().position(325,75).size(200,10).rotation(90)
		game.add new Sidewalk().position(285,115).size(70,10).rotation(90)
		game.add new Sidewalk().position(355,0).size(275,10).rotation(90)
		game.add new Sidewalk().position(25,0).size(125,10).rotation(90)
		game.add new Sidewalk().position(185,175).size(150,10).rotation(90)
		game.add new Sidewalk().position(65,0).size(80,10).rotation(90)
		# game.add new Grass().position(0,0).size(15,135).decay(.0001)
		# game.add new Grass().position(0,125).size(275,50).decay(.0001)
		# game.add new Grass().position(385,0).size(25,370).decay(.0001)
		# game.add new Grass().position(172,325).size(215,45).decay(.0001)
		# game.add new Grass().position(0,170).size(175,200).decay(.0001)
		# game.add window.grass = new Grass().position(325,70).size(20,205).decay(.0001)

		game.tick(16.66)

		$.provide 'game'
