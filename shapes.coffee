class Shape extends GameObject
	fillStyle: chain (style) ->
		@fillStyle = style
	strokeStyle: chain (style) ->
		@strokeStyle = style
	preDraw: (ctx) ->
		if @fillStyle?
			ctx.fillStyle @fillStyle
		if @strokeStyle?
			ctx.strokeStyle @strokeStyle

expose class Circle extends Shape
	radius: chain (deg) ->
		@rad = deg
	draw: (ctx) ->
		ctx.beginPath()
		ctx.arc 0,0,@rad,0,2*Math.PI
		ctx.fill()
		ctx.stroke()
		ctx.closePath()

