
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var user = require('./routes/user');
var http = require('http');
var path = require('path');

var Parse = require('parse').Parse;

var app = express();

// all environments
app.set('port', process.env.PORT || 5000);
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
        res.render('home');
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
	// Parse.initialize("Q7ub1yg5A0AmDAnwnzVc2SS0X0Q4UZMefq3Kukdf", "dpqGmdW8VDtxsBwJ93hOWQqekd9M4OQwc8flxhmI");
 //         var Video = Parse.Object.extend("Video");
 //         var query = new Parse.Query(Video);
 //         query.find({
 //                   success: function(results) {
 //                           res.render('index', {message: results});
 //                   },
 //                   error: function(error) {
 //                     res.render('index', {message: error});
 //                   }
 //         });
});

//login succeed
app.get('/success', function(req, res){
        res.redirect('/');
})

http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});
