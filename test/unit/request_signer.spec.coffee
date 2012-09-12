AWS = require('../../lib/core')
require('../../lib/services/dynamodb')

buildRequest = ->
  req = new AWS.DynamoDB.HttpRequest();
  req.endpoint = {region: 'region', scheme: 'https', host: 'localhost', port: 443}
  builder = new AWS.JsonRequestBuilder({ n:'ListTables' })
  builder.populateRequest({ foo: 'bar' },req)
  return req

buildSigner = (request) ->
  return new AWS.SignatureV4Signer(request || buildRequest())

describe 'AWS.SignatureV4Signer', ->
  date = new Date(1935346573456)
  datetime = AWS.util.date.getISODateString(date)
  creds = {accessKeyId: 'akid', secretAccessKey: 'secret', sessionToken: 'session'}
  signature = '3e5fc3cac486c843144891dc0be6f8c2e89fe1d7b542b3722f65d1b351f43ea2'
  authorization = 'AWS4-HMAC-SHA256 Credential=akid/20310430/region/dynamodb/aws4_request, ' +
    'SignedHeaders=content-length;content-type;date;host;user-agent;x-amz-date;x-amz-security-token;x-amz-target, ' +
    'Signature=' + signature
  signer = null

  beforeEach ->
    signer = buildSigner()
    signer.addHeaders(creds, datetime)

  describe 'constructor', ->
    it 'can build a signer for a request object', ->
      req = buildRequest()
      signer = buildSigner(req)
      expect(signer.request).toBe(req)

  describe 'addAuthorization', ->
    headers = {
      'Content-Type': 'application/x-amz-json-1.0',
      'Content-Length': 13,
      'X-Amz-Target': 'DynamoDB_20111205.ListTables',
      'Host': 'localhost',
      'Date': datetime,
      'X-Amz-Date': datetime,
      'X-Amz-Security-Token' : 'session',
      'Authorization' : authorization
    }

    beforeEach -> signer.addAuthorization(creds, date)

    for key, value of headers
      it 'should add ' + key + ' header', ->
        key = this.description.match(/(\S+) header/)[1]
        expect(signer.request.headers[key]).toEqual(headers[key])

  describe 'authorization', ->
    it 'should return authorization part for signer', ->
      expect(signer.authorization(creds, datetime)).toEqual(authorization)

  describe 'signature', ->
    it 'should generate proper signature', ->
      expect(signer.signature(creds, datetime)).toEqual(signature)

  describe 'stringToSign', ->
    it 'should sign correctly generated input string', ->
      expect(signer.stringToSign(datetime)).toEqual 'AWS4-HMAC-SHA256\n' +
        datetime + '\n' +
        '20310430/region/dynamodb/aws4_request\n' +
        signer.hexEncodedHash(signer.canonicalString())

  describe 'canonicalHeaders', ->
    it 'should return headers', ->
      expect(signer.canonicalHeaders()).toEqual [
        'content-length:13',
        'content-type:application/x-amz-json-1.0',
        'date:' + datetime,
        'host:localhost',
        'user-agent:aws-sdk-js/' + AWS.VERSION,
        'x-amz-date:' + datetime,
        'x-amz-security-token:session',
        'x-amz-target:DynamoDB_20111205.ListTables'
      ].join('\n')

    it 'should ignore Authorization header', ->
      signer.request.headers = {'Authorization': 'foo'}
      expect(signer.canonicalHeaders()).toEqual('')

    it 'should lowercase all header names (not values)', ->
      signer.request.headers = {'FOO': 'BAR'}
      expect(signer.canonicalHeaders()).toEqual('foo:BAR')

    it 'should sort headers by key', ->
      signer.request.headers = {abc: 'a', bca: 'b', Qux: 'c', bar: 'd'}
      expect(signer.canonicalHeaders()).toEqual('abc:a\nbar:d\nbca:b\nqux:c')

    it 'should compact multiple spaces in keys/values to a single space', ->
      signer.request.headers = {'Header': 'Value     with  Multiple   \t spaces'}
      expect(signer.canonicalHeaders()).toEqual('header:Value with Multiple spaces')

    it 'should strip starting and end of line spaces', ->
      signer.request.headers = {'Header': ' \t   Value  \t  '}
      expect(signer.canonicalHeaders()).toEqual('header:Value')