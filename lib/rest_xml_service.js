/**
 * Copyright 2011-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"). You
 * may not use this file except in compliance with the License. A copy of
 * the License is located at
 *
 *     http://aws.amazon.com/apache2.0/
 *
 * or in the "license" file accompanying this file. This file is
 * distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific
 * language governing permissions and limitations under the License.
 */

var AWS = require('./core');
var libxml = require("libxmljs");
require('./rest_service');
var inherit = AWS.util.inherit;

AWS.RESTXMLService = inherit(AWS.RESTService, {

  constructor: function RESTXMLService(config) {
    AWS.RESTService.call(this, config);
  },

  buildRequest: function buildRequest(method, params) {
    var _super = AWS.RESTService.prototype.buildRequest;
    var httpRequest = _super.call(this, method, params);
    httpRequest.body = this.buildBody(this.api.operations[method], params || {});
    return httpRequest;
  },

  buildBody: function buildBody(rules, params) {
    var body = null;
    AWS.util.each.call(this, rules.i || {}, function (name, rule) {
      if (rule.l === 'body') {
        if (rule.t === 'o') {
          body = this.buildXML(name, rule, params);
        } else {
          body = params[name];
        }
      }
    });
    return body;
  },

  buildXML: function buildXML(name, rules, params) {

    var xml = new libxml.Document();
    xml = xml.node(name).attr({ xmlns: this.api.xmlNamespace })

    AWS.util.each(rules.m, function (memberName, memberRule) {
      if (params[memberName] !== undefined) {
        xml.node(memberName, String(params[memberName])).parent();
      }
    });

    return xml.toString();

  }

});