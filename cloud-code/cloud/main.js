
Parse.Cloud.afterSave("Review", function(request) {
	var fromUser = request.object.get("fromUser");
	var targetVideo = request.object.get("targetVideo");
	var toUser = request.object.get("toUser");
	Parse.Push.send({
  		channels: [request.object.get("toUser")],
  		data: {
  			alert: "Your video " + video.get("videoName") + " has been reviewed by " + request.user.get("displayName") + "!",
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
});
