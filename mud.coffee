#!/usr/bin/env iced

host = 'ifmud.port4000.com'
port = 4000
user = 'HomeBot'
pass = require('../mud/accounts').passwords[user]

assert = require 'assert'
assert.ok pass, "no password for user #{user}"

markup = require './markup'
tags =
  div: '\n'
  p: '\n\n'
  hr: '* * *\n\n'
mkElem = (tag, children = [], attrs = {}) ->
  children.push tags[tag] or ''
  children.join ''
format = (s) ->
  s = '\n' + mkElem null, markup.parse s, mkElem, (t) -> t
  s = s.replace /[\u201c\u201d]/g, '"'
  s = s.replace /[\u2018\u2019]/g, "'"

net = require 'net'
conn = net.connect port, host, -> console.log "connected to #{host}:#{port}"
conn.setEncoding 'utf8'

conn.on 'error', (err) ->
  event "connection to #{host}:#{port} failed: #{err}"
conn.on 'close', ->
  event "connection to #{host}:#{port} closed"
  process.exit()
setInterval((-> conn.write "\n"), 60000)

do ->
  buf = ''
  conn.on 'data', (data) ->
    buf += data
    while (index = buf.indexOf "\n") >= 0
      line = buf.substr 0, index
      buf = buf.substr index+1
      line = line.replace '\r', ''
      line = line.replace '\n', ''
      gotLine line

sendCmd = (cmd) ->
  console.log "< #{cmd}"
  conn.write "#{cmd}\n"

{newGame} = require './game'
game = null
history = []

gotLine = (line) ->
  console.log "- #{line}"
  m = /^\w+ (?:says|exclaims) \(to (?:[Nn]ode|[Hh]ome|[Ss]weetie)(?:[Bb]ot)?\), "(.*)"$/.exec line
  return if not m
  cmd = m[1]
  console.log "> #{cmd}"

  lcCmd = cmd.toLowerCase()
  if not game or (game.over and not game.more) or lcCmd is 'restart'
    sendCmd '"Starting a new game.  http://toastball.net/games/home/'
    game = newGame()
  else if lcCmd is 'quit'
    history.push game.saveData if game
    sendCmd '"Thanks for playing!'
    game = null
    return
  else if lcCmd is 'undo'
    if not history.length
      sendCmd '"Unable to undo.'
    else
      sendCmd '"Undoing one turn.'
      game = newGame history.pop()
  else
    history.push game.saveData if not game.more
    game.parse m[1]

  text = format game.output
  if game.more then text += '[more]'
  else if not game.over then text += '>'
  sendCmd "| #{s}" for s in text.split '\n'
  
  if game.over and not game.more
    sendCmd '"The links are a lie, but you can still restart, undo, or quit.'

sendCmd "connect #{user} #{pass}"
#sendCmd "@tel #19429" # TPV
sendCmd "@tel #4262" # Toyshop
