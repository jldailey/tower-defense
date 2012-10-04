
Function::has = Function::is = (cls) ->
		proto = @::
	for k,v of cls::
		proto[k] = switch $.type v
			when "function" then do (v,f=proto[k]) ->
				-> $(f,v).apply(@, arguments).coalesce()
			else v

class Modular extends $.EventEmitter
	constructor: -> @init()
	init: ->
