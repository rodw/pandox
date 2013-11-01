should         = require 'should'
fs             = require 'fs'
path           = require 'path'
HOMEDIR        = path.join(__dirname,'..')
LIB_COV        = path.join(HOMEDIR,'lib-cov')
LIB_DIR        = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
StringCombiner = require(path.join(LIB_DIR,'string-combiner')).StringCombiner
UpCaser        = require(path.join(LIB_DIR,'up-caser')).UpCaser

DATA_DIR       = path.join(HOMEDIR,'test','data')

describe 'StringCombiner',->

  it 'can be used combine strings', (done)->
    SIMPLE_MD_JSON = require( path.join(DATA_DIR,'simple.json') )
    filter = new StringCombiner()
    result = filter.execute(SIMPLE_MD_JSON)
    found = JSON.stringify(result)
    /Simple Markdown Example/.test(found).should.be.ok
    /This is a simple example of/.test(found).should.be.ok
    /Numbered Lists/.test(found).should.be.ok
    done()

  it 'can be chained with upcaser', (done)->
    SIMPLE_MD_JSON = require( path.join(DATA_DIR,'simple.json') )
    filter = (new StringCombiner()).chain(new UpCaser())
    result = filter.execute(SIMPLE_MD_JSON)
    found = JSON.stringify(result)
    /SIMPLE MARKDOWN EXAMPLE/.test(found).should.be.ok
    /THIS IS A SIMPLE EXAMPLE OF/.test(found).should.be.ok
    /NUMBERED LISTS/.test(found).should.be.ok
    done()

  it 'operates on meta-data too', (done)->
    SIMPLE_MD_JSON = require( path.join(DATA_DIR,'simple-with-meta.json') )
    filter = new StringCombiner()
    result = filter.execute(SIMPLE_MD_JSON)
    found = JSON.stringify(result)
    /Rod Waldhoff/.test(found).should.be.ok
    /31 October 2013/.test(found).should.be.ok
    /An Example with Meta-Data/.test(found).should.be.ok
    done()
