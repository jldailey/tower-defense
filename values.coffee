
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
		sum = 0
		$.defineProperty @, 'value',
			get: ->
				sum/data.length
			set: (v) ->
				if not isFinite(v) then return
				if data.length >= smoothOver
					sum -= data.shift()
				sum += data.push(v).last()
