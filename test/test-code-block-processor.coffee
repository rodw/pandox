should       = require 'should'
fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
CodeBlockProcessor = require(path.join(LIB_DIR,'code-block-processor')).CodeBlockProcessor

describe 'CodeBlockProcessor',->

  it 'can hide a codeblock', (done)->
    original = [{"docTitle":[],"docAuthors":[],"docDate":[]},[{"Para":[{"Str":"Above"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]},{"CodeBlock":[["theid",["class1","class2"],[["display","none"]]],"Within\nthe\ncode block."]},{"Para":[{"Str":"Below"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]}]]
    filtered = [{"docTitle":[],"docAuthors":[],"docDate":[]},[{"Para":[{"Str":"Above"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]},{"Para":[{"Str":"Below"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]}]]
    expected = JSON.stringify(filtered)
    filter = new CodeBlockProcessor()
    result = filter.execute(original)
    found = JSON.stringify(result)
    found.should.equal(expected)
    done()

  it 'can import a codeblock', (done)->
    original = [{"docTitle":[],"docAuthors":[],"docDate":[]},[{"Para":[{"Str":"Above"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]},{"CodeBlock":[["theid",["class1","class2"],[["input-file","package.json"]]],"Within\nthe\ncode block."]},{"Para":[{"Str":"Below"},"Space",{"Str":"the"},"Space",{"Str":"code"},"Space",{"Str":"block"},{"Str":"."}]}]]
    filter = new CodeBlockProcessor()
    result = filter.execute(original)
    /\"devDependencies\":/.test(result[1][1].CodeBlock[1]).should.be.ok
    done()
