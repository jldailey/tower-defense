try require 'bling'

$.mixin = (a, b) ->
	for field,func of b
		continue if field in $.mixin.reservedWords
		continue unless $.is 'function', func
		a[field] = MethodChain a[field], func
	a
$.mixin.reservedWords = [ 'constructor', '__super__' ]
Function::mixin = (obj) ->
	$.mixin @::, obj::
	@

emptyArray = []
class MethodChainOp
	constructor: (@op, @value) ->
MethodChain = (funcs...) ->
	funcs = $(funcs).filter(-> $.is 'function', @)
	for i in [0...funcs.length] by 1
		if funcs[i].chain
			a = funcs[i].chain.length - 1
			funcs.splice i, 1, funcs[i].chain...
			i += a
	$.extend ( (args...) ->
		x = null
		for func in funcs
			x = func.apply(@, args) or x
			if x?.constructor is MethodChainOp
				switch x.op
					when "arguments" then args = x.value
					when "abort" then return null
		x
	),
		chain: funcs

class Modular extends $.EventEmitter
	constructor: ->
		super @
		@init()
	init: -> @
	clone: ->
		@init.apply { __proto__: @__proto__ }

if module?
	$.extend module.exports, {MethodChain, Modular, MethodChainOp}
