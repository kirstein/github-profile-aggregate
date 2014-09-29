request = require 'request'
async   = require 'async'
extend  = require 'extend'

API_URL         = 'https://api.github.com/users'
DEFAULT_HEADERS = 'User-Agent': 'github-profile-aggregate'

buildRequestObj = (url, headers) ->
  url: "#{API_URL}/#{url}"
  json: true
  headers: headers

fetchData = (type = '') -> (username, headers, cb) ->
  data = buildRequestObj "#{username}/#{type}", headers
  request.get data, (error, res, body) ->
    return cb 'User not found', null if res.statusCode is 404
    return cb 'Forbidden (probably rate limited)', null if res.statusCode is 403
    cb error, body

swiftArgs = (opts, cb) ->
  hasOpts = typeof opts isnt 'function'
  headers : if hasOpts then opts else {}
  cb      : if hasOpts then cb else opts

module.exports = (username, args...) ->
  { headers, cb } = swiftArgs args...
  throw new Error 'No username defined' unless username
  throw new Error 'No callback defined' unless cb

  headers = extend {}, DEFAULT_HEADERS, headers

  async.map [
    fetchData()
    fetchData('subscriptions')
    fetchData('gists')
  ], (fn, next) ->
    fn username, headers, next
  , (err, [ user, subscriptions, gists ]) ->
    cb err, { user, subscriptions, gists }
