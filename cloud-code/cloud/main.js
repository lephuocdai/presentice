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



// Parse.Cloud.afterSave("Review", function(request) {
// 	var fromUser = request.object.get("fromUser");
// 	var targetVideo = request.object.get("targetVideo");
// 	fromUser.fetch();
// 	targetVideo.fetch();
// 	console.log(fromUser);
// 	console.log(targetVideo);
// 	var videoObj = Parse.Object.extend("Video");
// 	var query = new Parse.Query(videoObj);
// 	query.get(targetVideo.id, {
// 		success: function(video) {
// 			var toUser = video.get("user");
// 			Parse.Push.send({
//   				channels: [toUser.id],
//   				data: {
// 					alert: "Your video " + video.get("videoName") + " has been reviewed by " + request.user.get("displayName") + "!",
//     				badge: "Increment"
//   				}
// 			}, {
//   				success: function() {
//     				// Push was successful
//   				},
//   				error: function(error) {
//     				// Handle error
//   				}
// 			});
// 		},
// 		error: function(object, error) {
// 			console.log(error);
// 		}
// 	});
// });

// Parse.Cloud.afterSave("Video", function(request) {
// 	if (request.object.get("type") == "answer") {
// 		var fromUser = request.object.get("user");
// 		var asAReplyTo = request.object.get("asAReplyTo");
// 		fromUser.fetch();
// 		asAReplyTo.fetch();
// 		var toUser = request.object.get("toUser");
// 		Parse.Push.send({
// 			channels: [toUser.id],
// 			data: {
// 	  			alert: "Your video " + asAReplyTo.get("videoName") + " has been answered by " + fromUser.get("displayName") + "!",
//    				badge: "Increment"
// 			}
// 		}, {
// 			success: function() {
//     			// Push was successful
// 	  		},
//   			error: function(error) {
//    				// Handle error
// 			}
// 		});
// 	};	
// });
