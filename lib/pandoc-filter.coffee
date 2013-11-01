path     = require 'path'
optimist = require 'optimist'
ARGF     = require 'argf'

# A base filter for processing the JSON-representation of a Pandoc AST.
#
# See <http://johnmacfarlane.net/pandoc/scripting.html> for more information.
#
# Pandoc's JSON-format AST (which can be generated via `pandoc -t json`)
# is an *array* with two elements.
#
# The first element is an *object* containing metadata like the document
# author or title.  (Parsed from the `%` lines at the top of a Markdown
# document, for example.)
#
# The second element is an *array* of "block" *objects*, representing the
# contents of the document.  Each block has two attributes:
#
#   - `t` - a *type* identifier (`Str`, `Header`, etc.)
#
#   - `c` - the *contents* of said block.
#
# A `PandocFilter` transforms blocks (and by extension, documents).
#
# The primary transformation method is called `action`, and has the
# signature:
#
#     function action(type,content,format,meta) { }
#
# where
#
#   - `type` is the block's type (`t`) attribute
#
#   - `content` is the block's content (`c`) attribute
#
# The value returned by `action` determines the transformed block:
#
#   - when `null` is returned, the block is not changed.
#
#   - when an object (presumably a new block) is returned, the
#     given block replaces the original (in the output document).
#
#   - when an array is returned, the elements of the array are
#     inserted into the output document in place of this element.
#
#   - when an *empty* array is returned, the block is removed from
#     the output document.
#
# To specify an `action` method, one may extend this class and
# override the `@action` method, or one may provide an `action` as
# an argument when constructing a new instance.
#
class PandocFilter

  # Create a new filter instance; optionally using the given `action` method.
  constructor:(action)->
    if action?
      @action_method = action

  # Filter the given `tree` (applying chained filters first, if any).
  # Returns a modified tree.
  execute:(tree,format,meta)=>
    if @chained?
      tree = @chained.execute(tree,format,meta)
    @walk(tree,@action,format,meta)

  # Recursively visit the elements of the given `tree`, performing
  # the specified `action` on each.
  # Returns a modified tree.
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

  # (An internal function, returning `true` if the given `fn` seems to be a constructor.)
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

  #
  # Chain the given `filter` to with this one.
  #
  # When `execute` is invoked, any chained filter will be applied
  # before this one.  (I.e., `a.chain(b)` yields `a(b(x))`.
  #
  # This method returns `this`, so the method calls can also be
  # chained together.  For example:
  #
  #     a.chain(b).chain(c)
  #
  # yields:
  #
  #     a(b(c(x))))
  #
  # Note that if a chained filter has already been assigned and
  # that filter supports a `chain` method, the new filter is
  # `chain`ed to the current one.
  #
  # The `filter` argument may be:
  #
  #  - An instance of `PandocFilter` or one of its subclasses
  #
  #  - A string, which is assumed to be the name of a module
  #    exporting a `PandocFilter` or one of its subclasses
  #
  #  - A function, which is assumed to one of:
  #
  #     - The constructor for a `PandocFilter` or one
  #       of its subclasses, or
  #
  #     - An `action` method.
  #
  chain:(filter)=>
    if typeof filter is 'string'
      filter = require(path.resolve(process.cwd(),filter))
    if typeof filter is 'function'
      if @_function_is_constructor(filter)
        filter = new filter()
      else
        filter = new PandocFilter(filter)
    if filter? and @chained?.chain? and (typeof @chained.chain is 'function')
      @chained.chain(filter)
    else
      @chained = filter
    return this

  # The `action` method, applied to each block of the tree.
  #
  # The default `action` will perform an identity transformation.
  # (I.e., it doesn't change anything about the tree.)
  #
  # To make this do something useful, this method may be overwritten by
  # subclasses or instances, or an `action` method may be provided to
  # the `PandocFilter` constructor.
  action:(type,content,format,meta)->
    if @action_method?
      return @action_method(type,content,format,meta)
    else
      return null

  # Populates the `@options` map with configuration parameters to pass to `node-optimist`.
  init_options:(options)=>
    @options = options ? @options
    @options ?= {}
    @options.h = { alias: 'help', boolean: true, describe: "Show this help message." }
    @options.f = { alias: 'filter', describe: "A filter to apply before this one. May be repeated.", required:false }

  # Uses `node-optimist` and the current `@options` map to initialize `@argv` base on the current command line parameters.
  init_argv:()=>
    @argv = optimist.options(@options).usage('Usage: $0 [OPTIONS] [FILE]').argv

  # Returns `true` if `value` is a truthy string value.
  is_true_string:(value)->value? and value.toUpperCase() in ['TRUE','T','YES','Y',1,'1','ON']

  # Returns `true` if `value` is a falsey string value.
  is_false_string:(value)->value? and value.toUpperCase() in ['NONE','HIDDEN','HIDE','NO','N','FALSE','F',0,'0','OFF']

  # Invoked when `-h` or `--help` is specifed on the command line.
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

  # Returns an option description of this filter, used by `@on_help`.
  get_description:()->null

  # Called after `@on_help`. Invokes `process.exit()` by default.
  after_help:()->process.exit(0)

  # Process the command-line arguments and apply this filter.
  #
  # Note that sub-classes can make use of this method as well.
  # In the simplest case, this looks something like:
  #
  #     if(require.main === module) {
  #       (new MyFilter()).main();
  #     }
  #
  # The default implementation accepts two (optional) parameters:
  #
  # 1. `-h`/`--help`, which shows a brief usage summary
  #
  # 2. `-f`/`--filter`, the location of node.js module (relative to `cwd`)
  #    which creates a `PandocFilter` instance when `required`.
  #
  # More than one `-f` parameter can be provided.  Any filters specified on the
  # command line will be chained together (in sequence).
  #
  # Generally the output of a pandoc process (e.g. `pandoc -t json`) will be
  # piped to this application, but alternatively one may specify a file
  # as a command-line parameter.
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

# Export `PandocFilter`
exports = module.exports = PandocFilter

# If this file is loaded directly, execute the `@main` method.
if require.main is module
  (new PandocFilter()).main()
