traverse = require 'traverse'

class PandocFilter
  constructor:(@action,@exec_method)->
    @exec_method ?= 'for_each'

  execute:(node)=>@[@exec_method](node)

  for_each:(node)=>
    return @traverse('forEach',node)

  map:(node)=>
    return @traverse('map',node)

  traverse:(method,node)=>
    if @chained?
      node = @chained.execute(node)
    visit = @visit
    node = traverse(node)[method] (value)->
      result = visit(this.key,value,this)
      if result?
        this.update(result)
      else
        this.remove(true)
    return node

  visit:(key,value,context)=>
    if @action?
      return @action(key,value,context)
    else
      return value

  chain:(filter)=>
    @chained = filter
    return this

exports = exports ? this
exports.PandocFilter = PandocFilter
