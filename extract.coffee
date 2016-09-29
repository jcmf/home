#!/usr/bin/env iced

fs = require 'fs'

{load} = require './analyze'
await load defer hash

for k in process.argv[2..]
  k = k.replace /.*#/, ''
  path = "#{k}.in"
  lines = []
  while k
    throw new Error "not found: ##{k}" if not v = hash[k]
    lines.unshift "#{v.v.input}\n" if v.v.input
    k = v.v.prev
  fs.writeFileSync path, lines.join ''
  console.log "wrote #{path}"
