try require('bling')

class Module extends $.EventEmitter
	@mixin = (cls) ->
		for k,v of cls::
			proto = @::
			proto[k] = switch $.type v
				when "function" then do (v,f=proto[k]) ->
					-> f.apply @, arguments; v.apply @, arguments
				else v
	constructor: $.trace("Module-constructor", -> @init() )
	init: $.trace("Module-init", -> )

	proxy: (array, names...) ->
		for i in [0...names.length] by 1 then do (i) =>
			name = names[i]
			$.defineProperty @, name,
				get: -> array[i]
				set: (v) -> array[i] = v
		@

if require?.main is module
	require('bling')
	class Foo
		init: ->
			$.log "Foo-init"
		A: ->
			$.log "Foo-A"
	class Bar extends Module
		constructor: -> super @
		A: ->
			$.log "Bar-A"
		@mixin Foo
	class Baz extends Module
		constructor: -> super @
		A: ->
			$.log "Baz-A"
		@mixin Bar
	
	b = new Baz()
	b.A()
	
