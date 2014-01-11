
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var user = require('./routes/user');
var http = require('http');
var path = require('path');
var passport = require('passport');
var LocalStrategy = require('passport-local').Strategy;



//Parse API
GLOBAL.Parse = require('parse').Parse;
Parse.initialize("Q7ub1yg5A0AmDAnwnzVc2SS0X0Q4UZMefq3Kukdf", "dpqGmdW8VDtxsBwJ93hOWQqekd9M4OQwc8flxhmI");


//S3 API
var AWS = require('aws-sdk'); 
var s3 = new AWS.S3(); 

var app = express();

//helper for template
var helpers = require('express-helpers');
helpers(app);

// all environments
//app.set('port', process.env.PORT || 5000);
app.set('port', 8080);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(express.cookieParser('your secret here'));
app.use(express.session());
app.use(express.bodyParser());
app.use(express.session({ secret: 'keyboard cat' }));
app.use(passport.initialize());
app.use(passport.session());
app.use(app.router);
app.use(require('less-middleware')({ src: path.join(__dirname, 'public') }));
app.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

/*
login module with passport
*/

//find username, password with Parse User database
passport.use(new LocalStrategy(
  function(username, password, done) {
    return Parse.User.logIn(username,password, {
      success: function(user){
        return done(null, user)
      },
      error: function(user, error){
        return done(null, false, {message: 'Incorrect username or password'});
      }
    });
  }
));

passport.serializeUser(function(user, done) {
    done(null, user);
});

passport.deserializeUser(function(user, done) {
  done(null, user);
});

//login page
app.get('/login', function(req, res) {
  res.render('login', { message: 'todo: implement login function' });
});
app.post('/login',
  passport.authenticate('local', { successRedirect: '/home',
                                  failureRedirect: '/login' })
);


//home page
app.get('/home', function(req, res){
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
      res.render('home', {videoList: videos});
    },
    error: function(error) {
        //todo?
    }
    });
});

//mylist page
app.get('/mylist', function(req, res){
  //find currun login user
  var queryUser = new Parse.Query(Parse.User);
  queryUser.equalTo("objectId", req.user.objectId);
  queryUser.find({
    success: function(users){
        var Video = Parse.Object.extend("Video");
        var query = new Parse.Query(Video);
        query.equalTo("type", "answer");

        query.equalTo("user", users[0]);
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
      res.render('mylist', {videoList: videos});
    },
    error: function(error) {
        //todo?
    }
    });
    }
  });
});

//logout request
app.get('/logout', function(req, res){
  req.logout();
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
