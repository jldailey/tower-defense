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

#include "shims.coffee"
#include "values.coffee"
#include "modular.coffee"

class Volume
	init: ->
		proxy @, @size = $(0,0,0), 'w', 'h', 'd'
		proxy @, @size, 'width', 'height', 'depth'

class Position
	init: -> proxy @, @pos = $(0,0,0), 'x', 'y', 'z'
	position: (@x,@y,@z=0) -> @
	preDraw: (ctx) -> ctx.translate @x, @y

class Velocity
	init: -> proxy @, @vel = $(0,0,0), 'vx', 'vy', 'vz'
	velocity: (@vx,@vy,@vz=0) -> @
	tick: (dt) -> @pos.add @vel.scale dt

class Rotation
	init: -> @rot = 0
	rotation: (deg) ->
		@rot = $.deg2rad deg
		@
	preDraw: (ctx) -> ctx.rotate @rot

class Filling
	init: -> @fillStyle = "black"
	fill: (@fillStyle) -> @
	preDraw: (ctx) -> ctx.fillStyle = @fillStyle
	draw: (ctx) -> ctx.fill()

class Stroking
	init: -> @strokeStyle = "black"
	stroke: (@strokeStyle) -> @
	preDraw: (ctx) -> ctx.strokeStyle = @strokeStyle
	draw: (ctx) -> ctx.stroke()

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
			add: chain (item) ->
				objects.splice (index = $.sortedIndex objects, item, 'layer'), 0, item
				item.on 'layerChange', (oldLayer, newLayer) ->
					objects.splice index, 1
					objects.splice (index = $.sortedIndex objects, item, 'layer'), 0, item
				item.on 'destroy', (x) ->
					if (i = objects.indexOf x) > -1
						objects.splice i, 1
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
				f = =>
					t = @tick $.now - t
					interval = requestInterval f
				interval = requestInterval f
			stop: ->
				cancelInterval interval

$(document).ready ->
	class FPSTracer extends Label
		init: -> @label = "FPS: 0"
		tick: (dt) ->
		@has Position
	window.game = new Game canvas: "#gameCanvas", w: 320, h: 240
	game.add new Tracer().position(10,20).color("red")
	$(".start-game").click -> game.start()
	$(".stop-game").click -> game.stop()
	$(".tick-game").click -> game.tick(10)
