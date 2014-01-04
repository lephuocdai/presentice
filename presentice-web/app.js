
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var user = require('./routes/user');
var http = require('http');
var path = require('path');

//Parse API
var Parse = require('parse').Parse;

//S3 API
var AWS = require('aws-sdk'); 
var s3 = new AWS.S3(); 

var app = express();

//helper for template
var helpers = require('express-helpers');
helpers(app);

// all environments
app.set('port', process.env.PORT || 5000);
//app.set('port', 8080);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(express.cookieParser('your secret here'));
app.use(express.session());
app.use(app.router);
app.use(require('less-middleware')({ src: path.join(__dirname, 'public') }));
app.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

// This is an example of hooking up a request handler with a specific request
// path and HTTP verb using the Express routing API.
app.get('/hello', function(req, res) {
  res.render('hello', { message: 'Congrats, you just set up your app!' });
});

//login page
app.get('/login', function(req, res) {
  res.render('login', { message: 'todo: implement login function' });
});

//home page
app.get('/home', function(req, res){
     Parse.initialize("Q7ub1yg5A0AmDAnwnzVc2SS0X0Q4UZMefq3Kukdf", "dpqGmdW8VDtxsBwJ93hOWQqekd9M4OQwc8flxhmI");
          var Video = Parse.Object.extend("Video");
          var query = new Parse.Query(Video);
          query.equalTo("type", "answer");
          query.equalTo("visibility","open");
          query.find({
                    success: function(results) {
                      var videos = new Array();
                      for(var i = 0; i < results.length; i++){
                        var params = {Bucket: 's3-transfer-manager-bucket-akiaibf67u5imhub2kdq', Key: results[i].get("videoURL")};
                        s3.getSignedUrl('getObject', params, function (err, url) {
                          var obj = {};
                          obj["name"] = results[i].get("videoName");
                          obj["url"] = url;
                          videos.push(obj);
                        });
                      }
                       console.log(videos); 
                       res.render('home', {videoList: videos});
                    },
                    error: function(error) {
                      //todo?
                    }
          });
});

//logout request
app.get('/logout', function(req, res){
        if(Parse.User.current()){
                Parse.User.logOut();
        }
        res.redirect('/');
});

//main page
app.get('/', function(req, res){
	res.render('index');
});

//login succeed
app.get('/success', function(req, res){
        res.redirect('/');
})

http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});
