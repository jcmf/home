#!/usr/bin/env iced

assert = require 'assert'
{sha256, BASE32} = require './sha256'

assert.equal(sha256(''),
  'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855')
assert.equal(sha256('The quick brown fox jumps over the lazy dog'),
  'd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592')
assert.equal(sha256('The quick brown fox jumps over the lazy dog.'),
  'ef537f25c895bfa782526529a9b63d97aa631564d5d789c2b765448c8635fb6c')
assert.equal(sha256('This is a test.'),
  'a8a2f6ebe286697c527eb35a58b5539532e9b3ae3b64d4eb0a46fb657b41562c')
assert.equal(sha256('This is a test.\n'),
  '11586d2eb43b73e539caa3d158c883336c0e2c904b309c0c5ffe2c9b83d562a1')
assert.equal(sha256('data'),
  '3a6eb0790f39ac87c94f3856b2dd2c5d110e6811602261a9a923d3bb23adc8b7')

assert.equal(sha256('data', BASE32),
  '79qb0x8f76p8fjaf71bb5q9cbm8gvt0hc0h63ad94f9up8wds2ug')
assert.equal(sha256('4265222', BASE32),
  'fy87bg7393rjef1tk5e4ha1k6n2f4d3665renmk7uk2f7jydntdg')
assert.equal(sha256('4600132', BASE32),
  'fy87bg739c9jfkqytnqeengnm7snc4bthtby0s5sdktcx2c86w5g')
