var INIT_POINT = 100;
var INIT_LEVEL = 0;
var INIT_CONTRIBUTION = 0;

var POINT_REGISTER_WITH_MYCODE = 50;

var POINT_PLUS_ON_REVIEW = 50;
var POINT_MINUS_ON_REVIEWED = 50;

var CONTRIBUTION_PLUS_ON_REVIEW = 1;

var CONTRIBUTION_TO_LEVEL_UP = 10*1;

Parse.Cloud.define("sendPushNotification", function(request, response) {
	var pushType = request.params.pushType;
	if (pushType == "message") {
		var toUser = request.params.toUser;
		var content = request.params.content;
		Parse.Push.send({
	  		channels: [toUser],
	  		data: {
				alert: "\"" + request.user.get("displayName") + "\" sent you a " + pushType + ": \"" + content + "\"",
	    		badge: "Increment"
	  		}
		}, {
	  		success: function() {
	    		// Push was successful
	  		},
	  		error: function(error) {
	    		// Handle error
	  		}
		});
	} else {
		var targetVideo = request.params.targetVideo;
		var toUser = request.params.toUser;
		Parse.Push.send({
	  		channels: [toUser],
	  		//channels: ["MvvDYgieBH"],
	  		data: {
				alert: "Your video \"" + targetVideo + "\" has been " + pushType + " by \"" + request.user.get("displayName") + "\"",
	    		badge: "Increment"
	  		}
		}, {
	  		success: function() {
	    		// Push was successful
	  		},
	  		error: function(error) {
	    		// Handle error
	  		}
		});
	}
});

/**
** cloud code call when user registered successfully
** step1: save promotion information of user
** step2: save promotion information for user have myCode as code entered by registered user
**/

Parse.Cloud.define("onRegistered", function(request, response){
	var user = request.user;
	var receiveCode = request.params.receiveCode;

	//save promotion info of user
	var promotion = new Parse.Object("Promotion");
	promotion.set("user", user);
	promotion.set("myCode", Math.uuid(6, 16));	//generate myCode to an unique 6 characters, base=16
    promotion.set("points", INIT_POINT);   //set init point to user
    promotion.set("level", INIT_LEVEL);	//set init level to user
    promotion.set("receiveCode", receiveCode);
    promotion.set("contribution", INIT_CONTRIBUTION);
    promotion.save();
	
    user.set("promotion", promotion);
    user.save();
    		
   	//find promotion of users which have myCode as code entered by other user
    var query = new Parse.Query("Promotion");
    query.include("user");
	query.equalTo("myCode", receiveCode);
	query.find({
		success: function(results){
			if (results.length == 0) {
				var notification = new Parse.Object("Activity");
	    		notification.set("type", "invalidCode");
	    		notification.set("toUser",user);
	    		notification.set("fromUser",user);
	    		notification.set("description", "Your input code \"" + receiveCode + "\" does not match anyone's promotion code.");
	    		notification.save();
				Parse.Push.send({
	  				channels: [user.id],
	  				data: {
						alert: "Your input code \"" + receiveCode + "\" does not match anyone's promotion code.",
	    				badge: "Increment"
	  				}
				}, {
	  				success: function() {
	    				// Push was successful
	  				},
	  				error: function(error) {
	    				console.error("Got an error " + error.code + " : " + error.message);
	  				}
				});
			} else {
				//increase points to each user
				for (var i = 0; i < results.length; i++) {
					var promotion2 = results[i];
					var points = promotion2.get("points") + POINT_REGISTER_WITH_MYCODE;
					promotion2.set("points", points);
					promotion2.save();
					Parse.Push.send({
	  					channels: [promotion2.get("user").id],
	  					data: {
							alert: "Your friend \"" + user.get("displayName") + "\" has been register by your promotion code. You have been added " + POINT_REGISTER_WITH_MYCODE + " points. Cheers!",
	    					badge: "Increment"
	  					}
					}, {
	  					success: function() {
	    					// Push was successful
	  					},
	  					error: function(error) {
	    					console.error("Got an error " + error.code + " : " + error.message);
	  					}
					});
				};
			}
		},
		error: function(error){
			console.error("Got an error " + error.code + " : " + error.message);
		}
	});
});

/**
** user fromUser review video of toUser
** step1: find promotion of fromUser and
** 		  if there is comment: plus points
** 		  plus contribution (+1)
** step2: find promotion of toUser and 
** 		  if there is comment: minus points
**/
Parse.Cloud.define("onReviewed", function (request, response){
	var fromUser = request.user;
	var toUserId = request.params.toUser;
	var comment = request.params.comment;
	
	//step1: find promotion of fromUser and plus points
	var query = new Parse.Query("Promotion");
	query.equalTo("user", fromUser);
	query.find({
		success: function(results){
			//for each user do review -> plus some points
			for(var i =0; i < results.length; i++){
				var promotion = results[i];

				if(comment != null && comment != ""){
					var points = promotion.get("points") + POINT_PLUS_ON_REVIEW;
					promotion.set("points", points);
				}

				var contribution = promotion.get("contribution");
				contribution = contribution + CONTRIBUTION_PLUS_ON_REVIEW;
				promotion.set("contribution", contribution);

				//if contribution > a number -> level up
				if(contribution > CONTRIBUTION_TO_LEVEL_UP){
					var level = promotion.get("level");
					level++;
					promotion.set("level", level);
				}
				
				promotion.save();
			}
		}
	});

	//step2: find promotion of toUser and minus points

	//if there is no comment, do noting
	if(comment == null || comment == "") return;

	//get toUser from id
	var toUser = new Parse.User();
	toUser.id = toUserId;

	//query toUser and minus points
	var query2 = new Parse.Query("Promotion");
	query2.equalTo("user", toUser);
	query2.find({
		success: function(results){
			//for each user do review -> plus some points
			console.log(results);
			for(var i =0; i < results.length; i++){
				var promotion = results[i];
				var points = promotion.get("points") - POINT_MINUS_ON_REVIEWED;
				if(points < 0) points = 0;
				promotion.set("points", points);
				promotion.save();
			}
		}
	});

});

Math.uuid = function (len, radix) {
 	// Private array of chars to use
  	var CHARS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('');
    var chars = CHARS, uuid = [], i;
    radix = radix || chars.length;

    if (len) {
    	// Compact form
      	for (i = 0; i < len; i++) uuid[i] = chars[0 | Math.random()*radix];
    } else {
      	// rfc4122, version 4 form
      	var r;

    	 // rfc4122 requires these characters
      	uuid[8] = uuid[13] = uuid[18] = uuid[23] = '-';
      	uuid[14] = '4';

      	// Fill in random data.  At i==19 set the high bits of clock sequence as
      	// per rfc4122, sec. 4.1.5
      	for (i = 0; i < 36; i++) {
        	if (!uuid[i]) {
          	r = 0 | Math.random()*16;
          	uuid[i] = chars[(i == 19) ? (r & 0x3) | 0x8 : r];
        	}
      	}
    }
    return uuid.join('');
};
