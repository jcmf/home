exports.parse = (text, mkNode, mkText) ->
  return [] if not text
  text = text.replace /\r\n/g, '\n'

  parseOutIn = (re, text, mkOutList, mkInItem) ->
    idx = 0
    result = []
    while m = re.exec text
      result.push item for item in mkOutList text.substring idx, m.index
      idx = re.lastIndex
      result.push mkInItem m
    result.push item for item in mkOutList text.substring idx
    return result

  parsePunct = (t) ->
    return [] if not t
    t = t.replace /"([^"]+)"/g, '\u201c$1\u201d' # ldquo $1 rdquo
    t = t.replace /^"/g, '\u201c' # ldquo
    t = t.replace /"$/g, '\u201d' # rdquo
#    t = t.replace /(^|[\[\(>" ])'/g, '$1\u2018' # lsquo
    t = t.replace /'/g, '\u2019' # rsquo
#    t = t.replace /\.{3}/g, '\u2026' # hellip
#    t = t.replace /\ --\ /g, '\u2009\u2014\u2009' # thinsp mdash thinsp
#    t = t.replace /--\ /g, '\u2014\u2009' # mdash thinsp
#    t = t.replace /\ --/g, '\u2009\u2014' # thinsp mdash
#    t = t.replace /--/g, '\u2014' # mdash
    [mkText t]

  parseLinks = (text) ->
    parseOutIn /\{((?:[^{}]|\{[^{}]*\})+)\}/g, text, parsePunct, (m) ->
      t = m[1]
      re = /\{?([^{}|]*)\|([^{}|]*)\}?/g
      raw = t.replace re, '$2'
      mkNode 'a', parsePunct(t.replace re, '$1'),
        if /^\w+:|^\./.test raw then href: raw
        else if /^[\w-]+\.\w[\w\.-]+$/.test raw then href: "http://#{raw}/"
        else if /^[\w-]+\.\w/.test raw then href: "http://#{raw}"
        else if /^[\w+.-]+@[\w+.-]+$/.test raw then href: "mailto:#{raw}"
        else cmd: raw

  parseSpans = (text) ->
    text = text.replace /^\s+/, ''
    text = text.replace /\s+$/, ''
    text = text.replace /\s+/g, ' '
    parseOutIn /\*([^\s*](?:[^*]+[^\s*])?)\*/g, text, parseLinks, (m) ->
      mkNode 'em', parseLinks m[1]

  applyClass = (text) ->
    clattrs = {}
    text = text.replace /^\.([\w-.]+)(?:\n|$)/, (t, m) ->
      clattrs.class = m.replace /\./g, ' '
      return ''
    return [text, clattrs]

  parseDivs = (text) ->
    parseOutIn /(?:^|\n)\+([^\n]*(?:\n [^\n]*)*)/g, text, parseSpans, (m) ->
      [content, dattrs] = applyClass m[1]
      mm = content.match /\n +/g
      if mm
        min = mm[0]
        for m in mm
          min = m if m.length < min.length
        content = content.replace new RegExp(min, 'g'), '\n'
      mkNode 'div', parseDivs(content), dattrs

  for pp in text.split /\n\n+/
    continue if /^\s*$/.test pp
    pp = pp.replace /^\n/, ''
    pp = pp.replace /\s+$/, ''
    [pp, attrs] = applyClass pp
    if /^(?:-|\* ?){3,}$/.test pp then mkNode 'hr', [], attrs
    else mkNode 'p', parseDivs(pp), attrs
