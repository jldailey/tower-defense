
class Player extends GameObject
	constructor: (@name) ->
		super @
		@money = new LinearValue 0
		@money.value = Rules.startingGold
		@towers = []
		@inHand = null
	toString: -> "#{@name} (#{@money.value}gp)"
	tick: (dt) ->
		tower.tick(ctx) for tower in towers
	draw: (ctx) ->
	adjustIncome: (amt) ->
		@money.value = @money.value # reset the base time so the rate change is not retroactive
		@money.rate += amt / 1000
	adjustBalance: (amt) ->
		@money.value -= amt
	purchaseTower: (towerCode) ->
		if towerCode of Towers
			tower = Towers[towerCode]
			if @money.value > tower.cost
				@inHand = tower
		null
	placeInHand: (map, pos...) ->
		if @inHand
			map.placeItem @inHand, pos...
		null
	cancelPurchase: ->
		if @inHand
			@adjustBalance +@inHand.cost
		@inHand = null
