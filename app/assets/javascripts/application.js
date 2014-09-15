// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

function checkIfOpenBarNeeded(synopsis){
	var height = synopsis.height()
	var autoHeight = synopsis.css('height','auto').height();
	synopsis.height(height)

	if (autoHeight >= height + 10){
		synopsis.addClass('unopened')
		synopsis.append('<div class="open_bar">v</div>')
	}
}

$(document).ready(function(){
	$('body').on('click', '.synopsis', function(ev){
		if ($(this).hasClass('unopened')){
			var that = this;
			var height = $(this).height()
			var autoHeight = $(this).css('height','auto').height();
			var animationTime = 400

			$(that).removeClass('unopened')
			$(this).height(height).animate({height: autoHeight}, animationTime);
			$('.open_bar').fadeOut(animationTime)
			setTimeout(function(){
				$('.open_bar').remove()
			},animationTime)
		}
	})

	checkIfOpenBarNeeded($('.synopsis'));
})