
// These two lines are required to initialize Express in Cloud Code.
var express = require('express');
var app = express();

// Global app configuration section
app.set('views', 'cloud/views');  // Specify the folder to find templates
app.set('view engine', 'ejs');    // Set the template engine
app.use(express.bodyParser());    // Middleware for reading request body

// This is an example of hooking up a request handler with a specific request
// path and HTTP verb using the Express routing API.
app.get('/hello', function(req, res) {
  res.render('hello', { message: 'Congrats, you just set up your app!' });
});

//login page
app.get('/login', function(req, res) {
  res.render('login', { message: 'todo: implement login function' });
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
	var Video = Parse.Object.extend("Video");
	var query = new Parse.Query(Video);
	query.find({
  		success: function(results) {
  			res.render('index', {message: results});
  		},
  		error: function(error) {
    		res.render('index', {message: error});
  		}
	});
});

//login succeed
app.get('/success', function(req, res){
	res.redirect('/');
})

app.listen();
