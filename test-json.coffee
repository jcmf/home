#!/usr/bin/env iced

assert = require 'assert'
{encode} = require './json'
ck = (from, to) -> assert.equal encode(from), to
ck null, 'null'
ck true, 'true'
ck false, 'false'
ck 123, '123'
ck 456.789, '456.789'
ck '', '""'
ck 'foo', '"foo"'
ck '"foo"', '"\\"foo\\""'
ck '\x00\t\r\n\u1234\u2028', '"\\u0000\\u0009\\u000d\\n\\u1234\\u2028"'
ck ['\x00\t\r\n\u1234\u2028'], '["\\u0000\\u0009\\u000d\\n\\u1234\\u2028"]'
ck {'\t':{'\t':null}}, '{"\\u0009":{"\\u0009":null}}'
ck [], '[]'
ck [5, 7, 12], '[5,7,12]'
ck {}, '{}'
ck {A: 1, B: 2, a: 3, b: 4}, '{"A":1,"B":2,"a":3,"b":4}'
ck {b: 4, a: 3, B: 2, A: 1}, '{"A":1,"B":2,"a":3,"b":4}'
ck [{A: 1, B: 2, a: 3, b: 4}], '[{"A":1,"B":2,"a":3,"b":4}]'
ck [{b: 4, a: 3, B: 2, A: 1}], '[{"A":1,"B":2,"a":3,"b":4}]'

class Foo
  bar: true
  baz: -> "Hello World"
foo = new Foo
ck foo, '{}'
ck foo.bar, 'true'
ck foo.baz(), '"Hello World"'
foo.bar = true
foo.qux = 456
ck foo, '{"bar":true,"qux":456}'
delete foo.bar
ck foo.bar, 'true'
ck foo, '{"qux":456}'
assert.throws -> encode undefined
assert.throws -> encode foo: undefined
assert.throws -> encode [undefined]
