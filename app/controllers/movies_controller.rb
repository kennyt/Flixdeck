class MoviesController < ApplicationController
	def show
		@movie = false
		
 		if params[:genre].nil? || params[:genre] == "1"
 			genre = false
 		else
 			genre = genre_num_to_genre(params[:genre])
 		end

		until pass_filter?(@movie)
			@movie = Movie.get_random(genre)
 		end

 		respond_to do |format|
      format.html do 
		 		@audience_class = @movie.audience_rating > 60 ? "fresh_popcorn" : "spilled_popcorn"
		 		movie_id = @movie.rotten_tomatoes_id
		 		@rt_link = "http://www.rottentomatoes.com/m/#{movie_id}"
		 		@genres = @movie.genres.split(',').join(', ')
		 		# @reviews = Movie.get_reviews_hash(@movie)
      end
      format.json { render :json => movie_to_json(@movie) }
    end
	end

	def pass_filter?(movie)
		movie != false && 
		movie.critic_rating > 59 && 
		movie.review_count > 20
	end
end