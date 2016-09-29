#!/usr/bin/env iced

fs = require 'fs'
{newGame} = require './game'
markup = require './markup'

hideFields = {}
do ->
  for k in 'input output saveData hash prev ver'.split ' '
    hideFields[k] = true

format = (s) ->
  warnings = []
  mkText = (s) ->
    quoted = JSON.stringify s
    if m = /(["'{}]|object Object|undefined|(?:^|\s)[@#][^\s.])/.exec s
      msg = "WARNING: suspicious string #{m[1]} in #{quoted}"
      warnings.push msg
      console.error msg
    return quoted
  mkElem = (tag, children = [], attrs = {}) ->
    """
    #{tag}#{(" #{k}=#{JSON.stringify v}" for k, v of attrs).join ''}
    #{("  #{c.replace(/\n/g, '\n  ')}" for c in children).join '\n'}
    """

  parsed = markup.parse game.output, mkElem, mkText
  return parsed.concat(warnings).join '\n'

progress = (msg) ->
  process.stderr.write """\r#{if msg then "#{msg} " else ''}\x1b[K"""

for inPath in fs.readdirSync('.').sort()
  outPath = inPath.replace /\.in$/, '.out'
  continue if inPath is outPath

  progress inPath
  game = newGame()
  result = []

  lineNo = 0
  for line in fs.readFileSync(inPath, 'utf8').split '\n'
    lineNo++
    progress "#{inPath}:#{lineNo}"
    continue if not line or line[0] is '#'
    result.push "#{lineNo}> #{line}\n"

    if game.over
      result.push '!!DONE!!\n'
      break

    game.parse line
    while game.more
      result.push format game.output
      result.push '\n--MORE--\n'
      game.parse()
    result.push format game.output
    for k in (k for own k of game when not hideFields[k]).sort()
      result.push "\n#{k} = #{JSON.stringify game[k]}"
    result.push '\n'
    result.push '--DONE--\n' if game.over

  tmpPath = "#{outPath}.tmp"
  progress tmpPath
  fs.writeFileSync tmpPath, result.join ''
  progress outPath
  fs.renameSync tmpPath, outPath
  progress()

