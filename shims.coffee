
chain = (f) -> -> f.apply @, arguments; @

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
