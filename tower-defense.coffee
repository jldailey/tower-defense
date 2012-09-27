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

deg2rad = (deg) -> deg*Math.PI/180
expose  = (f) -> window[f.name] = f
chain   = (f) -> -> f.apply @, arguments; @

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

expose class GameObject extends $.EventEmitter
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
		ctx.translate @x, @y if @x?
		ctx.rotate deg2rad @rot if @rot?
	draw: (ctx) -> # (optional) draw yourself
	postDraw: (ctx) -> ctx.restore()

	rotation: chain (deg) -> @rot = deg
	position: (x, y) -> @proxy @pos = $(x,y), 'x', 'y'
	size: (w, h) -> @proxy @size = $(w, h), 'w', 'h'

	proxy: chain (array, names...) ->
		for i in [0...names.length] by 1 then do (i) ->
			name = names[i]
			$.defineProperty @, name,
				get: -> arr[i]
				set: (v) -> arr[i] = v

expose class Game
	constructor: (opts, objects...) ->
		opts = $.extend {
			canvas: "#canvas"
			fps: 30
		}, opts
		requestInterval = window.requestAnimationFrame or
			window.mozRequestAnimationFrame or
			window.webkitRequestAnimationFrame or
			window.msRequestAnimationFrame or
			(f) -> window.setTimeout f, 1000/opts.fps
		cancelInterval = window.cancelAnimationFrame or
			window.mozCancelAnimationFrame or
			window.webkitCancelAnimationFrame or
			window.msRequestAnimationFrame or
			window.clearInterval
		ctx = $(opts.canvas).select('getContext').call('2d').first()
		interval = null
		objects = $()
		$.extend @,
			add: chain (item) ->
				objects.push item
				item.on 'destroy', (x) ->
					if (i = objects.indexOf x) > -1
						objects.splice i, 1
			start: ->
				t = $.now
				f = ->
					t += (dt = t - $.now)
					objects.select('tick').call dt
					objects.select('preDraw').call ctx
					objects.select('draw').call ctx
					objects.select('postDraw').call ctx
					interval = requestInterval f
				interval = requestInterval f
			stop: ->
				cancelInterval interval

expose class Tracer extends GameObject
	tick: (dt) ->
		$.log "Tick (dt:#{dt} fps:#{1000/dt})"

expose class Label extends GameObject
	text: chain (text) ->
		@txt = text
	draw: (ctx) ->
		ctx.fillText @txt, @x, @y
