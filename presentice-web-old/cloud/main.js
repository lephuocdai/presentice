
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
require('cloud/app.js');
Parse.Cloud.define("hello", function(request, response) {
  response.success("hello, welcome to Presentice!");
});
