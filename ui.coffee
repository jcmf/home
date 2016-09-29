error = info = (args...) -> try console.log args...

storage = null
do ->
  url = 'http://toastball.net/games/zsavgam'
  prefix = 'zsavgam.'

  cache = {}
  localSet = (k, v) ->
    cache[k] = v
    try window.localStorage[prefix + k] = v
    catch e
      error "unable to store #{k} in localStorage: #{e}"
      error e

  storage =
    set: (k, v) ->
      localSet k, v
      $.ajax url,
        data: {k, v}
        dataType: 'jsonp'

    get: (k, cb) ->
      v = cache[k]
      return cb v if v
      try v = window.localStorage[prefix + k]
      return cb v if v
      $.ajax url,
        data: {k}
        dataType: 'jsonp'
        success: (data) ->
          for dk, dv of data
            localSet dk, dv
          cb cache[k]

elem = (tag, children, attrs) ->
  result = window.document.createElement tag
  result.setAttribute k, v for k, v of attrs or {}
  c and result.appendChild c for c in children or []
  return result
text = (s) -> window.document.createTextNode s

div = (cl, children, attrs = {}) ->
  attrs['class'] = cl
  return elem 'div', children, attrs
span = (cl, s, attrs = {}) ->
  attrs['class'] = cl
  return elem 'span', [text(s)], attrs

fixElem = (tag, children, attrs) ->
  if tag is 'a' and attrs and cmd = attrs.cmd
    tag = 'span'
    attrs.class = 'link'
    delete attrs.cmd
  if attrs.href is '.'
    m = /([^\/]+)$/.exec window.location?.pathname or ''
    if m then attrs.href = m[1]
  else if attrs.href
    attrs.target or= '_blank'
  result = elem tag, children, attrs
  if cmd then $(result).click ->
    runCmd cmd
    return true
  return result

markup = require './markup'
format = (s) -> markup.parse s, fixElem, text

resize = ->
  iw = $('#output').width()
  iw -= $('#prompt').outerWidth()
  input.filter(':visible').width iw
  return true

setHash = (hash) ->
  window.location.hash = hash
  hashchange()

renderTurn = (game) ->
  rewind = null
  if hash = game.prev
    rewind = div 'rewind', [text '[undo]']
    $(rewind).click ->
      setHash hash
      return true

  div 'turn',
  [
    if not game.input? then null
    else div 'request',
      [
        rewind
        span 'prompt', promptText
        span 'cmd', game.input
      ]
    div 'response', format game.output
  ]

showTurn = (turn) ->
  form.toggle not game.more and not game.over
  more.toggle not not game.more
  resize()

  minPos = $(turn).offset().top
  maxPos = $(window.document).height() - $(window).height()
  window.scrollTo 0, Math.min minPos, maxPos
  input.focus() if not game.more and minPos >= maxPos

{newGame} = require './game'
game = null

restore = (hash) ->
  return if game?.hash is hash

  hash = hash.toLowerCase()
  hash = hash.replace /o/g, '0'
  hash = hash.replace /[il]/g, '1'
  hash = hash.replace /z/g, '2'
  hash = hash.replace /[^0-9a-z]+/g, ''

  $(output).empty()

  $('#game').hide()
  $('#404').hide()
  $('#loading').show()
  $('#credits-body').hide()
  $('#notes-body').hide()
  $('#intro-body').show()
  $('#intro').show()

  game = firstTurn = bottomTurn = null

  while hash
    await storage.get hash, defer saveData
    if not saveData
      info "not found: [#{hash}]"
      break

    g = null
    try
      g = newGame saveData, hash
      game or= g
    catch e
      error "error restoring #{hash}"
      error e

    break if not g

    output.insertBefore turn = renderTurn(g), firstTurn
    firstTurn = turn
    bottomTurn or= turn

    hash = g.prev

  $('#loading').hide()

  if game
    $('#game').show()
    $('#intro').hide()
    showTurn bottomTurn
  else
    $('#404').show()

hashchange = ->
  hash = window.location.hash.replace '#', ''
  credits = hash is 'credits'
  notes = hash is 'notes'
  return restore hash if hash and hash != '#' and not credits and not notes

  $('#game').hide()
  $('#output').empty()

  $('#intro-body').toggle not credits and not notes
  $('#credits-body').toggle credits
  $('#notes-body').toggle notes
  $('#loading').hide()
  $('#404').hide()
  $('#intro').show()

  window.scrollTo 0, 0
  game = null

runCmd = (cmd) ->
  if not game
    game = newGame()
    $('#intro').hide()
    $('#game').show()
  else
    return if game.over and not game.more
    game.parse cmd

  storage.set game.hash, game.saveData

  setHash game.hash

  output.appendChild turn = renderTurn game
  showTurn turn

submit = ->
  runCmd input.val()
  input.val ''

promptText = input = output = more = form = null
window.onload = ->
  promptText = $('#prompt').text()
  $('#credits').replaceWith elem 'div', format(require('./meta').credits),
    id: 'credits'
  $('#notes').replaceWith elem 'div', format(require('./meta').notes),
    id: 'notes'

  do ->
    m = /([^\/]+)$/.exec window.location?.pathname or ''
    if m then $('.top').attr 'href', m[1]

    host = window.location?.hostname or ''
    host = host.toLowerCase()
    $('.update').hide() if window.location.href is $('.update a').attr 'href'

  input = $ 'input'
  input.on 'speechchange webkitspeechchange', ->
    submit()
    return true
  input.focus()

  byId = (id) -> window.document.getElementById id
  output = byId 'output'

  form = $('#form')
  form.submit (event) ->
    event.preventDefault()
    submit()
    return false

  more = $('#more')
  more.click ->
    runCmd()
    return true
  $('.start').click ->
    runCmd()
    return true

  $(window).on 'hashchange', (event) ->
    event.preventDefault()
    hashchange()
    return true

  $(window).keypress (event) ->
    if not game or game.more
      event.preventDefault()
      runCmd()
      return false
    input.focus()
    return true

  $(window).resize resize
  resize()
  hashchange()

  $('.start').show()

  return true
