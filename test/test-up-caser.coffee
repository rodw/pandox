should         = require 'should'
fs             = require 'fs'
path           = require 'path'
HOMEDIR        = path.join(__dirname,'..')
LIB_COV        = path.join(HOMEDIR,'lib-cov')
LIB_DIR        = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
StringCombiner = require(path.join(LIB_DIR,'string-combiner')).StringCombiner
UpCaser        = require(path.join(LIB_DIR,'up-caser')).UpCaser

DATA_DIR       = path.join(HOMEDIR,'test','data')

describe 'UpCaser',->

  it 'converts strings to upper case', (done)->
    SIMPLE_MD_JSON = require( path.join(DATA_DIR,'simple.json') )
    filter = new UpCaser()
    result = filter.execute(SIMPLE_MD_JSON)
    found = JSON.stringify(result)
    /SIMPLE/.test(found).should.be.ok
    /MARKDOWN/.test(found).should.be.ok
    /EXAMPLE/.test(found).should.be.ok
    /THIS/.test(found).should.be.ok
    /IS/.test(found).should.be.ok
    /A/.test(found).should.be.ok
    /SIMPLE/.test(found).should.be.ok
    /EXAMPLE/.test(found).should.be.ok
    /OF/.test(found).should.be.ok
    /NUMBERED/.test(found).should.be.ok
    /LISTS/.test(found).should.be.ok
    done()

  it 'leaves code blocks alone', (done)->
    SIMPLE_MD_JSON = require( path.join(DATA_DIR,'simple.json') )
    filter = new UpCaser()
    result = filter.execute(SIMPLE_MD_JSON)
    found = JSON.stringify(result)
    /Hello/.test(found).should.be.ok
    /World/.test(found).should.be.ok
    done()

  it 'can be chained with string combiner', (done)->
    SIMPLE_MD_JSON = require( path.join(DATA_DIR,'simple.json') )
    filter = (new UpCaser()).chain(new StringCombiner())
    result = filter.execute(SIMPLE_MD_JSON)
    found = JSON.stringify(result)
    /SIMPLE MARKDOWN EXAMPLE/.test(found).should.be.ok
    /THIS IS A SIMPLE EXAMPLE OF/.test(found).should.be.ok
    /NUMBERED LISTS/.test(found).should.be.ok
    done()

  it 'operates on meta-data too', (done)->
    SIMPLE_MD_JSON = require( path.join(DATA_DIR,'simple-with-meta.json') )
    filter = new UpCaser()
    result = filter.execute(SIMPLE_MD_JSON)
    found = JSON.stringify(result)
    /ROD/.test(found).should.be.ok
    /WALDHOFF/.test(found).should.be.ok
    /OCTOBER/.test(found).should.be.ok
    /AN/.test(found).should.be.ok
    /EXAMPLE/.test(found).should.be.ok
    /WITH/.test(found).should.be.ok
    /META-DATA/.test(found).should.be.ok
    done()
