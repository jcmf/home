senc = (s) ->
  s = s.replace /[\\"]/g, '\\$&'
  s = s.replace /\n/g, '\\n'
  s = s.replace /[^ -~]/g, (m) ->
    hex = m.charCodeAt(0).toString(16)
    hex = "0#{hex}" while hex.length < 4
    if hex.length > 4 then hex = 'fffd'
    "\\u#{hex}"
  "\"#{s}\""

exports.encode = enc = (obj) ->
  t = typeof obj
  if t is 'string' then senc obj
  else if t is 'undefined' then throw new Error 'cannot encode undefined'
  else if obj is null or t != 'object' then JSON.stringify obj
  else if obj instanceof Array then "[#{(enc x for x in obj).join ','}]"
  else
    kk = (k for own k of obj).sort()
    fields = ("#{senc k}:#{enc obj[k]}" for k in kk)
    "{#{fields.join ','}}"
