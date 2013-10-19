# Pandox
## A collection of PANDOc eXtensions

**Pandox** is a small collection of utilities that extend [John MacFarlane's Pandoc](http://johnmacfarlane.net/pandoc/), the "universal document converter".

*Pandox* processes the JSON-format abstact-syntax tree that *pandoc* can generate when given the `-t json` flag. Internally, this is quite similiar to (but not *exactly* the same as) the [*Pandoc* filters API](http://johnmacfarlane.net/pandoc/scripting.html) that exists for Haskell and Python.

If you'd like to try your hand at writing custom JavaScript-based *Pandoc* filters, simply extend the `PandocFilter` class or supply a filtering method. For example:

```js
var PandocFilter = require('pandoc-filter').PandocFilter

function upcase(key,value) {
  if(key==='Str') {
    return value.toUpperCase();
  } else {
    return value;
  }
}

var filter = new PandocFilter(upcase);
```

***HOWEVER*** one should not consider the API fully stable or settled just yet, so some of the semantics might change in future releases.  We follow the [semver version numbering conventions](http://semver.org/) so it should be easy to tell when a breaking change is introduced, but the `PandocFilter` API will probably change moderately frequently until we're more satisified with it.
