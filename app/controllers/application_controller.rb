class ApplicationController < ActionController::Base
  protect_from_forgery

  def movie_to_json(movie)
    {
      :genres => movie.genres,
      :cast => movie.cast,
      :director => movie.director,
      :critic_rating => movie.critic_rating,
      :review_count => movie.review_count,
      :audience_rating => movie.audience_rating,
      :title => movie.title,
      :year => movie.year,
      :runtime => movie.runtime,
      :mpaa => movie.mpaa,
      :synopsis => movie.synopsis,
      :critic_consensus => movie.critic_consensus,
      # :reviews => Movie.get_reviews_hash(movie),
      :audience_class => movie.audience_rating > 60 ? "fresh_popcorn" : "spilled_popcorn",
      :netflixsource => movie.netflixsource,
      :rotten_tomatoes_id => movie.rotten_tomatoes_id,
      :poster => movie.poster
    }
  end

  def movies_to_json(movies)
    movie_json = []
    movies.each do |movie|
      movie_json << movie_to_json(movie)
    end

    {:movies => movie_json}
  end

  def genre_num_to_genre(num)
  	case num
  	when "1"
  		genre = "All"
  	when "2"
  		genre = "Drama"
  	when "3"
  		genre = "Romance"
  	when "4"
  		genre = "Comedy"
  	when "5"
  		genre = "Mystery & Suspense"
  	when "6"
  		genre = "Action & Adventure"
  	when "7"
  		genre = "Documentary"
  	when "8"
  		genre = "Horror"
  	when "9"
  		genre = "Art House & International"
  	when "10"
  		genre = "Science Fiction & Fantasy"
  	when "11"
  		genre = "Animation"
  	when "12"
  		genre = "Kids & Family"
  	when "13"
  		genre = "Classics"
  	when "14"
  		genre = "Cult Movies"
  	end

  	genre
  end
end
