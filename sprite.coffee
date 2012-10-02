
class Sprite extends GameObject
	image: chain (url, onload=->) ->
		@img = new Image()
		@img.src = url
		@img.onload = onload
	draw: (ctx) ->
		ctx.drawImage @img, 0, 0, @w, @h
