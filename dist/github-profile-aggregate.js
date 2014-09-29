(function() {
  var API_URL, DEFAULT_HEADERS, async, buildRequestObj, extend, fetchData, request, swiftArgs,
    __slice = [].slice;

  request = require('request');

  async = require('async');

  extend = require('extend');

  API_URL = 'https://api.github.com/users';

  DEFAULT_HEADERS = {
    'User-Agent': 'github-profile-aggregate'
  };

  buildRequestObj = function(url, headers) {
    return {
      url: "" + API_URL + "/" + url,
      json: true,
      headers: headers
    };
  };

  fetchData = function(type) {
    if (type == null) {
      type = '';
    }
    return function(username, headers, cb) {
      var data;
      data = buildRequestObj("" + username + "/" + type, headers);
      return request.get(data, function(error, res, body) {
        if (res.statusCode === 404) {
          return cb('User not found', null);
        }
        if (res.statusCode === 403) {
          return cb('Forbidden (probably rate limited)', null);
        }
        return cb(error, body);
      });
    };
  };

  swiftArgs = function(opts, cb) {
    var hasOpts;
    hasOpts = typeof opts !== 'function';
    return {
      headers: hasOpts ? opts : {},
      cb: hasOpts ? cb : opts
    };
  };

  module.exports = function() {
    var args, cb, headers, username, _ref;
    username = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    _ref = swiftArgs.apply(null, args), headers = _ref.headers, cb = _ref.cb;
    if (!username) {
      throw new Error('No username defined');
    }
    if (!cb) {
      throw new Error('No callback defined');
    }
    headers = extend({}, DEFAULT_HEADERS, headers);
    return async.map([fetchData(), fetchData('subscriptions'), fetchData('gists')], function(fn, next) {
      return fn(username, headers, next);
    }, function(err, _arg) {
      var gists, subscriptions, user;
      user = _arg[0], subscriptions = _arg[1], gists = _arg[2];
      return cb(err, {
        user: user,
        subscriptions: subscriptions,
        gists: gists
      });
    });
  };

}).call(this);
