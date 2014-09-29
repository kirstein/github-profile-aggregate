sinon   = require 'sinon'
request = require 'request'
assert  = require 'assert'

profileAggregrate = require "#{process.cwd()}/src/github-profile-aggregate"

describe 'github-profile-aggregate', ->

  it 'should throw if no username is defined', ->
    (-> profileAggregrate(null, ->)).should.throw 'No username defined'

  it 'should throw if no cb is defined', ->
    (-> profileAggregrate('asd')).should.throw 'No callback defined'

  describe 'api', ->
    it 'should trigger the callback if its the second argument', sinon.test ->
      spy = sinon.spy()
      @stub(request, 'get').yields null, {}, {}
      profileAggregrate 'kirstein', spy
      spy.called.should.be.ok

    it 'should trigger the callback if its the third second argument', sinon.test ->
      spy = sinon.spy()
      @stub(request, 'get').yields null, {}, {}
      profileAggregrate 'kirstein', {}, spy
      spy.called.should.be.ok

  describe 'headers', ->
    it 'should pass userAgent', sinon.test ->
      @stub(request, 'get').yields null, {}, {}
      headers = 'User-Agent': 123
      profileAggregrate 'kirstein', headers, ->
        userAgent = request.get.args[0][0].headers['User-Agent']
        userAgent.should.eql 123

    it 'should pass anything else', sinon.test ->
      @stub(request, 'get').yields null, {}, {}
      headers = 'sd': 123
      profileAggregrate 'kirstein', headers, ->
        headers = request.get.args[0][0].headers
        headers.sd.should.eql 123

  describe 'user data fetching', ->
    it 'should trigger the callback', sinon.test ->
      @stub(request, 'get').yields null, {}, {}
      spy = sinon.spy()
      profileAggregrate 'kirstein', spy
      spy.called.should.be.ok

    it 'should make a request asking for github user info', sinon.test ->
      @stub(request, 'get').yields null, {}, {}
      profileAggregrate 'kirstein', ->
        request.get.args[0][0].url.should.eql 'https://api.github.com/users/kirstein/'
        request.get.called.should.be.ok

    it 'should make a request asking for users subscriptions', sinon.test ->
      @stub(request, 'get').yields null, {}, {}
      profileAggregrate 'kirstein', ->
        request.get.args[1][0].url.should.eql 'https://api.github.com/users/kirstein/subscriptions'
        request.get.called.should.be.ok

    it 'should make a request asking for users gists', sinon.test ->
      @stub(request, 'get').yields null, {}, {}
      profileAggregrate 'kirstein', ->
        request.get.args[2][0].url.should.eql 'https://api.github.com/users/kirstein/gists'
        request.get.called.should.be.ok

    it 'should not make request asking for subscriptions if user fails', sinon.test ->
      @stub(request, 'get').yields 'wat', {}, null
      profileAggregrate 'kirstein', (error, data) ->
        assert request.get.args[1] is undefined

    it 'should return error if the request errors', sinon.test ->
      @stub(request, 'get').yields 'wat', {}, null
      profileAggregrate 'kirstein', (error, data) ->
        error.should.eql 'wat'

    it 'should return "Does not exist" if user does not exist', sinon.test ->
      @stub(request, 'get').yields null, { statusCode: 404 }, null
      profileAggregrate 'kirstein123', (error, data) ->
        error.should.eql 'User not found'

    it 'should return "Forbidden" if user does not exist', sinon.test ->
      @stub(request, 'get').yields null, { statusCode: 403 }, null
      profileAggregrate 'kirstein', (error, data) ->
        error.should.eql 'Forbidden (probably rate limited)'

  describe 'aggregating', ->
    gists = require './fixtures/gists.json'
    user  = require './fixtures/user.json'
    subs  = require './fixtures/subscriptions.json'

    beforeEach ->
      stub = sinon.stub request, 'get'
      stub.onFirstCall().yields null, {}, user
      stub.onThirdCall().yields null, {}, gists
      stub.onSecondCall().yields null, {}, subs

    afterEach ->
      request.get.restore()

    it 'should return user data', ->
      profileAggregrate 'kirstein', (error, { user }) ->
        user.should.eql user

    it 'should return subscriptions data', ->
      profileAggregrate 'kirstein', (error, { subscriptions }) ->
        subscriptions.should.eql subs

    it 'should return gists data', ->
      profileAggregrate 'kirstein', (error, { gists }) ->
        gists.should.eql gists
