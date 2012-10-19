assert = require 'assert'
require 'bling'
$.extend global, require '../modular'

describe "modular.coffee", ->
	describe "MethodChain", ->
		it "chains two methods into one", ->
			output = []
			f = -> output.push "f"
			g = -> output.push "g"
			m = MethodChain(f, g)
			m()
			assert.deepEqual output, ["f", "g"]
		it "chains any number of methods at once", ->
			output = []
			f = -> output.push "f"
			g = -> output.push "g"
			h = -> output.push "h"
			m = MethodChain(f, g, h)
			m()
			assert.deepEqual output, ["f", "g", 'h']
		it "flattens/unrolls nested chains", ->
			output = []
			f = -> output.push "f"
			g = -> output.push "g"
			h = -> output.push "h"
			i = -> output.push "i"
			m = MethodChain(f, MethodChain(g, MethodChain(h, i)))
			m()
			assert.deepEqual output, ["f", "g", "h", "i"]
		it "does not leak state across nested chains", ->
			output = []
			f = -> output.push "f"
			g = -> output.push "g"
			h = -> output.push "h"
			fg = MethodChain(f, g)
			fgh = MethodChain(fg, h)
			fg()
			assert.deepEqual output, ["f","g"]
			output = []
			fgh()
			assert.deepEqual output, ["f","g","h"]
		it "can abort a chain", ->
			output = []
			f = -> output.push "f"
			g = -> new MethodChainOp("abort")
			h = -> output.push "h"
			do MethodChain(f, g, h)
			assert.deepEqual output, ["f"]
		it "can alter the arguments for rest of the chain", ->
			outputA = []
			outputB = []
			f = (output) -> output.push 'f'
			g = (output) -> new MethodChainOp('arguments', [outputB])
			h = (output) -> output.push 'h'
			MethodChain(f,g,h)(outputA)
			assert.deepEqual outputA, ['f']
			assert.deepEqual outputB, ['h']


	describe "class Modular", ->
		it "is an EventEmitter", ->
			m = new Modular()
			assert 'emit' of m
		it "can be extended", ->
			class Foo extends Modular
			assert 'init' of new Foo()
		it "gives any subclass a static @mixin function", ->
			class Foo extends Modular
			assert 'mixin' of Foo
		it "auto-invokes @init() when constructed", ->
			output = []
			class Foo extends Modular
				init: -> output.push "Foo"
			f = new Foo()
			assert.deepEqual output, ["Foo"]
		describe "Modular.mixin()", ->
			it "chains shared methods", ->
				output = []
				class Foo extends Modular
					init: -> output.push "Foo"
				class Bar extends Modular
					init: -> output.push "Bar"
					@mixin Foo
				b = new Bar()
				assert.deepEqual output, ["Bar", "Foo"]
			it "tree-chains do not cross-pollinate", ->
				output = []
				class A extends Modular
					init: -> output.push "A"
				class B extends Modular
					init: -> output.push "B"
					@mixin A
				class C extends Modular
					init: -> output.push "C"
					@mixin A
				a = new A()
				b = new B()
				c = new C()
				assert.deepEqual output, ["A", "B", "A", "C", "A"]
			it "can mix heterogeneous classes", ->
				output = []
				class A extends Modular
					init: -> output.push "A.init"
					A: -> output.push "A.A"
				class B extends Modular
					init: -> output.push "B.init"
					B: -> output.push "B.B"
					@mixin A

				b = new B()
				assert.deepEqual output, ["B.init", "A.init"]
				b.B()
				b.A()
				assert.deepEqual output, ["B.init", "A.init", "B.B", "A.A"]


