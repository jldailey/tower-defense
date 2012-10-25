# Tower Defense.

# One thing that is currently fragile that I don't like is that you have to
# extend from Modular if you want to be directly constructable, otherwise the
# init: chain is never bootstrapped.

#include "shims.coffee"
#include "values.coffee"
#include "modular.coffee"

class Destroyable
	init: -> @destroyed = false
	destroy: -> @emit 'destroy', @destroyed = true

class Indexed
	_index = {}
	_types = {}
	init: ->
		_index[@guid or= $.random.string 16] = @
		c = @
		while c.constructor
			_types[c.constructor.name] = @
			c = c.__proto__
		@on 'destroy', =>
			delete _index[@guid]
	@find = (id, where = -> true) ->
		$(_index[id] or _types[id.name ? id]).filter where

class Managed extends Modular
	@mixin Indexed
	@mixin Destroyable

class Ball extends Modular
	enter: (paper) ->
		@circle = paper.circle(50,50,30).attr("fill", "#33E")
	exit: (paper) ->
		@circle.remove()
	tick: (dt) ->
	@mixin Managed

class Game
	constructor: (opts) ->
		$.extend @, $.extend {
			w: 640
			h: 480
		}, opts
		@paper or= Raphael 0,0,@w,@h
		@interval = null
		# Read-only: @objects
		objects = $()
		$.defineProperty @, 'objects',
			get: -> objects
	add: (items...) ->
		for item in items then do (item) ->
			item = $.extend {
				enter: (paper, game) ->
				exit: (paper, game) ->
				tick: (dt, game) ->
			}, item
			# if the item asks to be destroyed, remove it
			item.on 'destroy', (destroyed) =>
				if destroyed and (i = @objects.indexOf item) > -1 # might/could trust _index and skip the search
					@objects.splice i, 1
					@objects.emit 'change'
		@
	tick: (dt = 16.66) ->
		for obj in @objects
			continue unless obj # during a tick, an item might be destroyed
			obj.tick dt, @
		$.now
	start: ->
		return if @interval
		t = $.now
		ticker = =>
			t = @tick($.now - t)
			interval = requestInterval ticker
		interval = requestInterval ticker
	stop: ->
		return unless @interval
		cancelInterval interval
		interval = null
	toggle: ->
		if @interval then @stop() else @start()

$(document).ready ->
	window.game = new Game w: window.innerWidth, h: window.innerHeight

	game.tick(16.66)
