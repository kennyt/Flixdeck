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
		@documentary = Movie.get_genre(5, "Documentary")
		@classic = Movie.get_genre(5, "Classics")
	end

	def show
		@movie = false

 		if params[:genre].nil? || params[:genre] == "1"
 			genre = false
 		else
 			genre = genre_num_to_genre(params[:genre])
 		end

 		if params[:minscore].nil?
 			min_score = 60
 		else
 			min_score = params[:minscore].to_i
 		end

		if params[:seen]
			already_seen = params[:seen].split('a').map{|n| n.to_i}
		else
			already_seen = [0]
		end

		until pass_filter?(@movie, min_score)
			@movie = Movie.get_random(genre, min_score, already_seen)
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

	def all_genre
		genre = stringToGenre(params[:genre])
		@genre_title = genre
		if params[:sortby] == "aud"
			@movies = Movie.get_ordered_genre(250, genre, 'audience_rating')
		else
			@movies = Movie.get_ordered_genre(250, genre, 'critic_rating')
		end
		p "###zzzzzzzzzzzzzzzzzz###" + params[:sortby].to_s
		respond_to do |format|
      format.html
      format.json { render :json => movies_to_json(@movies) }
    end
	end

	def get_reviews
		id = params[:rtid]
		reviews = Movie.get_reviews_hash(id)

		respond_to do |format|
      format.json { render :json => reviews }
    end
	end

	def get_five
		genre = params[:genre]
		if params[:seen]
			already_seen = params[:seen].split('a').map{|n| n.to_i}
		else
			already_seen = []
		end

		if genre == "15"
			movies = Movie.get_ultra(5)
		else
			movies = Movie.get_genre(5, genre_num_to_genre(genre), already_seen)
		end


		respond_to do |format|
      format.json { render :json => movies_to_json(movies) }
    end
	end

	def pass_filter?(movie, min_score)
		movie != false && 
		movie.critic_rating > min_score - 1 && 
		movie.review_count > 20
	end
end