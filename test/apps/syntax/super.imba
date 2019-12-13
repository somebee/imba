class Animal

	def constructor ...params
		@params = params

	get name
		'Animal'

	set alias value
		#alias = value

	def skills
		[1,2,3,4]

	def test ...params
		return params

class Cat < Animal

	def constructor
		super

	get name
		"Cat {super.name} {super}"

	set alias value
		super # same as super.alias = value
		super.alias = value

	def test
		[
			super, # same as super.test(...arguments)
			super(1), # same as super.test(1)
			super.test(2,3) # same as super.test(2,3)
		]

class Dog < Animal

	def constructor a,b
		super(a)

test do
	eq Cat.new(1,2,3).params, [1,2,3]

test do
	eq Cat.new.name, "Cat Animal Animal"

test do
	eq Cat.new.test(10,20), [ [10,20],[1],[2,3] ]

test do
	eq Dog.new(1,2,3).params, [1]