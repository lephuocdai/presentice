$( document ).ready(function() {
  Parse.initialize("Q7ub1yg5A0AmDAnwnzVc2SS0X0Q4UZMefq3Kukdf", "dpqGmdW8VDtxsBwJ93hOWQqekd9M4OQwc8flxhmI");
  //check user login
  if(Parse.User.current()){
  	$("#login").html("<a href='/logout'>Logout</a>");
  } else {
  	$("#login").html("<a href='/login'>Login</a>");
  }

  //logout
  $("#login a").click(function(){
  	if(Parse.User.current()){
  		Parse.User.logOut();
  	}
  });

});