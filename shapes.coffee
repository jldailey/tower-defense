
class Shape extends Modular
	@mixin Size
	@mixin Scale
	@mixin Color
	@mixin Indexed
	@mixin Rotation
	@mixin Highlight
	@mixin Destroyable

class window.Circle extends Modular
	init: -> @rad = 10
	radius: (@rad) -> @
	draw: (ctx) ->
		ctx.circlePath 0,0,@rad
	@mixin Shape

class window.Triangle extends Modular
	draw: (ctx) ->
		ctx.beginPath()
		ctx.moveTo 0,0
		ctx.lineTo @w/2,@h
		ctx.lineTo -@w/2,@h
		ctx.lineTo 0,0
		ctx.closePath()
	@mixin Shape
