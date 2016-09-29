#!/usr/bin/env iced

escape = (text) ->
  text = text.replace /&/g, '&amp;'
  text = text.replace /</g, '&lt;'
  text = text.replace />/g, '&gt;'

quote = (text) ->
  text = escape text
  text = text.replace /"/g, '&quot;'
  "\"#{text}\""

elem = (tag, children = [], attrs = {}) ->
  attrList = (" #{k}=#{quote v}" for k, v of attrs)
  "<#{tag}#{attrList.join ''}>#{children.join ''}</#{tag}>"

{parse} = require './markup'
toHtml = (text) -> parse(text, elem, escape).join ''

assert = require 'assert'
ck = (from, to) -> assert.equal toHtml(from), to

ck '"Hello  World"', '<p>\u201cHello World\u201d</p>'
#ck "'its' vs 'it's'", '<p>\u2018its\u2019 vs \u2018it\u2019s\u2019</p>'
#ck 'Hi....', '<p>Hi\u2026.</p>'
#ck 'foo -- bar', '<p>foo\u2009\u2014\u2009bar</p>'
#ck 'foo-- bar', '<p>foo\u2014\u2009bar</p>'
#ck 'foo --bar', '<p>foo\u2009\u2014bar</p>'
#ck 'foo--bar', '<p>foo\u2014bar</p>'
ck '{hi}', '<p><a cmd="hi">hi</a></p>'
ck '{x|y}', '<p><a cmd="y">x</a></p>'
ck '{hi {x|y}}', '<p><a cmd="hi y">hi x</a></p>'
ck '{example.com}', '<p><a href="http://example.com/">example.com</a></p>'
ck '{hi|example.com}', '<p><a href="http://example.com/">hi</a></p>'
ck '{Jade|jade-lang.com}', '<p><a href="http://jade-lang.com/">Jade</a></p>'
ck '{yo|foo.com/bar}', '<p><a href="http://foo.com/bar">yo</a></p>'
ck '{oho|ftp://bla}', '<p><a href="ftp://bla">oho</a></p>'
ck '+ hi', '<p><div>hi</div></p>'
ck '.foo\n+ hi', '<p class="foo"><div>hi</div></p>'
ck '+.bar\n hi', '<p><div class="bar">hi</div></p>'
ck '.foo\n+.bar\n hi', '<p class="foo"><div class="bar">hi</div></p>'
ck 'foo\n+bar', '<p>foo<div>bar</div></p>'
ck '+ 1\n+ 2', '<p><div>1</div><div>2</div></p>'
ck '+\n  + 1a\n  + 1b\n+\n  + 2a\n+ 3', '<p><div><div>1a</div><div>1b</div></div><div><div>2a</div></div><div>3</div></p>'
ck '+\n  +\n    +1\n    +2', '<p><div><div><div>1</div><div>2</div></div></div></p>'
ck '*foo*', '<p><em>foo</em></p>'
ck '*foo* *bar*', '<p><em>foo</em> <em>bar</em></p>'
#ck '{Ornamental Alphabet -- 16th Century|commons.wikimedia.org/wiki/File:Ornamental_Alphabet_-_16th_Century.svg}', '<p><a href="http://commons.wikimedia.org/wiki/File:Ornamental_Alphabet_-_16th_Century.svg">Ornamental Alphabet — 16th Century</a></p>'
#ck '{Ornamental Alphabet -- 16th Century|commons.wikimedia.org/wiki/File:Ornamental*Alphabet*-*16th*Century.svg}', "<p>{Ornamental Alphabet — 16th Century|commons.wikimedia.org/wiki/File:Ornamental<em>Alphabet</em>-<em>16th</em>Century.svg}</p>"
ck '{xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', "<p>{xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</p>" # used to hang "forever"

ck '"foo {bar} baz"', '<p>\u201cfoo <a cmd="bar">bar</a> baz\u201d</p>'
ck 'foo\nbar\nbaz', '<p>foo bar baz</p>'

ck '* * *', '<hr></hr>'
ck '.cut\n* * *', '<hr class="cut"></hr>'

ck '{back|.}', '<p><a href=".">back</a></p>'
ck "{foo}'s ball", '<p><a cmd="foo">foo</a>\u2019s ball</p>'

ck '{someone@example.com}', '<p><a href="mailto:someone@example.com">someone@example.com</a></p>'
