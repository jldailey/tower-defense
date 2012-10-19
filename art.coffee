#define LIGHT_COLOR(alpha) "rgba(245,245,210,"+(alpha)+")"

class window.Road extends Modular
	draw: (ctx) ->
		mid = (@h/2)
		shoulderWidth = @h/16
		bottomShoulder = @h-shoulderWidth
		lineWidth = @h/20
		stopLineOffset = 11
		stopLineWidth = 4
		crosswalkOffsetA = 3
		crosswalkOffsetB = 7
		white = "rgba(255,255,255,#{@quality})"
		ctx.translate 0,-mid
		ctx.fillStyle = "#333"
		ctx.fillRect 0,0,@w,@h
		ctx.beginPath()
		ctx.strokeStyle = white
		ctx.lineWidth = lineWidth
		# the two white shoulder lines
		ctx.moveTo shoulderWidth*crosswalkOffsetB, shoulderWidth
		ctx.lineTo @w-shoulderWidth*crosswalkOffsetB, shoulderWidth
		ctx.moveTo shoulderWidth*crosswalkOffsetB, bottomShoulder
		ctx.lineTo @w-shoulderWidth*crosswalkOffsetB, bottomShoulder
		# the two white crosswalk lines
		ctx.moveTo (shoulderWidth*crosswalkOffsetA), 0
		ctx.lineTo (shoulderWidth*crosswalkOffsetA), @h
		ctx.moveTo (shoulderWidth*crosswalkOffsetB), shoulderWidth
		ctx.lineTo (shoulderWidth*crosswalkOffsetB), bottomShoulder

		# the second set of crosswalk lines
		ctx.moveTo (@w-shoulderWidth*crosswalkOffsetB), shoulderWidth
		ctx.lineTo (@w-shoulderWidth*crosswalkOffsetB), bottomShoulder
		ctx.moveTo (@w-shoulderWidth*crosswalkOffsetA),0
		ctx.lineTo (@w-shoulderWidth*crosswalkOffsetA),@h
		ctx.stroke()
		ctx.closePath()

		# the first stop line
		ctx.beginPath()
		ctx.lineWidth = lineWidth*stopLineWidth
		ctx.moveTo shoulderWidth*stopLineOffset,shoulderWidth
		ctx.lineTo shoulderWidth*stopLineOffset,mid*1.02
		# the second stop line
		ctx.moveTo @w-shoulderWidth*stopLineOffset,mid*0.98
		ctx.lineTo @w-shoulderWidth*stopLineOffset,bottomShoulder
		ctx.stroke()
		ctx.closePath()

		# the yellow dashed line down the middle
		ctx.beginPath()
		ctx.setLineDash [5,5]
		ctx.lineWidth = lineWidth
		ctx.strokeStyle = "rgba(255,255,0,#{@quality})"
		ctx.moveTo shoulderWidth*stopLineOffset,mid
		ctx.lineTo @w - shoulderWidth*stopLineOffset,mid
		ctx.stroke()
		ctx.closePath()
	@mixin Drawable
	@mixin Quality

class window.LightCone extends Modular
	tick: (dt) ->
		@stroke null
		@fill null
	draw: (ctx) ->
		gradient = ctx.createRadialGradient( @w/2,0, 1, @w/2,0, @w/2 )
		gradient.addColorStop 0, LIGHT_COLOR(@quality*.9)
		gradient.addColorStop 1, LIGHT_COLOR(0)
		ctx.fillStyle = gradient
		ctx.fillRect 0,0,@w,@h
	@mixin Drawable
	@mixin Quality

class window.StreetLight extends Modular
	tick: (dt) ->
		@quality = $.random.coin(.995)
		@strokeStyle = null
		@fillStyle = null
	draw: (ctx) ->
		# draw pole
		x1=@w*.42 # base of the pole on the ground
		x2=@w*.50 # location of the head of the pole (where bulb attaches)
		y1=-@h/12 # the depth of the corner (away from the bulb)
		y2=@h*.02 # the bulb offset
		ctx.beginPath()
		ctx.moveTo x1,0
		ctx.lineTo x2,y1
		ctx.lineTo x2,4
		ctx.lineWidth = 2
		ctx.strokeStyle = "rgba(0,0,0,.8)"
		ctx.stroke()
		ctx.closePath()

		ctx.beginPath()
		ctx.moveTo x1+1,0
		ctx.lineTo x2-2,y1+2
		ctx.lineTo x2-2,4
		ctx.strokeStyle = LIGHT_COLOR(@quality*.6)
		ctx.stroke()
		ctx.closePath()

		# draw bulb
		ctx.beginPath()
		ctx.strokeStyle = LIGHT_COLOR(@quality)
		ctx.lineWidth = 4
		ctx.arc x2,0,y2,0,Math.PI
		ctx.closePath()
		ctx.stroke()
	@mixin LightCone

class window.Sidewalk extends Modular
	draw: (ctx) ->
		ctx.fillStyle = "lightgrey"
		ctx.fillRect 0,0,@w,@h
		ctx.beginPath()
		ctx.lineWidth = 1
		ctx.strokeStyle = "darkgrey"
		for i in [@h...@w] by @h*1.3
			ctx.moveTo i,0
			ctx.lineTo i,@h
		ctx.stroke()
		ctx.closePath()
	@mixin Drawable

class window.PineTree extends Modular
	draw: (ctx) ->
		unless @gradient
			@gradient = g = ctx.createRadialGradient()
			g.addColorStop 0, "rgb(10,50,10)"
			g.addColorStop 1, "forestgreen"
		# draw trunk
		ctx.translate @w/2,@h/2
		ctx.beginPath()
		ctx.moveTo -2, 0
		ctx.lineTo 2, -@h/2
		ctx.lineTo 3, 0
		ctx.lineTo -2, 0
		ctx.fillStyle = "rgb(100,10,10)"
		ctx.fill()
		ctx.closePath()

	@mixin Managed

class window.Grass extends Modular
	drawUncached: (ctx) ->
		@ttl -1
		ctx.fillStyle = "rgb(150,255,150)"
		ctx.fillRect 0,0,@w,@h
		ctx.beginPath()
		ctx.lineWidth = 1
		scatter = [2, 5]
		for x in [0...@w] by $.random.integer 8,13
			for y in [0...@h] by $.random.integer 8,13
				x = $.random.integer 0,@w
				y = $.random.integer 0,@h

				ctx.beginPath()
				ctx.strokeStyle = "rgb(100,10,10)"
				ctx.moveTo x,y
				ctx.lineTo x,y-4
				ctx.stroke()
				ctx.closePath()

				ctx.beginPath()
				ctx.strokeStyle = "rgb(10,100,10)"
				ctx.moveTo x, y-19
				ctx.lineTo x-3, y
				ctx.moveTo x, y-19
				ctx.lineTo x+3, y
				ctx.stroke()

		ctx.closePath()
		
	@mixin Managed
	@mixin Quality
	@mixin Cached
	@mixin Elapsed

class Intersection extends Modular
	draw: (ctx) ->
		ctx.translate -@w,-@h/2
		ctx.fillStyle = "#333"
		ctx.fillRect 0,0,@w,@h
	@mixin Drawable
	@mixin Quality

