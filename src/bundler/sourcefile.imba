import compiler from 'compiler'
import imba1 from 'compiler1'
import {SourceMapper} from '../compiler/sourcemapper'
import {resolveDependencies} from '../compiler/transformers'

const defaultConfig = {
	platform: 'node',
	format: 'esm',
	raw: true
	imbaPath: 'imba'
	styles: 'extern'
	hmr: true
	bundle: false
}

const defaults = {
	node: {
		ext: '.mjs'
	}

	web: {
		ext: '.js'
	}
}

export default class SourceFile
	def constructor src
		#cache = {}
		src = src
		out = {
			meta: mirrorFile('.meta')
			css: mirrorFile('.css')
			node: mirrorFile('.mjs')
			web: mirrorFile('.web.js')
			browser: mirrorFile('.web.js')
			transformed: mirrorFile('.trs.js')
		}
	
	get fs do src.fs
	get cwd do fs.cwd
	get program do #program ||= fs.program
	get config do program.config

	def mirrorFile ext
		let fs = fs
		fs.lookup((fs.outdir or '.') + '/' + src.rel + ext)

	# making sure that the actual body is there
	def prepare
		await precompile!

	def readSource
		#cache.source ||= src.read!

	def invalidate
		# possibly try to recompile -- see if anything has changed for real and all that
		let prevBody = #cache.source
		#cache = {}
		# setTimeout(&,20) do precompile!
		self

	def load
		# program should be implied, no?
		# run as a full-blown promise?
		#cache.load ||= program.queue(#load!)

	def #load
		# console.log "loading {src.rel}"
		# run as a full-blown promise?
		# program.queue #cache.build ||= new Promise do(resolve,reject)
		let jsfile = out.node
		let srctime = src.mtimesync
		let outtime = jsfile.scanned? ? jsfile.mtimesync : 0
		let manifest = {node: {}, web: {}}
		let resolver = program.resolver
		let fs = fs

		# register to watch file
		src.watch(self)
		
		# the previous one was built earlier
		if outtime > srctime and outtime > program.mtime
			console.log 'cached imba',src.rel,outtime - srctime
			return Promise.resolve(yes)

		try
			# this makes the promises not work?
			console.log 'need to compile',src.rel
			let sourceBody = await src.read!
			let rawResults 

			for platform in ['node','web']
				# console.log "start compile! {src.rel}",platform,srctime,outtime
				let web = platform == 'web'
				let cfg = defaults[platform]
				let outfile = out[platform] # web ? webfile : jsfile # mirrorFile(cfg.ext)
				let meta = manifest[platform] 
				let imports = meta.imports ||= {}
				# should not always compile both

				let opts = Object.assign({
					platform: platform
					format: 'esm'
					raw: true
					sourcePath: src.rel
					sourceId: src.id
					cwd: cwd
					imbaPath: 'imba' # need to be able to change this?
					styles: 'extern'
					hmr: true
					bundle: false
					config: program.config
				})

				# ,program.config

				let legacy = (/\.imba1$/).test(src.rel)

				if legacy
					opts.filename = opts.sourcePath
					opts.target = platform #  == 'node' ? opts.platform : 'web'
					opts.inlineHelpers = 1

				if legacy
					let res = imba1.compile(sourceBody,opts)
					await outfile.write(res.js)
				else
					let res = rawResults or compiler.compile(sourceBody,opts)
					let js = res.js

					let onResolve = do(args)
						let res = imports[args.path] = resolver.resolve(args)
						let path = res.path

						if res.namespace
							let file = fs.lookup(path)
							let resolvedFile = file

							if args.css
								console.log 'resolving with css',args,res

							if res.namespace != 'file' and file.asset and !args.css
								file.asset.load!
								# TODO need to ensure that this path exists before doing more?
								file = file.asset.out.js
								console.log 'onresolve',args

							if file.imba
								# resolvedFile = res.remapped = file.imba.out[platform].rel
								file.imba.load!
								return resolver.relative(src.reldir,file.rel)
								# path = file.rel
							return file.abs

							return resolver.relative(src.reldir,path)

							return resolver.relative(outfile.reldir,path)
						
						return path or null

					js = resolveDependencies(src.rel,js,onResolve)

					if res.css.length
						if platform == 'node'
							res.css = resolveDependencies(src.rel,res.css,onResolve, css: true)
							await out.css.write(SourceMapper.strip(res.css))

						# need to resolve mappings?
						js += "\nimport '{out.css.abs}'"

					await outfile.write(SourceMapper.strip(js))

					if false
						let esb = await program.esb!
						let stripped = SourceMapper.strip(js)
						console.log 'will transform',src.rel
						let ojs = await esb.transform(stripped,{
							sourcefile: src.rel
							format: 'esm'
							minifySyntax: false
							minifyIdentifiers: false
						})

						if ojs.errors..length
							console.log 'errors in transform',src.rel,ojs.errors

					# console.log 'transformed',ojs.code
					# await out.transformed.write(SourceMapper.strip(ojs.code))

					if res.universal
						# console.log "universal {src.rel}"
						rawResults = res
						# no need to even save the web file(!)
						# but we need to check if it exists?!
						# break
					else
						yes
						# if src.rel.indexOf('/core') >= 0
						#	console.log "not universal {src.rel}",opts
						# console.log 'no need to build for web as well!!'
						# break

			# console.log 'write manifest'
			await out.meta.write(JSON.stringify(manifest,null,2))
			# console.log 'imports',imports
		catch e
			console.log 'error',e
			yes
		return self

	
	def #compile opts
		# check for cached version of this
		self


	def build dest, o = {}
		#cache[dest] ||= new Promise do(resolve,reject)
			let opts = Object.assign({
				platform: '',
				format: 'esm',
				raw: true
				sourcePath: src.rel,
				sourceId: src.id,
				cwd: cwd,
				imbaPath: 'imba'
				styles: 'extern'
				hmr: true
				bundle: false
			},o)

			let t = Date.now!

			mtsrc ||= await src.mtime!
			let mtdest = await dest.mtime!

			if mtdest > mtsrc and mtdest > program.mtime
				let body = await dest.read!
				return resolve(body)

			try
				let legacy = (/\.imba1$/).test(src.rel)
				let lib = legacy ? imba1 : compiler
			
				let sourceCode = await readSource!

				if legacy
					opts.filename = opts.sourcePath
					opts.target = opts.platform
					opts.inlineHelpers = 1

				let res = lib.compile(sourceCode,opts)
				console.log 'compiling',src.rel

				if legacy
					await dest.write(res.js)
				else
					let js = res.js
					if res.css.length
						let cssfile = mirrorFile('.css')
						await cssfile.write(SourceMapper.strip(res.css))
						js += "\nimport './{cssfile.name}'"
				
					await dest.write(SourceMapper.strip(js))

					# possibly also build one for web?

				# console.log 't',Date.now! - t,src.rel,src.id
				# console.log 'write to',dest.rel,res.js.length,sourceCode.length,Date.now! - t
				resolve(res.js)
			catch e
				resolve(errors: [])

	def precompile o = {}
		# let key -- get a key based on the options
		o.platform ||= 'browser'
		let key = o.platform
		#cache[key] ||= new Promise do(resolve,reject)
			let opts = Object.assign({
				platform: platform,
				format: 'esm',
				raw: true
				sourcePath: src.rel,
				sourceId: src.id,
				cwd: cwd,
				imbaPath: 'imba'
				styles: 'extern'
				hmr: true
				bundle: false
			},o)

			# slow?
			let tmpfile = src.tmp(".{key}")
			let t = Date.now!
			mtsrc ||= await src.mtime!
			let mtdest = await tmpfile.mtime!

			if mtdest > mtsrc and mtdest > program.mtime
				let body = await tmpfile.read!
				return resolve(body)

				let result = compiler.deserialize(body,{sourcePath: src.rel})
				return resolve(result)

			try
				let legacy = (/\.imba1$/).test(src.rel)
				let lib = legacy ? imba1 : compiler
			
				let sourceCode = await readSource!

				if legacy
					opts.filename = opts.sourcePath
					opts.target = opts.platform
					opts.inlineHelpers = 1

				let res = lib.compile(sourceCode,opts)
				console.log 'compiling',src.rel

				if legacy
					tmpfile.write(res.js)
				else
					tmpfile.write(SourceMapper.strip(res.js))
					console.log 'write css',src.rel,res.css.length
					cssfile.write(SourceMapper.strip(res.css)) if res.css

				console.log 't',Date.now! - t,src.rel,src.id
				console.log 'write to',tmpfile.rel,res.js.length,sourceCode.length,Date.now! - t
				resolve(res.js)
			catch e
				resolve(errors: [])

	def compile o = {}
		# for now we expect
		console.log 'compiling!',src.abs
		let code = await precompile(o)
		if o.styles == 'import' and code.indexOf('HAS_CSS_STYLES') >= 0
			code += "\nimport '{src.abs}.css'"
		let out = SourceMapper.run(code,o)
		return out.code

	def getStyles o = {}
		await load!
		return out.css.read!

		let code = await cssfile.read!
		let out = SourceMapper.run(code,o)
		return out.code