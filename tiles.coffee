
class TileLayer extends Sprite
	constructor: ->
		@tileWidth = 100
		@tileHeight = 100
	setTileSize: (@tileWidth=100, @tileHeight=@tileWidth) ->
	drawTile: (ctx, x, y) ->
		x *= @tileWidth
		y *= @tileHeight
		ctx.drawImage @img,x,y,@tileWidth,@tileHeight
	draw: (ctx, game) ->
		{width, height} = game.canvas.first()
		for x in [0...width / @tileWidth] by 1
			for y in [0...height / @tileHeight] by 1
				@drawTile ctx, x, y
