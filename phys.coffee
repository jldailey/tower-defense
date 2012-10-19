
#define VEC_ADD(v,a) [v[0]+a,v[1]+a,v[2]+a]
#define VEC_ADD_INPLACE(v,a) (v[0]+=a;v[1]+=a;v[2]+=a)
#define VEC_ADDV(v,w) [v[0]+w[0],v[1]+w[1],v[2]+w[2]]
#define VEC_ADDV_INPLACE(v,w) (v[0]+=w[0];v[1]+=w[1];v[2]+=w[2])
#define VEC_SCALE(v,r) [v[0]*r, v[1]*r, v[2]*r]
#define VEC_SCALE_INPLACE(v, r) (v[0]*=r;v[1]*=r;v[2]*=r)
#define VEC_SUBV(v,w) [v[0]-w[0],v[1]-w[1],v[2]-w[2]]
#define VEC_MAG(v) Math.sqrt((v[0]*v[0]) + (v[1]*v[1]) + (v[2]*v[2]))
#define VEC_REPLACE(v,w) (v[0]=w[0];v[1]=w[1];v[2]=w[2])
#define VEC_XROT(v) $.rad2deg(Math.acos(v[0] / VEC_MAG(v)))
#define VEC_YROT(v) $.rad2deg(Math.acos(v[1] / VEC_MAG(v)))
#define VEC_ZROT(v) $.rad2deg(Math.acos(v[2] / VEC_MAG(v)))

class Size
	init: ->
		proxy @, @pos = $(0,0,0), 'x', 'y', 'z'
		proxy @, @vol = $(0,0,0), 'w', 'h', 'd'
	size: (@w,@h=@w,@d=0) -> @
	position: (@x,@y,@z=0) -> @
	preDraw: (ctx) ->
		if @x isnt 0 or @y isnt 0
			ctx.translate @x, @y
class Velocity
	init: ->
		$.log "Velocity::init()"
		proxy @, @vel = $(0,0,0), 'vx', 'vy', 'vz'
	velocity: (@vx,@vy,@vz=0) -> @
	tick: (dt) ->
		if not @vel
			$.log "Object has a velocity tick, but wasn't inited with @vel"
			$.log @tick.funcs()
			$.log @init
		v = VEC_SCALE(@vel, dt)
		VEC_ADDV_INPLACE(@pos, v)
		$.log "pos: #{@pos} x: #{@x} y: #{@y}"
class Acceleration
	init: -> proxy @, @acc = $(0,0,0), 'ax', 'ay', 'az'
	accel: (@ax,@ay,@az=0) -> @
	tick: (dt) ->
		a = VEC_SCALE(@acc, dt)
		VEC_ADDV_INPLACE(@vel, a)
class Speed
	init: ->
		if not @speed
			$.log "Speed:init() called, but the object has no @speed()"
			$.log @init.funcs()
			$.log $.keysOf(@)
		@speed 0
	speed: (@spd) -> @
	tick: (dt) ->
		m = VEC_MAG(@vel)
		if m isnt 0
			m = @spd / m
			VEC_SCALE_INPLACE(@vel, m)
class Color
	init: -> @fillStyle = @strokeStyle = null
	fill: (@fillStyle) -> @
	stroke: (@strokeStyle) -> @
	preDraw: (ctx) ->
		ctx.fillStyle = @fillStyle
		ctx.strokeStyle = @strokeStyle
	draw: (ctx) ->
		ctx.fill() if @fillStyle
		ctx.stroke() if @strokeStyle
class Scale
	preDraw: (ctx) -> ctx.scale @scaler... if @scaler
	scale: (@scaler...) -> @
class Rotation
	init: -> @rot = 0
	rotation: (deg) ->
		@rot = $.deg2rad deg
		@
	preDraw: (ctx) -> ctx.rotate @rot if @rot
class Quality
	init: ->
		@quality = 1.0
		@decayPerMs = 0
	decay: (@decayPerMs) -> @
	tick: (dt) -> @quality = Math.max(0, @quality - @decayPerMs * dt )

