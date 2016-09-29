prep = (str) ->
  pr = for ii in [0..((str.length+8) | 0x3f)] by 4
    (
      (((str.charCodeAt(ii  ) or 0) & 0xff) << 24) |
      (((str.charCodeAt(ii+1) or 0) & 0xff) << 16) |
      (((str.charCodeAt(ii+2) or 0) & 0xff) <<  8) |
      (((str.charCodeAt(ii+3) or 0) & 0xff)      )
    )
  pr[str.length >> 2] |= 0x80 << ((3-(str.length & 3)) << 3)
  pr[pr.length - 1] = str.length << 3
  return pr

getBit = (ww, bit) -> ((ww[bit >> 5] or 0) >> (31-(bit & 0x1f))) & 1
getBits = (ww, b0, nb) ->
  result = 0
  for bit in [b0...(b0+nb)]
    result = (result << 1) | getBit(ww, bit)
  return result

exports.HEX = HEX =
  bits: 4
  digits: '0123456789abcdef'

exports.BASE32 =
  bits: 5
  digits: '0123456789abcdefghjkmnpqrstuvwxy'

encode = (ww, base = HEX) ->
  dd = for b0 in [0...(ww.length << 5)] by base.bits
    base.digits[getBits(ww, b0, base.bits)]
  return dd.join('')

k = [0x428a2f98|0, 0x71374491|0, 0xb5c0fbcf|0, 0xe9b5dba5|0,
     0x3956c25b|0, 0x59f111f1|0, 0x923f82a4|0, 0xab1c5ed5|0,
     0xd807aa98|0, 0x12835b01|0, 0x243185be|0, 0x550c7dc3|0,
     0x72be5d74|0, 0x80deb1fe|0, 0x9bdc06a7|0, 0xc19bf174|0,
     0xe49b69c1|0, 0xefbe4786|0, 0x0fc19dc6|0, 0x240ca1cc|0,
     0x2de92c6f|0, 0x4a7484aa|0, 0x5cb0a9dc|0, 0x76f988da|0,
     0x983e5152|0, 0xa831c66d|0, 0xb00327c8|0, 0xbf597fc7|0,
     0xc6e00bf3|0, 0xd5a79147|0, 0x06ca6351|0, 0x14292967|0,
     0x27b70a85|0, 0x2e1b2138|0, 0x4d2c6dfc|0, 0x53380d13|0,
     0x650a7354|0, 0x766a0abb|0, 0x81c2c92e|0, 0x92722c85|0,
     0xa2bfe8a1|0, 0xa81a664b|0, 0xc24b8b70|0, 0xc76c51a3|0,
     0xd192e819|0, 0xd6990624|0, 0xf40e3585|0, 0x106aa070|0,
     0x19a4c116|0, 0x1e376c08|0, 0x2748774c|0, 0x34b0bcb5|0,
     0x391c0cb3|0, 0x4ed8aa4a|0, 0x5b9cca4f|0, 0x682e6ff3|0,
     0x748f82ee|0, 0x78a5636f|0, 0x84c87814|0, 0x8cc70208|0,
     0x90befffa|0, 0xa4506ceb|0, 0xbef9a3f7|0, 0xc67178f2|0]

ror = (x, y) -> (x >>> y) | (x << (32-y))

exports.sha256 = sha256 = (str, base) ->
  pr = prep str

  h0 = 0x6a09e667|0
  h1 = 0xbb67ae85|0
  h2 = 0x3c6ef372|0
  h3 = 0xa54ff53a|0
  h4 = 0x510e527f|0
  h5 = 0x9b05688c|0
  h6 = 0x1f83d9ab|0
  h7 = 0x5be0cd19|0

  for ii in [0...pr.length] by 16
    w = pr[ii..(ii+15)]

    for jj in [16..63]
      s0 = ror(w[jj-15], 7) ^ ror(w[jj-15], 18) ^ (w[jj-15] >>> 3)
      s1 = ror(w[jj-2], 17) ^ ror(w[jj-2], 19) ^ (w[jj-2] >>> 10)
      w[jj] = (w[jj-16] + s0 + w[jj-7] + s1) >> 0

    [a, b, c, d, e, f, g, h] = [h0, h1, h2, h3, h4, h5, h6, h7]

    for jj in [0..63]
      s0 = ror(a, 2) ^ ror(a, 13) ^ ror(a, 22)
      maj = (a&b) ^ (a&c) ^ (b&c)
      t2 = (s0 + maj) | 0
      s1 = ror(e, 6) ^ ror(e, 11) ^ ror(e, 25)
      ch = (e&f) ^ (~e & g)
      t1 = (h + s1 + ch + k[jj] + w[jj]) | 0
      h = g
      g = f
      f = e
      e = (d + t1) | 0
      d = c
      c = b
      b = a
      a = (t1 + t2) | 0

    h0 = (h0 + a) | 0
    h1 = (h1 + b) | 0
    h2 = (h2 + c) | 0
    h3 = (h3 + d) | 0
    h4 = (h4 + e) | 0
    h5 = (h5 + f) | 0
    h6 = (h6 + g) | 0
    h7 = (h7 + h) | 0

  return encode([h0, h1, h2, h3, h4, h5, h6, h7], base)
