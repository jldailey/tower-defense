
class Path
	preDraw: (ctx) -> ctx.beginPath()
	postDraw: (ctx) -> ctx.closePath()

class Shape
	tick: (dt) ->
	preDraw: (ctx) -> ctx.save()
	postDraw: (ctx) -> ctx.restore()
	@has Size
	@has Color
	@has Highlight
	@is Destroyable
	@is Indexed

class window.Circle extends Modular
	init: -> @rad = 10
	radius: (@rad) -> @
	draw: (ctx) -> ctx.arc 0,0,@rad,0,2*Math.PI
	@is Shape
	@has Path

class window.Square extends Modular
	draw: (ctx) -> ctx.fillRect 0,0,@w,@h
	@is Shape
	@has Rotation

class window.Triangle extends Modular
	draw: (ctx) ->
		ctx.moveTo 0,0
		ctx.lineTo @w/2,@h
		ctx.lineTo -@w/2,@h
		ctx.lineTo 0,0
	@is Shape
	@has Path
	@has Rotation
