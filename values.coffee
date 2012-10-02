
class TimeValue # a value that changes at a constant rate
	constructor: (func) ->
		baseValue = baseTime = 0
		$.defineProperty @, 'value',
			get: -> func baseValue, $.now - baseTime
			set: (v) ->
				baseTime = $.now
				baseValue = v
		@value = 0
		@valueAt = (t) -> func baseValue, $.date.stamp(t) - baseTime
class LinearValue extends TimeValue
	constructor: (@rate) ->
		super (x, dt) => x + (dt*@rate)

class SmoothValue
	constructor: (smoothOver=10) ->
		data = $()
		$.defineProperty @, 'value',
			get: -> data.mean()
			set: (v) ->
				if data.length >= smoothOver
					data.shift()
				data.push v
