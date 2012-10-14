try require('bling')

$.mixin = (a, b) ->
	for field,func of b
		continue if field in $.mixin.reservedWords
		continue unless $.is 'function', func
		a[field] = MethodChain a[field], func
	a
$.mixin.reservedWords = [ 'constructor' ]
Function::mixin = (obj) -> $.mixin @::, obj; @
$::mixin = (obj) ->
	if obj? then @each -> $.mixin @, obj
	else if @length > 1
		$.mixin @first(), @slice(1).mixin()
	else @first()

MethodChain = (f, g) ->
	unless $.is 'function', f
		_f = f
		f = -> _f
	unless $.is 'function', g
		_g = g
		g = -> _g
	if f.isChain
		return f.append(g)
	if g.isChain
		return g.prepend(f)

	funcs = $()
	adder = (method) -> (func) ->
		(funcs[method].call funcs, func) if ($.is 'function', func) and funcs.indexOf(func) is -1
		@

	$.extend (-> funcs.apply(@, arguments).coalesce()),
		isChain: true
		append: adder('push')
		prepend: adder('unshift')
	.append(f)
	.append(g)


if require?.main is module
	assert = require 'assert'

	Area =
		init: -> @w = @h = 0
		area: (@w, @h) -> @

	Position =
		init: -> @x = @y = 0
		position: (@x,@y) -> @
		preDraw: (ctx) ->
			ctx.translate @x, @y
	
	Velocity =
		init: -> @vx = @vy = 0
		velocity: (@vx, @vy) -> @
		tick: (dt) ->
			@x += @vx * dt
			@y += @vy * dt
	
	Acceleration =
		init: -> @ax = @ay = 0
		accel: (@ax, @ay) -> @
		tick: (dt) ->
			@vx += @ax * dt
			@vy += @ay * dt
	
	Color =
		init: ->
		fill: (@fillStyle) -> @
		stroke: (@strokeStyle) -> @
		preDraw: (ctx) ->
			ctx.fillStyle = @fillStyle
			ctx.strokeStyle = @strokeStyle
	
	class Entity extends $.EventEmitter
		constructor: ->
			super @
			@init()
		tick: (dt) ->
		preDraw: (ctx) -> ctx.save()
		draw: (ctx) ->
		postDraw:(ctx)  -> ctx.restore()
		@mixin Area
		@mixin Position
		@mixin Acceleration
		@mixin Velocity
		@mixin Color
	
	class Box extends Entity
		draw: (ctx) -> ctx.fillRect 0,0,@w,@h

	Path =
		preDraw: (ctx) -> ctx.beginPath()
		postDraw: (ctx) -> ctx.closePath()
	
	class Circle extends Entity
		constructor: -> @init()
		draw: (ctx) -> ctx.arc 0,0,0,0,2*Math.PI
		@mixin Path

	# set up a fake context for testing
	output = []
	dummy = (name) -> (args...) -> output.push [name, args...]
	ctx =
		translate: dummy 'translate'
		save: dummy 'save'
		restore: dummy 'restore'
		fillRect: dummy 'fillRect'
		arc: dummy 'arc'
		beginPath: dummy 'beginPath'
		closePath: dummy 'closePath'
	
	o = new Circle()
	assert.equal o.x, 0
	assert.equal o.y, 0
	assert.equal o.vx, 0
	assert.equal o.vy, 0
	assert.equal o.ax, 0
	assert.equal o.ay, 0
	o.area(20,30)
	assert.equal o.w, 20
	assert.equal o.h, 30
	o.tick(16.66)
	o.preDraw(ctx)
	o.draw(ctx)
	o.postDraw(ctx)
	$.log output

