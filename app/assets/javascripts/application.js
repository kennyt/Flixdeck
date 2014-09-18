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

function showReview(review, currentParallel, i){
	var imageClass = 'noclass';
	if (review["freshness"] == "fresh"){
		imageClass = "medium_tomato review_image"
	} else {
		imageClass = "medium_rotten review_image"
	}

	if (currentParallel.length != 0){
		currentParallel.animate({ opacity: 0}, 250)
	}

	setTimeout(function(){
		if (currentParallel.length != 0){
			currentParallel.replaceWith('<div class="center_col one_review_wrapper" id="movie'+i+'" style="opacity:0;"><div class="center_col" style="float:left; margin-top:50px;padding-top: 50px;border-top:1px solid #D8D8D8;"><div class="left_col"><div class="'+imageClass+'"></div><div class="reviewer_name">'+review["critic"]+'</div><div class="reviewer_publication">'+review["publication"]+'</div><div class="review_date">'+review["date"]+'</div></div><div class="review_wrap"><div class="reviews_container"><div class="review_quote">"'+review["quote"]+'"</div></div></div></div></div>')
		} else {
			$('.individual_reviews').append('<div class="center_col one_review_wrapper" id="movie'+i+'" style="opacity:0;"><div class="center_col" style="float:left; margin-top:50px;padding-top: 50px;border-top:1px solid #D8D8D8;"><div class="left_col"><div class="'+imageClass+'"></div><div class="reviewer_name">'+review["critic"]+'</div><div class="reviewer_publication">'+review["publication"]+'</div><div class="review_date">'+review["date"]+'</div></div><div class="review_wrap"><div class="reviews_container"><div class="review_quote">"'+review["quote"]+'"</div></div></div></div></div>')
		}

		$('#movie'+i).animate({ opacity: 1}, 250).attr('id','');
	}, 250)
}

function removeExtraReviews(newLength){
	var curLength = $('.one_review_wrapper').length

	if (curLength > newLength){
		$('.one_review_wrapper').slice(newLength, curLength).remove()
	}
}

function showReviews(reviews){
	$.each(reviews, function(i, review){
		var currentParallel = $($('.one_review_wrapper')[i])
		setTimeout(function(){
			showReview(review, currentParallel, i)
		}, i * 50)
	})

	removeExtraReviews(reviews.length)
}

function peopleLinkHtml(people){
	var people = people.split(', ')
	var html = ""
	// console.log(people)
	$.each(people, function(i, person){
		var googleSearchable = person.split(' ').join('%20')
		html = html + '<a class="people linked" href="http://www.google.com/#q=' + googleSearchable +'">' + person + '</a>'
	})

	// console.log(html);
	return html
}

function showMovie(movie){
	delayTransitionAttr($('.whitewrap .poster'), 'src', movie["poster"], 0)
	delayTransitionHtml($('#genres'), movie["genres"].split(',').join(', '), 20)
	delayTransitionHtml($('#directors'), peopleLinkHtml(movie["director"]), 40)
	delayTransitionHtml($('#cast'), peopleLinkHtml(movie["cast"]), 60)
	delayTransitionHtml($('#critic_score'), movie["critic_rating"] + '<span class="small">%</span>', 60)
	delayTransitionHtml($('.critic_tomato'), false, 50)
	delayTransitionHtml($('#review_count'), movie["review_count"] + ' critic reviews', 50)
	delayTransitionHtml($('#audience_score'), movie["audience_rating"] + '<span class="small">%</span>', 100)
	delayTransitionAttr($('#popcorn_bucket'), 'class', "rating_holder " + movie["audience_class"], 100)
	delayTransitionHtml($('.film_title'), movie['title'], 150)
	delayTransitionHtml($('.year_release'), movie['year'], 200)
	delayTransitionHtml($('.runtime'), movie["runtime"] + 'min', 250)
	delayTransitionHtml($('.mpaa'), movie["mpaa"], 300)
	delayTransitionHtml($('.synopsis'), movie["synopsis"], 350, function(){
		checkIfOpenBarNeeded($('.synopsis'))
	})
	delayTransitionHtml($('.consensus_header'), false, 460)
	delayTransitionHtml($('.critic_consensus'), '"' + movie["critic_consensus"] + '"', 500)
	delayTransitionHtml($('.big_tomato'), false, 500)

	// setTimeout(function(){
	// 	showReviews(movie["reviews"])
	// }, 470)

	$('.play_netflix').attr('href', "http://www.netflix.com/WiMovie/" + movie["netflixsource"])
	$('#rt_link').attr('href', "http://www.rottentomatoes.com/m/" + movie["rotten_tomatoes_id"])
	$('.synopsis').attr('style','')
}

function delayTransitionHtml(ele, newHtml, delay, callback){
	setTimeout(function(){
			ele.animate({ opacity: 0}, 300)
			setTimeout(function(){
				if (newHtml){
					ele.html(newHtml)
				}
				ele.animate({ opacity: 1}, 300)
				if (callback){
					callback();
				}
			}, 300)
	}, delay)
}

function delayTransitionAttr(ele, attr, attrValue, delay){
	setTimeout(function(){
		ele.animate({ opacity: 0}, 300)
		setTimeout(function(){
			ele.attr(attr, attrValue)
		}, 300)
		ele.animate({ opacity: 1}, 300)
	}, delay)
}

function preLoadMovie(callback){
	var genre = $('.selected_genre').attr('data-genre-number')
	var url = '/movie.json?genre=' + genre
	$.post(url, function(response){
		movieHolder.push(response);
		if (callback){
			callback();
		}
	})
}

function getReviews(rt_id){
	$.post('/movie/get_reviews.json?rtid=' + rt_id, function(response){
		showReviews(response)
	})
}

function rotate(ele){
	var rotation = $(ele).attr('data-rotate')
	$(ele).css({'-ms-transform': 'rotate('+rotation+'deg)', '-webkit-transform': 'rotate('+rotation+'deg)', 'transform': 'rotate('+rotation+'deg)'})
	$(ele).attr('data-rotate', parseInt(rotation) + 360);
}

function playMovie(movieHolder, currentGenre){
	var nextMovie = movieHolder[0]
	if (currentGenre == "All" || nextMovie["genres"].indexOf(currentGenre) != -1){
		showMovie(movieHolder[0]);
		preLoadMovie();
	} else {
		preLoadMovie(function(){
			$('.redraw').trigger('click');
		})
	}
	movieHolder.shift();
}

function eleToMovie(ele){
	var movie = {}
	movie["genres"] = ele.attr('data-genres')
	movie["cast"] = ele.attr('data-cast')
	movie["director"] = ele.attr('data-directors')
	movie["critic_rating"] = ele.attr('data-critic-rating')
	movie["review_count"] = ele.attr('data-review-count')
	movie["audience_rating"] = ele.attr('data-audience-rating')
	movie["title"] = ele.attr('data-title')
	movie["runtime"] = ele.attr('data-runtime')
	movie["mpaa"] = ele.attr('data-mpaa')
	movie["synopsis"] = ele.attr('data-synopsis')
	movie["critic_consensus"] = ele.attr('data-critic-consensus')
	movie["netflixsource"] = ele.attr('data-netflixsource')
	movie["rotten_tomatoes_id"] = ele.attr('data-rotten-tomatoes-id')
	movie["poster"] = ele.attr('data-poster')
	movie["year"] = ele.attr('data-year')

	if (parseInt(movie["audience_rating"]) > 60){
		movie["audience_class"] = "fresh_popcorn"
	} else {
		movie["audience_class"] = "spilled_popcorn"
	}

	return movie
}

$(document).ready(function(){


	//on random only
	if ($('.page_identifier').attr('data-id') == 'random'){

		$('body').on('click', '.redraw', function(ev){
			var currentGenre = $('.selected_genre').text()
			playMovie(movieHolder, currentGenre)
			rotate($(this));
		})

		$('body').on('click', '.filter', function(ev){
			$('.genre_container').animate({ left: 0}, 300)
		})

		$('body').on('click', '.close_genre', function(ev){
			$('.genre_container').animate({ left: '-200'}, 300)
		})

		$('body').on('click', '.a_genre', function(ev){
			$('.selected_genre').removeClass('selected_genre')
			$(this).addClass('selected_genre');
			preLoadMovie(function(){
				movieHolder.shift();
				$('.redraw').trigger('click');
			})
		})

		$('body').on('click','.get_reviews', function(ev){
			getReviews($('.rating_container').attr('data-rotten-tomatoes-id'))
		})

		movieHolder = [];
		preLoadMovie();
		checkIfOpenBarNeeded($('.synopsis'));
		$('body').css('background','#F3F2F1')
	}



	//on index only
	if ($('.page_identifier').attr('data-id') == 'index'){
		$('body').on('click', '.cover_more_info', function(ev){
			$('.triangle').css({'left': $(this).offset().left + 80, 'top':'-20px'})
			var currentParent = $('.movie_card').parent()
			var currentIndex = $('.movie_card').index()
			var leavingRow = currentParent.children()[currentIndex-1]
			var movie = eleToMovie($(this))
			var parent = $(this).parent().parent().parent()
			var height = $('.movie_card').height()
			
			$(parent).after($('.movie_card'))

			if (!($(currentParent).is('body')) && ($(leavingRow).attr('id') != $(parent).attr('id')) ){
				$(leavingRow).css('padding-bottom', height + 'px')
			}
			
			$('.movie_card').show()


			$('body,html').animate({scrollTop: $(parent).offset().top + 110}, 300, function(){
				$(leavingRow).css('padding-bottom', '0px')
				$('body').scrollTop($(parent).offset().top + 110)
			})
			// $('.movie_card').animate({height: 750}, 300)
			$('.movie_card').append($('.triangle'))
			showMovie(movie)
		})

		$('body').on('click', '.close_card', function(ev){
			$('.movie_card').animate({height: 0}, 500, function(){
				$('.movie_card').removeAttr('style');
				$('.movie_card').hide();
				$('body').append($('.movie_card'))
			})
		})

		$('.movie_card').hide();
		$('.movie_card').append('<div class="close_card">x</div>')
	}


	//no matter what page
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
})