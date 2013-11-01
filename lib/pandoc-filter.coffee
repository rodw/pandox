path = require 'path'
optimist = require 'optimist'
ARGF     = require('argf')

class PandocFilter
  constructor:(action)->
    if action?
      @action_method = action

  execute:(tree,format,meta)=>
    if @chained?
      tree = @chained.execute(tree,format,meta)
    @walk(tree,@action,format,meta)

  walk:(tree,action,format,meta)->
    if Array.isArray(tree)
      list = tree
      newlist = []
      for block in list
        if block.t?
          result = action(block.t,block.c,format,meta)
          if not result?
            newlist.push( @walk(block,action,format,meta) )
          else if Array.isArray(result)
            for item in result
              newlist.push( @walk(item,action,format,meta) )
          else
            newlist.push( @walk(result,action,format,meta) )
        else
          newlist.push( @walk(block,action,format,meta) )
      return newlist
    else if tree.t?
      result = action(tree.t,tree.c,format,meta)
      if not result?
        tree.c = @walk(tree.c,action,format,meta)
        return tree
      else if Array.isArray(result)
        return @walk(result,action,format,meta)
      else if result.c?
        result.c = @walk(result.c,action,format,meta)
        return result
      else
        return result
    else if tree.unMeta?
      result = action('unMeta',tree.unMeta,format,meta)
      if result?
        tree.unMeta = @walk(result,action,format,meta)
      newmeta = {}
      for n,v of tree.unMeta
        result = action(n,v,format,meta)
        if not result?
          newmeta[n] = @walk(tree.unMeta[n],action,format,meta)
        else if (Array.isArray(result)) and (result.length is 0)
          # drop this meta value when an empty array is returned
        else
          newmeta[n] = @walk(result,action,format,meta)
      tree.unMeta = newmeta
      return tree
    else
      return tree

  _function_is_constructor:(fn)->
    if typeof fn is 'function'
      instance = new fn()
      has_property = false
      for n,v of instance
        has_property = true
        break
      return has_property
    else
      return false

  chain:(filter)=>
    if typeof filter is 'string'
      filter = require(filter)
    if typeof filter is 'function'
      if @_function_is_constructor(filter)
        filter = new filter()
      else
        filter = new PandocFilter(filter)
    if filter? and @chained?.chain?
      @chained.chain(filter)
    else
      @chained = filter
    return this

  action:(type,content,format,meta)->
    if @action_method?
      return @action_method(type,content,format,meta)
    else
      return null

  init_options:(options)=>
    @options = options ? @options
    @options ?= {}
    @options.h = { alias: 'help', boolean: true, describe: "Show this help message." }
    @options.f = { alias: 'filter', describe: "A filter to apply before this one. May be repeated.", required:false }

  init_argv:()=>
    @argv = optimist.options(@options).usage('Usage: $0 [OPTIONS] [FILE]').argv

  is_true_string:(value)->value? and value.toUpperCase() in ['TRUE','T','YES','Y',1,'1','ON']
  is_false_string:(value)->value? and value.toUpperCase() in ['NONE','HIDDEN','HIDE','NO','N','FALSE','F',0,'0','OFF']

  on_help:()->
    console.log("")
    optimist.showHelp()
    description = @get_description()
    if description?
      console.log(description)
      console.log("")
    console.log("Examples:")
    cmd = "#{process.argv[0]} #{path.basename(process.argv[1])}"
    console.log("  pandoc -t json FILE.md | #{cmd}")
    console.log("  pandoc -t json FILE.md > FILE.json && #{cmd} FILE.json")
    console.log("")
    @after_help()

  get_description:()->null

  after_help:()->process.exit(0)

  main:()=>
    @init_options() unless @options?
    @init_argv() unless @argv?
    if @argv.help
      @on_help()
    if @argv.filter?
      if typeof @argv.filter is 'string'
        @chain(@argv.filter)
      else if Array.isArray(@argv.filter)
        for filter in @argv.filter
          @chain(filter)
    argf = new ARGF(@argv._)
    data = []
    argf.forEach (line)->data.push(line)
    argf.on 'finished', ()=>
      json = JSON.parse(data.join(''))
      result = @execute(json)
      console.log JSON.stringify(result)

exports = module.exports = PandocFilter

if require.main is module
  (new PandocFilter()).main()
