should       = require 'should'
fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
CodeBlockProcessor = require(path.join(LIB_DIR,'code-block-processor'))


DATA_DIR     = path.join(HOMEDIR,'test','data')

describe 'CodeBlockProcessor',->

  it 'can hide a codeblock', (done)->
    original = require( path.join(DATA_DIR,'codeblock-hide.json') )
    expected = JSON.stringify(require( path.join(DATA_DIR,'codeblock-hidden.json')))
    filter = new CodeBlockProcessor()
    result = filter.execute(original)
    found = JSON.stringify(result)
    /This code block won\'t appear in the final output./.test(found).should.not.be.ok
    found.should.equal(expected)
    done()

  it 'can import a codeblock', (done)->
    original = require( path.join(DATA_DIR,'codeblock-import.json') )
    filter = new CodeBlockProcessor()
    result = filter.execute(original)
    found = JSON.stringify(result)
    /extensions for Pandoc, the universal document converter./.test(found).should.be.ok
    /This code block won\'t appear in the final output./.test(found).should.not.be.ok
    done()
