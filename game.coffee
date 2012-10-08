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
		proxy @, @vol = $(0,0,0), 'w', 'h', 'd'
		proxy @, @vol, 'width', 'height', 'depth'
	size: (@w,@h=@w,@d=0) -> @

class Position
	init: -> proxy @, @pos = $(0,0,0), 'x', 'y', 'z'
	position: (@x,@y,@z=0) -> @
	preDraw: (ctx) ->
		if @x isnt 0 or @y isnt 0
			ctx.translate @x, @y

#define VEC_ADD_INLINE(a,b) for i in [0...3] then a[i] += b[i]
#define VEC_SCALE(v,r) [v[0]*r, v[1]*r, v[2]*r]
#define VEC_MAG(v) Math.sqrt((v[0]*v[0]) + (v[1]*v[1]) + (v[2]*v[2]))
#define VEC_NORMALIZE(v) VEC_SCALE(v, 1/VEC_MAG(v))

class Velocity
	init: -> proxy @, @vel = $(0,0,0), 'vx', 'vy', 'vz'
	velocity: (@vx,@vy,@vz=0) -> @
	speed: (px_ms) ->
		@vel.replaceWith @vel.normalize().scale(px_ms)
	tick: (dt) ->
		v = VEC_SCALE(@vel, dt)
		VEC_ADD_INLINE(@pos, v)

class Rotation
	init: -> @rot = 0
	rotation: (deg) ->
		@rot = $.deg2rad deg
		@
	preDraw: (ctx) -> ctx.rotate @rot if @rot

class Filling
	init: -> @fill null
	fill: (@fillStyle) -> @
	preDraw: (ctx) -> ctx.fillStyle = @fillStyle
	draw: (ctx) -> ctx.fill() if @fillStyle

class Stroking
	init: -> @stroke(null)
	stroke: (@strokeStyle) -> @
	preDraw: (ctx) -> ctx.strokeStyle = @strokeStyle
	draw: (ctx) -> ctx.stroke() if @strokeStyle

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
	@has Filling
	@has Stroking
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

class Goals
	init: ->
		@goals = $()
		$.defineProperty @, 'goal',
			get: => @goals.coalesce()
	tick: (dt) ->
		speed = @vel.magnitude()


class Game
	constructor: (opts, objects...) ->
		opts = $.extend {
			canvas: "#canvas"
			w: 640
			h: 480
			fps: 60
		}, opts
		ctx = @ctx = (@canvas = $ opts.canvas).select('getContext').call('2d').first()
		@canvas.attr('width', $.px opts.w).attr('height', $.px opts.h)
		interval = null
		objects = @objects = $()
		$.extend @,
			add: (items...) ->
				for item in items then do (item) ->
					objects.splice (index = $.sortedIndex objects, item, 'layer'), 0, item
					item.on 'layer', (newLayer) ->
						objects.splice index, 1
						objects.splice (index = $.sortedIndex objects, item, 'layer'), 0, item
					item.on 'destroyed', (destroyed) ->
						if destroyed and (i = objects.indexOf item) > -1
							objects.splice i, 1
				@
			tick: (dt = 1) ->
				objects.select('tick').call dt
				ctx.clearRect 0,0,opts.w,opts.h
				for obj in objects
					obj.preDraw ctx, @
					obj.draw ctx, @
					obj.postDraw ctx, @
				$.now
			start: ->
				t = $.now
				ticker = =>
					dt = $.now - t
					t = $.now
					@tick dt
					interval = requestInterval ticker
				interval = requestInterval ticker
			stop: ->
				cancelInterval interval

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
	
	window.game = new Game canvas: "#gameCanvas", w: 600, h: 400

	game.add new Tracer().position(10,10).layerUp()
	colors = ["red", "green", "blue", "yellow", "purple", "pink"]
	for i in [0...50] by 1
		game.add new Ball()
			.radius($.random.integer(5,20))
			.fill($.random.element(colors))
			.stroke($.random.element(colors))
			.position($.random.integer(20,600), $.random.integer(20,400))
			.velocity($.random.real(-.007,.007), $.random.real(-.007,.007))
	
	game.tick(16.66)

	$(".start-game").click -> game.start()
	$(".stop-game").click -> game.stop()
	$(".tick-game").click -> game.tick(16.66)
