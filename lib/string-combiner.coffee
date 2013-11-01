fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
PandocFilter = require(path.join(LIB_DIR,'pandoc-filter'))

class StringCombiner extends PandocFilter

  get_description:()->"Collapses each sequence of strings and spaces into a single string."

  action:(type,content,format,meta)=>
    if Array.isArray(content)
      new_array = []
      current = null
      for elt in content
        if elt?.t is 'Str'
          current ?=  { 't':'Str', 'c':'' }
          current.c += elt.c
        else if elt?.t is 'Space'
          current ?=  { 't':'Str', 'c':'' }
          current.c += ' '
        else
          if Array.isArray(elt)
            result = @action(null,elt,format,meta)
            if result?.c?
              elt = result.c
          if current?
            new_array.push current
            current = null
          new_array.push elt
      if current?
        new_array.push current
      return { t:type, c:new_array }
    else
      return null

exports = module.exports = StringCombiner

if require.main is module
  (new StringCombiner()).main()
