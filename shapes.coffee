
class Path
	preDraw: (ctx) -> ctx.beginPath()
	postDraw: (ctx) -> ctx.closePath()

class Shape
	tick: (dt) ->
	preDraw: (ctx) -> ctx.save()
	postDraw: (ctx) -> ctx.restore()
	@mixin Size
	@mixin Color
	@mixin Layer
	@mixin Highlight
	@mixin Destroyable
	@mixin Indexed

class window.Circle extends Modular
	init: -> @rad = 10
	radius: (@rad) -> @
	draw: (ctx) -> ctx.arc 0,0,@rad,0,2*Math.PI
	@mixin Shape
	@mixin Path

class window.Square extends Modular
	draw: (ctx) -> ctx.fillRect 0,0,@w,@h
	@mixin Shape
	@mixin Rotation

class window.Triangle extends Modular
	draw: (ctx) ->
		ctx.moveTo 0,0
		ctx.lineTo @w/2,@h
		ctx.lineTo -@w/2,@h
		ctx.lineTo 0,0
	@mixin Shape
	@mixin Path
	@mixin Rotation
