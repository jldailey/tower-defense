
proxy = (t, array, names...) ->
	for i in [0...names.length] by 1 then do (i) =>
		name = names[i]
		$.defineProperty t, name,
			get: -> array[i]
			set: (v) -> array[i] = v
	t

requestInterval = window.requestAnimationFrame or
	window.mozRequestAnimationFrame or
	window.webkitRequestAnimationFrame or
	window.msRequestAnimationFrame or
	(f) -> window.setTimeout f, 1000/60

cancelInterval = window.cancelAnimationFrame or
	window.mozCancelAnimationFrame or
	window.webkitCancelAnimationFrame or
	window.msCancelAnimationFrame or
	window.clearTimeout
