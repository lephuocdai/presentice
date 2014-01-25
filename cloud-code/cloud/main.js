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

Parse.Cloud.beforeSave(Parse.User, function(request, response) {
    request.object.set("myCode", Math.uuid(6, 16));	//set myCode to an unique 6 characters, base=16
    response.success();
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
