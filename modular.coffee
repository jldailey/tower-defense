try require 'bling'

$.mixin = (a, b) ->
	for field,func of b
		continue if field in $.mixin.reservedWords
		continue unless $.is 'function', func
		a[field] = Aspects a[field], func
	a
$.mixin.reservedWords = [ 'constructor', '__super__' ]
Function::mixin = (obj) ->
	$.mixin @::, obj::
	@

emptyArray = []
Aspects = (funcs...) ->
	funcs = $(funcs).filter(-> $.is 'function', @)
	# create the wrapper function that invokes the whole chain
	ret = $.extend ( (args...) ->
		x = null
		for func in funcs
			x = func.apply(@, args) or x
			if x?.constructor is Aspects.Op
				switch x.op
					when "arguments" then args = x.value
					when "abort" then return null
		x
	),
		chain: funcs
	# unroll all the funcs (and any nested chains) into just the one flat funcs
	for i in [0...funcs.length] by 1
		if funcs[i].chain
			a = funcs[i].chain.length - 1
			funcs.splice i, 1, funcs[i].chain...
			i += a
	# lift the prototypes of the funcs up and attach them to the wrapper prototype
	ret.name = "Aspects<#{funcs.select('name').or('_').join(',')}>"
	for func in funcs
		p = ret::
		for k,v of (func::) when $.is 'function', v
			# chain functions that collide
			if k of p
				p[k] = Aspects p[k], v
			else
				p[k] = v
	ret
class Aspects.Op # can be returned by functions in the chain
	constructor: (@op, @value) ->

if module?
	$.extend module.exports, {Aspects}
