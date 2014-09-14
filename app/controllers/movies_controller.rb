class MoviesController < ApplicationController
	# require 'nokogiri'
	# require 'json'

	def show
		@movie = false
		until !@movie == false && @movie.critic_rating > 59
			# rand_id = rand(Movie.count)
 		# 	@movie = Movie.first(:conditions => [ "id >= ?", rand_id])
 			@movie = Movie.order("RANDOM()").limit(1)[0]
 			# @movie = Movie.order("RAND()").limit(1)[0] # for sqlite
 		end
 		@audience_class = @movie.audience_rating > 60 ? "fresh_popcorn" : "spilled_popcorn"
 		movie_id = @movie.rotten_tomatoes_id
 		@rt_link = "http://www.rottentomatoes.com/m/#{movie_id}"
 		@genres = @movie.genres.split(',').join(', ')
	end
end