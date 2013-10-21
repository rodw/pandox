should       = require 'should'
fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
pandox       = require(path.join(LIB_DIR,'index'))

describe 'Index',->

  it 'exports various classes', (done)->
    should.exist pandox.PandocFilter
    should.exist pandox.UpCaser
    should.exist pandox.CodeBlockProcessor
    should.exist pandox.StringCombiner
    done()
