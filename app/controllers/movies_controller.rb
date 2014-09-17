class MoviesController < ApplicationController
	def index
		@comedies = Movie.get_genre(5, "Comedy")
		@action_advent = Movie.get_genre(5, "Action & Adventure")
		@mystery = Movie.get_genre(5, "Mystery & Suspense")
		@horror = Movie.get_genre(5, "Horror")
		@ninety = Movie.get_ultra(5)
		@drama = Movie.get_genre(5, "Drama")
		@romance = Movie.get_genre(5, "Romance")
		@art_international = Movie.get_genre(5, "Art House & International")
		@scifi = Movie.get_genre(5, "Science Fiction & Fantasy")
		@animation = Movie.get_genre(5, "Animation")
		@cult = Movie.get_genre(5, "Cult Movies")
		@documentary = Movie.get_genre(5, "Documentary")
		@classic = Movie.get_genre(5, "Classics")
		@kids = Movie.get_genre(5, "Kids & Family")
	end

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

	def get_reviews
		id = params[:rtid]
		reviews = Movie.get_reviews_hash(id)

		respond_to do |format|
      format.json { render :json => reviews }
    end
	end

	def pass_filter?(movie)
		movie != false && 
		movie.critic_rating > 59 && 
		movie.review_count > 20
	end
end