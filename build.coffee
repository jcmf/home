#!/usr/bin/env iced

errPath = 'error.jade'
inPath = 'index.jade'
outPath = 'index.html'
tmpPath = "#{outPath}.tmp"
ctypes =
  jpg: 'image/jpeg'
  woff: 'application/x-font-woff'

fs = require 'fs'
read = (path, enc = 'utf8') -> fs.readFileSync path, enc
url = (path, ctype) ->
  ctype or= ctypes[/\.([^.]+)$/.exec(path)?[1]] or 'application/octet-stream'
  "data:#{ctype};base64,#{read path, 'base64'}"

vm = require 'vm'
iced = require 'iced-coffee-script'

tools =
  read: read
  url: url
  bg: (name, path) ->
    path or= "#{name}.jpg"
    ".#{name}{background-image:url(#{url path})}"
  font: (f, path, etc = '') ->
    path or= "#{f.replace /\s+/g, ''}.woff"
    "@font-face{font-family:'#{f}';src:url(#{url path}) format('woff');#{etc}}"
  load: (name) ->
    src = read path = "#{name}.coffee"
    js = iced.compile src, filename: path
    sandbox = exports: {}
    vm.runInNewContext js, sandbox, path
    return sandbox.exports
  script: (name, uglify) ->
    seen = {}
    include = (name) ->
      k = "./#{name}"
      return null if k of seen
      seen[k] = true

      src = read path = "#{name}.coffee"
      js = """
        // FILE: #{path}
        (function() { var exports = require[#{JSON.stringify k}] = {};
        #{iced.compile src, filename: path, bare: true, runtime: 'inline'}
        }).call(this);

        """

      re = /// (?: ^ | \s) require \s* \(? \s* ["'] \./ ([^ \s '"]+) ["'] ///g
      result = (include m[1] while m = re.exec src)
      result.push js
      return result.join ''

    js = """
      (function() { var require = function(k) { return require[k]; };

      #{include name}}).call(this);
      """
    js = require('uglify-js') js if uglify
    return js

template = (path, opts) ->
  t = require('jade').compile read(path), filename: path
  return t opts

build = ->
  process.stderr.write 'building... '
  fs.writeFileSync tmpPath,
    try
      template inPath, tools
    catch e
      template errPath, {e}
  fs.renameSync tmpPath, outPath
  process.stderr.write '\r\x1b[K'

prev = null
check = -> while true
  curParts = for name in fs.readdirSync('.').sort()
    continue if name[0] is '.'
    continue if name is outPath
    try
      "#{name}\n#{fs.statSync(name).mtime.getTime()}"
    catch e
      continue
  cur = curParts.join '\n'
  return if cur is prev
  prev = cur
  build()

check()
fs.watch '.', check
