
class Shape extends GameObject

class Circle extends Shape
	radius: chain (deg) ->
		@rad = deg
	draw: (ctx) ->
		ctx.beginPath()
		ctx.arc 0,0,@rad,0,2*Math.PI
		ctx.fill()
		ctx.stroke()
		ctx.closePath()
