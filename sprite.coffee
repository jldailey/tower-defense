
class window.Sprite extends Modular
	image: (url, onload=->) ->
		@img = new Image()
		@img.src = url
		@img.onload = onload
		@
	draw: (ctx) ->
		ctx.drawImage @img, 0, 0, @w, @h
	@mixin Drawable

class window.TileLayer extends Sprite
	init: -> @tileSize 100
	tileSize: (@tileWidth, @tileHeight=@tileWidth) -> @
	drawTile: (ctx, x, y) ->
		x *= @tileWidth
		y *= @tileHeight
		ctx.drawImage @img,x,y,@tileWidth,@tileHeight
	draw: (ctx, game) ->
		{width, height} = game.canvas
		for x in [0...width / @tileWidth] by 1
			for y in [0...height / @tileHeight] by 1
				@drawTile ctx, x, y
	@mixin Drawable

window.Textures = [
	"ground-snow1-0.jpg",
	"ground-snow1-0_footprints.jpg",
]
