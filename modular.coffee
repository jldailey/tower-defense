try require('bling')

$.mixin = (a, b) ->
	for field,func of b
		continue if field in $.mixin.reservedWords
		continue unless $.is 'function', func
		a[field] = MethodChain a[field], func
	a
$.mixin.reservedWords = [ 'constructor' ]
Function::mixin = (obj) -> $.mixin @::, obj; @
$::mixin = (obj) ->
	if obj? then @each -> $.mixin @, obj
	else if @length > 1
		$.mixin @first(), @slice(1).mixin()
	else @first()

MethodChain = (f, g) ->
	unless $.is 'function', f
		_f = f
		f = -> _f
	unless $.is 'function', g
		_g = g
		g = -> _g
	if f.isChain
		return f.append(g)
	if g.isChain
		return g.prepend(f)

	funcs = $()
	adder = (method) -> (func) ->
		(funcs[method].call funcs, func) if ($.is 'function', func) and funcs.indexOf(func) is -1
		@

	$.extend (-> funcs.apply(@, arguments).coalesce()),
		isChain: true
		append: adder('push')
		prepend: adder('unshift')
	.append(f)
	.append(g)

class Modular extends $.EventEmitter
	constructor: ->
		super @
		@init()
	init: ->
