
Function::has = Function::is = (cls) ->
	@mixins or= []
	if (i = @mixins.indexOf cls) > -1
		@mixins.splice i, 1
	@mixins.push cls
	proto = @::
	for k,v of cls::
		continue if k in [ 'constructor' ]
		if $.is 'function', v then do (k,v) =>
			orig = proto[k]
			proto[k] = ->
				if orig?
					a = orig.apply @, arguments
				b = v.apply @, arguments
				return a or b
	null

$::mixin = (field, func) ->
	@each ->
		old = @[field]
		@[field] = ->
			if old?
				a = old.apply @, arguments
			b = func.apply @, arguments
			return a or b

class Modular extends $.EventEmitter
	constructor: ->
		super @
		@init()
	init: ->
