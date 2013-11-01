traverse = require 'traverse'

class PandocFilter

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

  action:(type,content,format,meta)->return null

  chain:(filter)=>
    @chained = filter
    return this

  main:()=>
    data = []
    process.stdin.resume()
    process.stdin.setEncoding('utf8')
    process.stdin.on 'data', (chunk)=>data.push(chunk)
    process.stdin.on 'end', ()=>
      json = JSON.parse(data.join(''))
      result = @walk(json,@action)
      console.log JSON.stringify(result)

exports = exports ? this
exports.PandocFilter = PandocFilter

if require.main is module
  (new PandocFilter()).main()
