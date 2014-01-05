$( document ).ready(function() {
  Parse.initialize("Q7ub1yg5A0AmDAnwnzVc2SS0X0Q4UZMefq3Kukdf", "dpqGmdW8VDtxsBwJ93hOWQqekd9M4OQwc8flxhmI");
  //check user login
  if(Parse.User.current()){
  	window.location.href = "/home";
  }
});