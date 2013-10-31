fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
PandocFilter = require(path.join(LIB_DIR,'pandoc-filter')).PandocFilter

class StringCombiner extends PandocFilter
  constructor:()->
    super(null,'map')

  visit:(key,value)=>
    if Array.isArray(value)
      new_array = []
      current = null
      for elt in value
        if elt.t is 'Str'
          current ?=  { 't':'Str', 'c':'' }
          current.c += elt.c
        else if elt.t is 'Space'
          current ?=  { 't':'Str', 'c':'' }
          current.c += ' '
        else
          if current?
            new_array.push current
            current = null
          new_array.push elt
      if current?
        new_array.push current
      return new_array
    else
      return value

exports = exports ? this
exports.StringCombiner = StringCombiner

if require.main is module
  (new StringCombiner()).main()
