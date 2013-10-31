should       = require 'should'
fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
CodeBlockProcessor = require(path.join(LIB_DIR,'code-block-processor')).CodeBlockProcessor


DATA_DIR     = path.join(HOMEDIR,'test','data')

describe 'CodeBlockProcessor',->

  it 'can hide a codeblock', (done)->
    original = require( path.join(DATA_DIR,'codeblock-hide.json') )
    expected = JSON.stringify(require( path.join(DATA_DIR,'codeblock-hidden.json')))
    filter = new CodeBlockProcessor()
    result = filter.execute(original)
    found = JSON.stringify(result)
    found.should.equal(expected)
    done()

  it 'can import a codeblock', (done)->
    original = require( path.join(DATA_DIR,'codeblock-import.json') )
    # expected = JSON.stringify(require( path.join(DATA_DIR,'codeblock-hidden.json')))
    filter = new CodeBlockProcessor()
    result = filter.execute(original)
    found = JSON.stringify(result)
    /extensions for Pandoc, the universal document converter./.test(found).should.be.ok
    /This code block won\'t appear in the final output./.test(found).should.not.be.ok
    done()

  # it 'can import a codeblock', (done)->
  #   original = [{"docTitle":[],"docAuthors":[],"docDate":[]},[{"Para":[{"Str":"Above"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]},{"CodeBlock":[["theid",["class1","class2"],[["input-file","package.json"]]],"Within\nthe\ncode block."]},{"Para":[{"Str":"Below"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]}]]
  #   filter = new CodeBlockProcessor()
  #   result = filter.execute(original)
  #   /\"devDependencies\":/.test(result[1][1].CodeBlock[1]).should.be.ok
  #   done()
