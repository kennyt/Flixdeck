class MoviesController < ApplicationController
	# require 'nokogiri'
	# require 'json'

	def show
		@movie = false
		until pass_filter?(@movie)
			# rand_id = rand(Movie.count)
 		# 	@movie = Movie.first(:conditions => [ "id >= ?", rand_id])
 			@movie = Movie.where(["critic_rating > ? and review_count > ?", 59, 20]).order("RANDOM()").limit(1)[0]
 			# movies.each do |movie|
 			# 	if pass_filter?(movie)
 			# 		@movie = movie
 			# 		break
 			# 	end
 			# end
 			# @movie = Movie.order("RAND()").limit(1)[0] # for sqlite
 		end
 		@audience_class = @movie.audience_rating > 60 ? "fresh_popcorn" : "spilled_popcorn"
 		movie_id = @movie.rotten_tomatoes_id
 		@rt_link = "http://www.rottentomatoes.com/m/#{movie_id}"
 		@genres = @movie.genres.split(',').join(', ')
 		@reviews = Movie.get_reviews_hash(@movie)
	end

	def pass_filter?(movie)
		movie != false && movie.critic_rating > 59 && movie.review_count > 20
	end


end