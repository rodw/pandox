# Pandox

## A collection of PANDOc eXtensions

**Pandox** is a small collection of utilities that extend [John MacFarlane's Pandoc](http://johnmacfarlane.net/pandoc/), the "universal document converter".

### Using

#### The Command Line Interface

The *Pandox* extensions are typically invoked by piping a JSON-formatted AST (generated via `pandoc -t json FILENAME`) in as stdin, and piping the transformed JSON-formatted AST to another pandoc invocation for rendering.  For example:

```console
pandoc -t json README.md | coffee lib/up-caser.coffee | pandoc -f json -t html
```

will generate an HTML version of the `README.md` file, first applying the filter defined in `up-caser`.

The npm module includes directly executable scripts for each extension.  Hence:

```console
pandoc -t json README.md | pandox-up-caser | pandoc -f json -t html
```

also works (following `npm install -g pandox`).

#### The API (Code-Level) Interface

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

### The Extensions

#### CodeBlockProcessor

The `CodeBlockProcessor` extension adds several capabilities to the way in which *Pandoc* handles "fenced code blocks", such as:

    ```
    This is a sample of text inside a "fenced" code block.
    ```

*Pandoc* supports several parameters that control the way in which a code block is rendered.  The general form is:

    ```{#THE-ID .CLASS-ONE .CLASS-TWO NAME="VALUE" NAME2="VALUE2"}
    This is a sample of text inside a "fenced" code block.
    ```

where:

  * `#THE-ID` is used to identify the code block in things like HTML anchors and Latex cross-references.

  * `.CLASS-ONE`and `.CLASS-TWO` enumerate HTML classes to assign to the code block, and sometimes influence the rendering in other ways.  For example, adding the class `.numberLines` will cause *Pandoc* to number the lines in the code block when rendering it.

  * `NAME="VALUE"` and `NAME2="VALUE2"` enumerate name-value pairs that can be used to modify the way in which the code block is rendered. For example, adding the pair `startFrom=100` will cause *Pandoc* to number the lines starting with 100 rather than 1.

`CodeBlockProcessor` adds a few new parameters that can be controlled by name-value pairs.

  * `input-file` - replaces the body of the code block with the contents of the specified file.

  * `input-cmd` - replaces the body of the code block with output of the specified command..

  * `exec` - executes the body of the code block as it were a shell script

  * `output-file` - writes the body of the code block to the specified file.

  * `output-cmd` - pipes the body of the code block to the specified command.
