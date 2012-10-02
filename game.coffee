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

class GameObject extends $.EventEmitter
	constructor: ->
		super @
		GameObject.index[@guid or= $.random.string 16] = @
		@valid = true
	@index = {}
	destroy: ->
		@valid = false
		@emit 'destroy', @ # signal the game to forget about us

	tick: (dt) -> # should update your state based on a dt amount of time having passed
	preDraw: (ctx) ->
		ctx.save()
		ctx.fillStyle = @style if @style?
		ctx.strokeStyle = @style if @style?
		ctx.translate @x, @y if @x?
		ctx.rotate $.deg2rad @rot if @rot?
	draw: (ctx) -> # (optional) draw yourself
	postDraw: (ctx) ->
		ctx.restore()

	color: chain (style) -> @style = style
	rotation: chain (deg) -> @rot = deg
	position: (x, y) -> @proxy @pos = $(x,y), 'x', 'y'
	size: (w, h) -> @proxy @size = $(w, h), "w", "h"

	proxy: chain (array, names...) ->
		for i in [0...names.length] by 1 then do (i) =>
			name = names[i]
			$.defineProperty @, name,
				get: -> array[i]
				set: (v) -> array[i] = v

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
				objects.push item
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

#include "sprite.coffee"
#include "tiles.coffee"
#include "towers.coffee"
#include "shapes.coffee"
#include "bullets.coffee"
#include "player.coffee"
#include "label.coffee"

class Tracer extends Label
	constructor: ->
		super @
		fps = new SmoothValue 100
		$.extend @,
			tick: (dt) ->
				fps.value = 1000/dt
				@label = "fps:#{(fps.value).toFixed 0}"

$(document).ready ->
	window.Tracer = Tracer
	window.game = new Game canvas: "#gameCanvas", w: 320, h: 240
	game.add new Tracer().position(10,20).color("red")
	game.add new Sprite().image("img/grass.jpg").position(50,50).size(100,100).rotation(45)
	$(".start-game").click -> game.start()
	$(".stop-game").click -> game.stop()
	$(".tick-game").click -> game.tick(10)
