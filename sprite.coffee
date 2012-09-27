expose class Sprite extends GameObject
	image: chain (url, onload=->) ->
		@img = new Image url
		@img.on 'load', onload
	draw: (ctx) ->
		ctx.drawImage @img, 0, 0, @w, @h
