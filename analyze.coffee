#!/usr/bin/env iced

ips =
  '208.71.158.214': null  # Lakeshore
  '99.48.239.172': 'ellison' # Milwaukee WI Win7 FF12
  '67.170.107.119': 'maga' # Seattle WA Comcast Win7 FF3.6
  '24.147.11.151': 'Richard Smyth?' # 'Randolph MA Comcast Win7 FF12'
  '74.104.19.133': 'Lowell MA Verizon Win7 FF12'
  '75.15.23.182': 'Dan Fabulich'
  '75.34.189.61': 'Chicago IL SBC Win7 FF12'
  '2.123.107.92': 'Joey Jones' # Bradford UK Sky Win7 Opera9
  '148.87.67.202': 'Redwood City CA Oracle? WinXP FF10'

hash = null
exports.load = load = (cb) ->
  return cb hash if hash
  hash = {}

  host = 'ofb.net'
  path = 'zsavgam/log'

  child = require('child_process').spawn 'ssh', [host, "cat #{path}"]

  child.stdout.on 'end', -> cb hash
  child.on 'exit', (code) ->
    throw new Error "code=#{code}" if code
  child.stderr.on 'data', (data) -> throw new Error "stderr=#{data}"

  buf = ''
  lineNo = 0
  re = /^k=(\S*) ip=(\S*) user=(\S*) t=(\S*) v=(.*) ok$/
  child.stdout.on 'data', (data) ->
    buf += data.toString 'utf8'
    while 0 <= index = buf.indexOf '\n'
      line = buf.substr 0, index
      buf = buf.substr index+1
      lineNo += 1
      continue if not m = re.exec line
      k = m[1]
      v =
        lineNo: lineNo
        ip: m[2]
        user: m[3]
        t: 1000 * parseFloat m[4]
        vRaw: m[5]
      try
        v.v = JSON.parse v.vRaw
      catch e
        console.error "#{host}:#{path} line #{lineNo}: #{e}"
        v.parseError = e
        v.v = {}
        for fk in 'input output prev'.split /\s+/g
          if m = new RegExp("""."#{fk}":"([^"]*)".""").exec v.vRaw
            v.v[fk] = m[1]
      hash[k] = v if ips[v.ip] != null

count = (items) ->
  n = 0
  counts = {}
  for item in items
    if item of counts
      counts[item] += 1
    else
      counts[item] = 1
      n += 1
  return {n, counts}

pad = (s) ->
  s = s.toString()
  if s.length is 1 then "0#{s}" else s

exports.fmtTime = fmtTime = (t) ->
  d = new Date t
  "#{d.getFullYear()}-#{pad 1+d.getMonth()}-#{pad d.getDate()} #{pad d.getHours()}:#{pad d.getMinutes()}:#{pad d.getSeconds()}"

exports.trace = trace = (k) ->
  n = 0
  flags = {}
  while v = hash[k]
    output = v.v.output or ''
    flags.error = true if /Error:/.test output
    flags.undef = true if /undefined/.test output
    flags.hash = true if /#/.test output
    flags.over = true if v.v.over
    flags.parseError = true if v.parseError
    k = v.v.prev
    flags.incomplete = true if k and k not of hash
    n += 1
  result = n.toString()
  for s of flags
    result += " #{s}"
  return result

main = ->
  await load defer()

  {n: nPrevs, counts: prevs} = do ->
    count(prev for k, v of hash when prev = v.v.prev)
  ends = (k for k of hash when k not of prevs)
  ends.sort (a, b) -> hash[a].t - hash[b].t

  {n: nIps, counts: movesByIp} = do -> count(ip for k, v of hash when ip = v.ip)
  endsByIp = {}
  for k in ends
    v = endsByIp[hash[k].ip] or= []
    v.push k

  console.log("unique IPs: #{nIps}");
  console.log("unique moves: #{nPrevs + ends.length}");
  console.log("unique games: #{ends.length}");

  for ip, kk of endsByIp
    console.log "#{ips[ip] or ip}: #{kk.length} unique games"
    for k in kk
      console.log("  #{fmtTime hash[k].t} toastball.net/games/home/##{k} #{trace k}")

main() if require.main is module
