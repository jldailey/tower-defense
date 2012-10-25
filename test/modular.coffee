assert = require 'assert'
require 'bling'
$.extend global, require '../modular'

Array::clear or= -> @splice 0, @length

describe "Aspects", ->
	it "chains two methods into one", ->
		output = []
		f = -> output.push "f"
		g = -> output.push "g"
		m = Aspects(f, g)
		m()
		assert.deepEqual output, ["f", "g"]
	it "chains any number of methods at once", ->
		output = []
		f = -> output.push "f"
		g = -> output.push "g"
		h = -> output.push "h"
		m = Aspects(f, g, h)
		m()
		assert.deepEqual output, ["f", "g", 'h']
	it "flattens/unrolls nested chains", ->
		output = []
		f = -> output.push "f"
		g = -> output.push "g"
		h = -> output.push "h"
		i = -> output.push "i"
		m = Aspects(f, Aspects(g, Aspects(h, i)))
		m()
		assert.deepEqual output, ["f", "g", "h", "i"]
	it "does not leak state across nested chains", ->
		output = []
		f = -> output.push "f"
		g = -> output.push "g"
		h = -> output.push "h"
		fg = Aspects(f, g)
		fgh = Aspects(fg, h)
		fg()
		assert.deepEqual output, ["f","g"]
		output = []
		fgh()
		assert.deepEqual output, ["f","g","h"]
	it "can abort a chain", ->
		output = []
		f = -> output.push "f"
		g = -> new Aspects.Op("abort")
		h = -> output.push "h"
		do Aspects(f, g, h)
		assert.deepEqual output, ["f"]
	it "can alter the arguments for rest of the chain", ->
		outputA = []
		outputB = []
		f = (output) -> output.push 'f'
		g = (output) -> new Aspects.Op('arguments', [outputB])
		h = (output) -> output.push 'h'
		Aspects(f,g,h)(outputA)
		assert.deepEqual outputA, ['f']
		assert.deepEqual outputB, ['h']
	describe "inheriting aspects", ->
		output = []
		class A
			constructor: -> @a = 1
			fA: -> output.push 'a'; @
			fC: -> output.push 'c'; @
		class B
			constructor: -> @b = 2
			fB: -> output.push 'b'; @
			fC: -> output.push 'd'; @
		class C extends Aspects(A,B)

		w = new C()
		it "chains the constructor", ->
			assert "chain" of C
			assert C.chain.contains A
		it "runs all constructors when creating new instances", ->
			assert.equal w.a, 1
			assert.equal w.b, 2
		it "preserves functions from the prototype", ->
			output.clear()
			w.fA().fB()
			assert.deepEqual output, ['a','b']
		it "chains functions that collide", ->
			output.clear()
			assert "chain" of w.fC
			w.fC()
			assert.deepEqual output, ['c','d']
		it "can nest and mix multiple classes and chains", ->
			output.clear()
			D = Aspects A,B, Aspects A,B, Aspects A,B
			new D()
				.fA() # calls fA 3x
				.fB() # calls fB 3x
				.fC() # calls fC 3x (adding 'c','d' each time)
			assert.deepEqual output, ['a','a','a','b','b','b','c','d','c','d','c','d']
		it "can re-extend", ->
			output.clear()
			class D extends C
				fD: -> output.push 'd'; @
			new D().fA().fB().fC().fD()
			assert.deepEqual output, ['a','b','c','d','d']
		it "can re-mix and extend", ->
			output.clear()
			class D
				fD: -> output.push 'd'; @
			class E
				fC: -> output.push 'e'; @
				fE: -> output.push 'e'; @
			e = new (Aspects C,D,E)
			e.fA().fB().fC().fD().fE()
			assert.deepEqual output, ['a','b','c','d','e','d','e']
			assert.equal e.a, 1
			assert.equal e.b, 2


