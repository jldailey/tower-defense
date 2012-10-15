# Tower Defense.

# One thing that is currently fragile that I don't like is that you have to
# extend from Modular if you want to be directly constructable, otherwise the
# init: chain is never bootstrapped.

#include "shims.coffee"
#include "values.coffee"
#include "modular.coffee"

#define EMIT_ON_CHANGE(name,default) name = default; $.defineProperty(@,'name',{get:(->name),set:(v)->@emit 'name', name = v})

class Size
	init: ->
		proxy @, @pos = $(0,0,0), 'x', 'y', 'z'
		proxy @, @vol = $(0,0,0), 'w', 'h', 'd'
	size: (@w,@h=@w,@d=0) -> @
	position: (@x,@y,@z=0) -> @
	preDraw: (ctx) ->
		if @x isnt 0 or @y isnt 0
			ctx.translate @x, @y

#define VEC_ADD(v,a) [v[0]+a,v[1]+a,v[2]+a]
#define VEC_ADD_INPLACE(v,a) (v[0]+=a;v[1]+=a;v[2]+=a)
#define VEC_ADDV(v,w) [v[0]+w[0],v[1]+w[1],v[2]+w[2]]
#define VEC_ADDV_INPLACE(v,w) (v[0]+=w[0];v[1]+=w[1];v[2]+=w[2])
#define VEC_SCALE(v,r) [v[0]*r, v[1]*r, v[2]*r]
#define VEC_SCALE_INPLACE(v, r) (v[0]*=r;v[1]*=r;v[2]*=r)
#define VEC_SUBV(v,w) [v[0]-w[0],v[1]-w[1],v[2]-w[2]]
#define VEC_MAG(v) Math.sqrt((v[0]*v[0]) + (v[1]*v[1]) + (v[2]*v[2]))
#define VEC_REPLACE(v,w) (v[0]=w[0];v[1]=w[1];v[2]=w[2])
#define VEC_XROT(v) $.rad2deg(Math.acos(v[0] / VEC_MAG(v)))

class Velocity
	init: -> proxy @, @vel = $(0,0,0), 'vx', 'vy', 'vz'
	velocity: (@vx,@vy,@vz=0) -> @
	tick: (dt) ->
		v = VEC_SCALE(@vel, dt)
		VEC_ADDV_INPLACE(@pos, v)

class Acceleration
	init: -> proxy @, @acc = $(0,0,0), 'ax', 'ay', 'az'
	accel: (@ax,@ay,@az=0) -> @
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

class Destroyable extends Modular
	init: -> EMIT_ON_CHANGE(destroyed, false)
	destroy: -> @destroyed = true

class Highlight extends Modular
	init: -> @highlightTime = 0
	tick: (dt) -> @highlightTime = Math.max(0, @highlightTime - dt)
	highlight: (@highlightTime) -> @
	drawHighlight: (ctx) ->
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

class Scale
	preDraw: (ctx) -> ctx.scale @scaler... if @scaler
	scale: (@scaler...) -> @

class Drawable extends Modular
	init: ->
	tick: (dt) ->
	draw: (ctx) ->
	preDraw: (ctx) ->
	postDraw: (ctx) ->
	@has Size
	@has Scale
	@has Rotation
	@has Color
	@has Highlight
	@is Indexed
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

class Waypoints
	init: ->
		@waypoints = $()
		@threshold = 1
		$.defineProperty @, 'waypoint',
			get: => @waypoints.first()
	addPlan: (points...) ->
		for xy in points
			@addWaypoint(xy[0],xy[1])
	addWaypoint: (x,y) ->
		@waypoints.push [x,y]
		@
	tick: (dt) ->
		wp = @waypoint
		return unless wp
		v = VEC_SUBV(wp, @pos)
		m = VEC_MAG(v)
		VEC_REPLACE(@vel, v)
		if m < @threshold then @waypoints.shift()
		if @waypoints.length is 0
			VEC_SCALE_INPLACE(@vel, 0)

class Quality
	init: ->
		@quality = 1.0
		@decayPerMs = 0
	decay: (@decayPerMs) -> @
	tick: (dt) -> @quality = Math.max(0, @quality - @decayPerMs * dt )

class window.Road extends Modular
	draw: (ctx) ->
		dashLen = (@h/6)+1
		shoulder = Math.floor(@h/18)
		mid = (@h/2)
		lineWidth = @h/25
		stopLineOffset = 14
		stopLineWidth = 4
		crosswalkOffsetA = 3
		crosswalkOffsetB = 8
		white = "rgba(255,255,255,#{@quality})"
		ctx.translate 0,-mid
		ctx.fillStyle = "#333"
		ctx.fillRect 0,0,@w,@h
		# the first stop line
		ctx.drawLine shoulder*stopLineOffset,shoulder,shoulder*stopLineOffset,mid*1.02, lineWidth*stopLineWidth, white
		# the first crosswalk
		ctx.drawLine shoulder*crosswalkOffsetA,shoulder,shoulder*crosswalkOffsetA,@h-shoulder, lineWidth, white
		ctx.drawLine shoulder*crosswalkOffsetB,shoulder,shoulder*crosswalkOffsetB,@h-shoulder, lineWidth, white
		# the first white shoulder line
		ctx.drawLine shoulder*crosswalkOffsetB,shoulder,@w-shoulder*crosswalkOffsetB,shoulder, lineWidth,white
		# the yellow dashed line down the middle
		ctx.drawLine shoulder*stopLineOffset,mid,@w - shoulder*stopLineOffset,mid, lineWidth,"yellow",[dashLen, dashLen*.8]
		# the second white shoulder line
		ctx.drawLine shoulder*crosswalkOffsetB,@h - shoulder, @w-shoulder*crosswalkOffsetB, @h - shoulder, lineWidth,white
		# the second stop line
		ctx.drawLine @w-shoulder*stopLineOffset,mid*0.98,@w-shoulder*stopLineOffset,@h-shoulder, lineWidth*stopLineWidth, white
		# the second crosswalk
		ctx.drawLine @w-shoulder*crosswalkOffsetA,shoulder,@w-shoulder*crosswalkOffsetA,@h-shoulder, lineWidth, white
		ctx.drawLine @w-shoulder*crosswalkOffsetB,shoulder,@w-shoulder*crosswalkOffsetB,@h-shoulder, lineWidth, white
	@is Drawable
	@has Quality

class Intersection extends Modular
	draw: (ctx) ->
		ctx.translate -@w,-@h/2
		ctx.fillStyle = "#333"
		ctx.fillRect 0,0,@w,@h
		shoulder = Math.ceil(@h/18)
		lineWidth = @h/25
		# ctx.drawLine shoulder,shoulder,shoulder,@h - shoulder, lineWidth, "white"
		# ctx.drawLine shoulder,shoulder,@w - shoulder, shoulder, lineWidth, "white"
		# ctx.drawLine @w - shoulder,shoulder,@w - shoulder, @h - shoulder, lineWidth, "white"
		# ctx.drawLine shoulder,@h - shoulder,@w - shoulder, @h - shoulder, lineWidth, "white"
	@is Drawable
	@has Quality

#define LIGHT_COLOR(alpha) "rgba(245,245,210,"+(alpha)+")"
class window.LightCone extends Modular
	tick: (dt) ->
	draw: (ctx) ->
		gradient = ctx.createRadialGradient( @w/2,0, 1, @w/2,0, @w/2 )
		gradient.addColorStop 0, LIGHT_COLOR(@quality*.9)
		gradient.addColorStop 1, LIGHT_COLOR(0)
		ctx.fillStyle = gradient
		ctx.fillRect 0,0,@w,@h
	@is Drawable
	@has Quality

class window.StreetLight extends Modular
	tick: (dt) ->
		# @quality = $.random.coin(.999)
	draw: (ctx) ->
		# draw pole
		x1=@w/3
		x2=@w/2
		y1=-@h/12
		y2=@h*.02
		ctx.beginPath()
		ctx.moveTo x1,0
		ctx.lineTo x2,y1
		ctx.lineTo x2,4
		ctx.lineWidth = 2
		ctx.strokeStyle = "rgba(0,0,0,.8)"
		ctx.stroke()
		ctx.closePath()

		ctx.beginPath()
		ctx.moveTo x1+1,0
		ctx.lineTo x2-2,y1+2
		ctx.lineTo x2-2,4
		ctx.strokeStyle = LIGHT_COLOR(@quality*.6)
		ctx.stroke()
		ctx.closePath()

		# draw bulb
		ctx.beginPath()
		ctx.strokeStyle = LIGHT_COLOR(@quality)
		ctx.lineWidth = 4
		ctx.arc x2,0,y2,0,Math.PI
		ctx.stroke()
		ctx.closePath()
	@has LightCone

class window.Sidewalk extends Modular
	draw: (ctx) ->
		ctx.fillStyle = "lightgrey"
		ctx.fillRect 0,0,@w,@h
		for i in [@h...@w] by @h*1.3
			ctx.drawLine i,0,i,@h, 1, "darkgrey"
	@is Drawable

class window.Grass extends Modular
	draw: (ctx) ->
		unless @imgData
			$.delay 1000, => delete @imgData
			canvas = document.createElement('canvas')
			canvas.setAttribute('width', @w)
			canvas.setAttribute('height', @h)
			ctx2 = canvas.getContext('2d')
			ctx2.fillStyle = "lightgrey"
			ctx2.fillRect 0,0,@w,@h
			ctx2.beginPath()
			ctx2.strokeStyle = "rgba(#{Math.floor(10+(1-@quality)*90)},100,#{Math.floor 10+(1-@quality)*60},.8)"
			ctx2.lineWidth = 2
			x = 0
			q = @quality
			qs = 1 # Math.sin(q*2*Math.PI)
			while x < @w
				y = 0
				while y < @h
					ctx2.moveTo x,y
					ctx2.lineTo x+5,y-5
					y += $.random.integer 2,4/qs
				x += $.random.integer 2,4/qs
			ctx2.stroke()
			ctx2.closePath()
			@imgData = ctx2.getImageData 0,0,@w,@h
		ctx.putImageData @imgData, @x, @y
	@is Drawable
	@has Quality

class Game
	constructor: (opts, objects...) ->
		opts = $.extend {
			canvas: "#canvas"
			w: 640
			h: 480
			fps: 60
		}, opts
		ctx = @ctx = (@canvas = $ opts.canvas).select('getContext').call('2d').first()
		ctx.drawLine = (a,b,c,d, width=1, style="1px solid black", dashing=[0]) ->
			@beginPath()
			@setLineDash dashing
			@moveTo a,b
			@lineWidth = width
			@strokeStyle = style
			@lineTo c,d
			@stroke()
			@closePath()

		@canvas.attr('width', $.px opts.w).attr('height', $.px opts.h)
		interval = null
		objects = @objects = $()
		$.extend @,
			started: false,
			add: (items...) ->
				for item in items then do (item) ->
					objects.splice (index = $.sortedIndex objects, item, 'z'), 0, item
					item.on 'layer', (newLayer) ->
						objects.splice index, 1
						objects.splice (index = $.sortedIndex objects, item, 'z'), 0, item
					item.on 'destroyed', (destroyed) ->
						if destroyed and (i = objects.indexOf item) > -1
							objects.splice i, 1
				@
			tick: (dt = 1) ->
				ctx.clearRect 0,0,opts.w,opts.h
				for obj in objects
					obj.tick dt, @
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
				@started = true
				t = $.now
				ticker = =>
					dt = $.now - t
					t = $.now
					@tick dt
					interval = requestInterval ticker
				interval = requestInterval ticker
			stop: ->
				return unless @started
				@started = false
				cancelInterval interval
			toggle: ->
				if @started then @stop() else @start()

$(document).ready ->
	class Tracer extends Modular
		init: ->
			@fps = new SmoothValue 30
		message: (@msg) -> @
		tick: (dt) ->
			@fps.value = 1000/Math.max 1, dt
			@label = "FPS: #{@fps.value.toFixed 0} DT: #{dt}" + (if @msg then " Message: #{@msg}" else "")
		@has Label
	
	class Ball extends Circle
		@has Velocity
		@has Waypoints
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

	window.game = new Game canvas: "#gameCanvas", w: window.innerWidth, h: window.innerHeight
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
		game.add new Circle().position(a,b).fill("blue").radius(2)
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
		d = 0.000001 # decay
		game.add new Road().position(a,b,0).size(w,roadWidth,0).rotation(r).decay(d)
		if i < points.length - 1
			game.add new Intersection().position(a,b).size(roadWidth,roadWidth,0).rotation(r).decay(d)
	game.add new Road().position(300,215).size(70,roadWidth).rotation(90)
	game.add new Intersection().position(300,315).size(roadWidth).rotation(90)

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
	game.add new Grass().position(65,0).size(280,75).decay(.0001)
	game.add new Grass().position(0,0).size(15,135).decay(.0001)
	game.add new Grass().position(0,125).size(275,50).decay(.0001)
	game.add new Grass().position(385,0).size(25,370).decay(.0001)
	game.add new Grass().position(172,325).size(215,45).decay(.0001)
	game.add new Grass().position(0,170).size(175,200).decay(.0001)
	game.add window.grass = new Grass().position(325,70).size(20,205).decay(.0001)

	game.tick(16.66)

	$("#gameCanvas").click -> game.toggle()
