fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
PandocFilter = require(path.join(LIB_DIR,'pandoc-filter'))
ExecSync     = require('execSync')
temp         = require('temp'); temp.track()
IS_WINDOWS   = require('os').platform().indexOf('win') is 0

class CodeBlockProcessor extends PandocFilter

  get_description:()->
    """
    Performs actions based on attributes specified in fenced code blocks.

      input-file  - replaces the body of the code block with the contents
                    of the specified file.
      input-cmd   - replaces the body of the code block with the output
                    of the specified command.
      exec        - when `true`, executes the body of the code block.
      output-file - writes the body of the code block to the specified file.
      output-cmd  - pipes the body of the code block as stdin to the
                    specified command.
      display     - when `false`, `none` or 'hide', removes the code
                    block from the output (sometimes useful with `exec`).
    """

  after_help:()->
    message = """

    Markup Examples:

      ``` {#theid .class1 .class2 input-file=SOME_FILE}
        Whatever you put here will be replaced by
        the contents of SOME_FILE.
      ```

      ``` {#theid .class2 input-cmd="uname -a"}
        Whatever you put here will be replaced by
        the output of `uname -a`.
      ```

      ``` {#theid .class2 output-cmd="wc"}
        Whatever you put here will be provided
        as input to `wc`.
      ```

      ``` {exec="true" display="false"}
        uptime | awk '{ print $6,$7,$8,$9,$10 }' > tempfile.txt
      ```

      ``` {input-file="tempfile.txt"}
        Whatever you put here will be replaced by
        the contents of `tempfile.txt`, created
        by the code block above.
      ```

    """
    console.log message
    super()

  write_to_temp_file: (data)=>
    temp_file = temp.path({suffix: '.pandox'})
    fs.writeFileSync(temp_file,data)
    return temp_file

  exec_with_stdin: (stdin,cmd)=>
    tmpfile = @write_to_temp_file(stdin)
    if IS_WINDOWS
      cmd = "type #{tmpfile} | #{cmd}"
    else
      cmd = "cat #{tmpfile} | #{cmd}"
    result = ExecSync.exec(cmd)
    temp.cleanup()
    return result

  pairs_to_map: (pairs)=>
    map = {}
    for pair in pairs
      map[pair[0]] = pair[1]
    return map

  map_to_pairs: (map)=>
    pairs = []
    for n,v of map
      pairs[n] = v
    return pairs

  action:(type,content,format,meta)=>
    DELETE_THESE = [ 'input-file', 'input-cmd', 'exec', 'output-file', 'output-cmd', 'display' ]
    if type is 'CodeBlock'
      nvps = @pairs_to_map(content[0][2])
      # given an input-file or input-cmd, replace the body of the code block
      if nvps['input-file']?
        content[1] = fs.readFileSync(nvps['input-file']).toString()
      else if nvps['input-cmd']?
        result = ExecSync.exec(nvps['input-cmd'])
        unless result?.code is 0
          console.error("WARNING: Error occurred running command \"#{nvps['input-cmd']}\".",result)
        else
          content[1] = result.stdout
      # given exec=true, execute the body of the code block
      if @is_true_string(nvps['exec'])
        result = ExecSync.exec(content[1])
        unless result?.code is 0
          console.error("WARNING: Error occurred running command \"#{content[1]}\".",result)
      # given an output-file or output-cmd, export the body of the code block
      if nvps['output-file']?
        fs.writeFileSync(nvps['output-file'],content[1])
      else if nvps['output-cmd']?
        result = @exec_with_stdin(content[1],nvps['output-cmd'])
        unless result?.code is 0
          console.error("WARNING: Error occurred running command \"#{nvps['output-cmd']}\".",result)
      # given display=none, hide the code block after processing
      if @is_false_string(nvps['display'])
        return []
      else
        for key in DELETE_THESE
          delete nvps[key]
        content[0][2] = @map_to_pairs(nvps)
        return { t:type, c:content }
    else
      return null

exports = module.exports = CodeBlockProcessor

if require.main is module
  (new CodeBlockProcessor()).main()
