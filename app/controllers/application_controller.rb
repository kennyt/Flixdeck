class ApplicationController < ActionController::Base
  protect_from_forgery

  def movie_to_json(movie)
    {
      :genres => movie.genres,
      :cast => movie.cast,
      :critic_rating => movie.critic_rating,
      :review_count => movie.review_count,
      :audience_rating => movie.audience_rating,
      :title => movie.title,
      :year => movie.year,
      :runtime => movie.runtime,
      :mpaa => movie.mpaa,
      :synopsis => movie.synopsis,
      :critic_consensus => movie.critic_consensus,
      :reviews => Movie.get_reviews_hash(movie),
      :audience_class => movie.audience_rating > 60 ? "fresh_popcorn" : "spilled_popcorn",
      :netflixsource => movie.netflixsource,
      :rotten_tomatoes_id => movie.rotten_tomatoes_id
    }
  end
end
