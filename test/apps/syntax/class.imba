
describe 'Defining classes' do

	test 'Class declarations' do
		class Rectangle
			def constructor height, width
				@height = height
				@width = width

		ok Rectangle.new

	test 'Class expressions' do
		# unnamed
		var expr = class
			def constructor height, width
				@height = height
				@width = width
		ok expr.new
		ok expr.name == 'expr'

		# named
		var expr = class NamedClass
			def constructor height, width
				@height = height
				@width = width
		ok expr.new
		ok expr.name == 'NamedClass'

describe 'Class body and method definitions' do

	test 'Prototype methods' do

		class Rectangle
			# constructor
			def constructor height, width
				@height = height
				@width = width

			# Getter
			get area
				@calcArea()

			# Method
			def calcArea
				return @height * @width

	test 'Static methods' do

		class Point
			# constructor
			def constructor x, y
				@x = x
				@y = y


			static def distance a,b
				const dx = a.x - b.x
				const dy = a.y - b.y
				Math.hypot(dx, dy)

		const p1 = Point.new(5, 5)
		const p2 = Point.new(10, 10)

		eq Point.distance(p2,p1), Math.hypot(5,5)


	test 'Dynamic methods' do
		let method = 'hello'
		class Example

			static def [method]
				return 'static'

			def [method]
				return 'member'

		ok Example.new.hello() == 'member'
		ok Example.hello() == 'static'

test 'Subclassing' do

	class Animal
		def constructor name
			@name = name

		def speak
			"{@name} makes a noise"

	class Dog < Animal
		def constructor name
			super(name)

		def speak
			"{@name} barks."

	let dog = Dog.new 'Mitzie'

	eq dog.speak(), 'Mitzie barks.'

test 'Super class calls with super' do

	class Cat
		def constructor name
			@name = name

		def speak
			console.info "{@name} makes a noise."

	class Lion < Cat
		def speak
			super.speak()
			console.info "{@name} roars."

	let lion = Lion.new('Fuzzy')

	lion.speak()
	eq $1.log, ['Fuzzy makes a noise.','Fuzzy roars.']

