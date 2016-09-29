#!/usr/bin/env iced

markup = require './markup'
tags =
  div: '\n'
  p: '\n\n'
  hr: ' * * *\n\n'
mkElem = (tag, children = [], attrs = {}) ->
  children.push tags[tag] or ''
  children.join ''
format = (s) ->
  s = '\n' + mkElem null, markup.parse s, mkElem, (t) -> t
  s = s.replace /[\u201c\u201d]/g, '"'
  s = s.replace /[\u2018\u2019]/g, "'"

main = () ->
  {stdin, stdout} = process
  repl = require('readline').createInterface stdin, stdout
  repl.setPrompt '>'

  game = require('./game').newGame()
  display = () ->
    stdout.write format game.output
    if game.more then stdout.write '[press ENTER to continue]\n'
    else if game.over then repl.close()

  repl.on 'line', (line) ->
    game.parse line
    display()
    repl.prompt()

  repl.on 'close', () ->
    stdout.write '\n'
    stdin.destroy()

  display()
  repl.prompt()

main() if module? and require.main is module
