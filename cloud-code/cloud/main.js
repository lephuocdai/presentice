
Parse.Cloud.afterSave("Review", function(request) {
	var fromUser = request.object.get("fromUser");
	var targetVideo = request.object.get("targetVideo");
	var videoObj = Parse.Object.extend("Video");
	var query = new Parse.Query(videoObj);
	query.get(targetVideo.id, {
		success: function(video){
			var toUser = video.get("user");
			Parse.Push.send({
  				channels: [ fromUser.id, toUser.id],
  				data: {
    				alert: "Your video " + video.get("videoName") + " has been reviewed by " + request.user.get("displayName") + "!"
  				}
				}, {
  				success: function() {
    				// Push was successful
  				},
  				error: function(error) {
    				// Handle error
  				}
			});
		},
		error: function(object, error){

		}
	});
    
});
