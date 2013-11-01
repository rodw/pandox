fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
PandocFilter = require(path.join(LIB_DIR,'pandoc-filter'))

class UpCaser extends PandocFilter

  get_description:()->"Converts all strings to upper case (ignoring code blocks)."

  action:(type,content,format,meta)->
    if type is 'Str'
      return { t:type, c:content.toUpperCase() }
    else
      return null

exports = module.exports = UpCaser

if require.main is module
  (new UpCaser()).main()
