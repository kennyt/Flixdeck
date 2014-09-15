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

function showMovie(movie){
	$('.film_title').html(movie['title'])
	$('.year_release').html(movie['year'])
	$('.runtime').html(movie["runtime"] + 'min')
	$('.mpaa').html(movie["mpaa"])
	$('#critic_score').html(movie["critic_rating"] + '<span class="small">%</span>')
	$('#audience_score').html(movie["audience_rating"] + '<span class="small">%</span>')
	$('#review_count').html(movie["review_count"] + ' critic reviews')
	$('.synopsis').html(movie["synopsis"])
	$('.critic_consensus').html(movie["critic_consensus"])
	$('#genres').html(movie["genres"])
	$('#cast').html(movie["cast"])
	$('#directors').html(movie["director"])

	$('.synopsis').attr('style','')
}

$(document).ready(function(){
	$('body').on('click', '.open_bar', function(ev){
		var synopsis = $('.synopsis')
		if (synopsis.hasClass('unopened')){
			var height = $(synopsis).height()
			var autoHeight = $(synopsis).css('height','auto').height();
			var animationTime = 400

			$(synopsis).removeClass('unopened')
			$(synopsis).height(height).animate({height: autoHeight}, animationTime);
			$('.open_bar').fadeOut(animationTime)
			setTimeout(function(){
				$('.open_bar').remove()
			},animationTime)
		}
	})

	$('body').on('click', '.redraw', function(ev){
		$.post('/movie.json', function(response){
			showMovie(response);
			checkIfOpenBarNeeded($('.synopsis'))
		})
	})

	checkIfOpenBarNeeded($('.synopsis'));
})