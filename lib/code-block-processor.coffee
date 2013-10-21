fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR      = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
PandocFilter = require(path.join(LIB_DIR,'pandoc-filter')).PandocFilter
ExecSync     = require('execSync')
temp         = require('temp'); temp.track()
IS_WINDOWS   = require('os').platform().indexOf('win') is 0

class CodeBlockProcessor extends PandocFilter

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

  visit: (key,value)=>
    if value?.CodeBlock?
      nvps = @pairs_to_map(value.CodeBlock[0][2])
      # given an input-file or input-cmd, replace the body of the code block
      if nvps['input-file']?
        value.CodeBlock[1] = fs.readFileSync(nvps['input-file']).toString()
      else if nvps['input-cmd']?
        result = ExecSync.exec(nvps['input-cmd'])
        unless result?.code is 0
          console.error("WARNING: Error occurred running command \"#{nvps['input-cmd']}\".",result)
        else
          value.CodeBlock[1] = result.stdout
      # given exec=true, execute the body of the code block
      if nvps['exec']? and nvps['exec'].toUpperCase() in ['TRUE','T','YES','Y',1,'1','ON']
        result = ExecSync.exec(value.CodeBlock[1])
        unless result?.code is 0
          console.error("WARNING: Error occurred running command \"#{value.CodeBlock[1]}\".",result)
      # given an output-file or output-cmd, export the body of the code block
      if nvps['output-file']?
        fs.writeFileSync(nvps['output-file'],value.CodeBlock[1])
      else if nvps['output-cmd']?
        result = @exec_with_stdin(value.CodeBlock[1],nvps['output-cmd'])
        unless result?.code is 0
          console.error("WARNING: Error occurred running command \"#{nvps['output-cmd']}\".",result)
      # given display=none, hide the code block after processing
      if nvps['display']? and nvps['display'].toUpperCase() in ['NONE','HIDDEN','HIDE','NO','N','FALSE','F',0,'0','OFF']
        return null
      else
        return value
    else
      return value

exports = exports ? this
exports.CodeBlockProcessor = CodeBlockProcessor
