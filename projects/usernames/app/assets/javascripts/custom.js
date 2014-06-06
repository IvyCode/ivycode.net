var date = new Date();
date.setTime(date.getTime() + (100000 * 100000));

var saved = $.cookie("usernames") == null ? "" : $.cookie("usernames");

// Cookies
for (var i in saved.split(",")) {
	var user = saved.split(",")[i];
	if ($.trim(user) == "") {
		continue;
	}
	$('#saved').append("<div class='alert alert-success username'>" + user + "<a class='close delete'>&times;</a></div>");
	$("#none").hide();
}


$(document).on("click", ".save", function() {
	$(this).hide();
	$("#none").hide();
	var name = $(this).parent().clone().children().remove().end().text().replace(/(\r\n|\n|\r)/gm,"");
	$('#saved').append("<div class='alert alert-success username'>" + name + "<a class='close delete'>&times;</a></div>");

	// Cookies
	saved += name + ",";
	$.cookie("usernames", saved, { expires: date });
});

$(document).on("click", ".delete", function() {
	var name = $(this).parent().clone().children().remove().end().text().replace(/(\r\n|\n|\r)/gm,"");
	$(this).parent().remove();

	// Cookies
	saved = saved.replace(name + ",", "");

	if (saved.split(",").length == 1) {
		$("#none").show();
	}

	$.cookie("usernames", saved, { expires: date });
});

$('.toggle-saved').click(function() {
	$('#saved').animate({
	  height: "toggle",
	  opacity: "toggle"
	});
});

$("[rel='tooltip']").tooltip();

// Form
var i = 0;
var id = 0;
var prevRequest;
$('form').submit(function(event){
	id += 1;
	var current = id;
	$('#loading').fadeOut(50);
	$('#loading').fadeIn(50);

	var data = $(this).serialize();

	if (prevRequest != null) {
		$("#cancelled").fadeIn(500);
		setTimeout(function() {
			$("#cancelled").fadeOut(500);
		}, 5000);
		prevRequest.abort();
	}
	
	prevRequest = $.get('/usernames/search', data).
	success(function(result){
		if (current != id) {
			return;
		}
		$("#loading").fadeOut(500);

		if (i > 0) {
			$('#result' + (i - 1)).fadeTo(500, 0.5)
		}
		$("#results").prepend("<div style='display: none; height: 195px;' id='result" + i + "'></div>");

		$("#result" + i).hide();
		$("#result" + i).html(result);
		$("#result" + i).slideDown(500);

		i += 1;
	})
	.error(function(){
		// Meh
	}
	);
	return false;
});
