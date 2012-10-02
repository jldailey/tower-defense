class Label extends GameObject
	constructor: -> super @
	text: chain (text) ->
		@label = text
	draw: (ctx) ->
		ctx.fillText @label, @pos...
