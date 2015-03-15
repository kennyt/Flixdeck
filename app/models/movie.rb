class Movie < ActiveRecord::Base
  attr_accessible :rotten_tomatoes_id, :title, :year, :runtime, :critic_rating, :audience_rating,  :critic_consensus,  :synopsis,  :mpaa,  :netflixsource,  :poster,  :cast,  :director,  :genres, :review_count
	require 'open-uri'
	require 'iconv'
	require 'cgi'

  def self.generate_database
		total_movies = get_total
	  data = get_data(total_movies)

	  data.each do |movie|
      next if exists?(movie)

      #make movie from info scraped
      movie = make_or_update(movie)

      #make rottentomatoes api call and get additional info
      give_attribute_full(movie)

      #scrape individual rottentomatoes page to get unavailable data
      scrape_individual(movie)
	  end
	end

	def self.get_reviews_hash(movie_id)
		data = open("http://api.rottentomatoes.com/api/public/v1.0/movies/#{movie_id}/reviews.json?apikey=5r8xr8cqaw9y3a2dhhtz2q7f&page_limit=50&review_type=all")
		json = data.read
		reviews = []

  	JSON.parse(json)["reviews"].each do |review|
  		reviews << review if review["quote"].length > 0
  		break if reviews.length >= 10
  	end

  	reviews
	end

	def self.get_random(genre, min_score, seen = [0])
		min_score -= 1
		if genre
			genre = "%#{genre}%"
	 		Movie.where(["critic_rating > ? and review_count > ? and genres LIKE ? and id NOT IN (?)", min_score, 20, genre, seen]).order("RANDOM()").limit(1)[0]
	 	else
			Movie.where(["critic_rating > ? and review_count > ?", min_score, 20]).order("RANDOM()").limit(1)[0]
	 	end
	end

	def self.get_genre(num, genre, seen = [0])
		genre = "%#{genre}%"
		Movie.where(["critic_rating > ? and review_count > ? and genres LIKE ? and id NOT IN (?)", 59, 20, genre, seen]).order("RANDOM()").limit(num)
	end

	def self.get_ordered_genre(num, genre, order)
		genre = "%#{genre}%"
		if order == "audience_rating"
			Movie.where(["review_count > ? and genres LIKE ? and year > ?", 10, genre, 1969]).order(order + " DESC").limit(num)
		else
			Movie.where(["critic_rating > ? and review_count > ? and genres LIKE ? and year > ?", 59, 10, genre, 1969]).order(order + " DESC").limit(num)
		end
	end

	def self.get_ultra(num)
		Movie.where(["critic_rating > ? and review_count > ?", 89, 20]).order("RANDOM()").limit(num)
	end

  private

    def self.exists?(movie)
      return !Movie.find_by_rotten_tomatoes_id(movie["id"]).nil?
    end

    def self.make_or_update(movie)
      if Movie.find_by_rotten_tomatoes_id(movie["id"]).nil?
        return create_new_movie(movie)
      else
        return Movie.find_by_rotten_tomatoes_id(movie["id"])
      end
    end

    def self.create_new_movie(movie)
      current_movie = Movie.new
      movie.each do |key, value|
        give_attribute(key, value, current_movie)
      end
      return current_movie
    end

    def self.give_attribute(key, value, movie)
      case key
      when "id"
        movie.rotten_tomatoes_id = value
      when "title"
        movie.title = value
      when "mpaaRating"
        movie.mpaa = value
      when "popcornScore"
        movie.audience_rating = value
      when "tomatoScore"
        movie.critic_rating = value
      when "posters"
        movie.poster = value["primary"]
      end
    end

    def self.scrape_individual(movie)
      movie_id = movie.rotten_tomatoes_id

      #duct tape code due to rottentomatoes' bugs
      movie_id = "enron_the_smartest_guys_in_the_room/" if movie_id == 24
      movie_id = "1144992-crash/" if movie_id == 12

      response = Nokogiri::HTML(open("http://www.rottentomatoes.com/m/#{movie_id}"))

      movie.netflixsource = get_netflixsource(response)
      movie.synopsis = get_synopsis(response)
      movie.poster = get_poster(response)
      movie.critic_consensus = get_critic_consensus(response)
      num_of_reviews = get_num_reviews(response)
      movie.review_count = num_of_reviews.to_i unless num_of_reviews.nil?

      movie.save!
    end

    def self.get_data(total)
      p2 = open("http://www.rottentomatoes.com/api/private/v1.0/m/list/find?minTomato=60&page=1&limit=#{total}&type=dvd-all&services=netflix_iw&sortBy=release")
      json = p2.read
      JSON.parse(json)["results"]
    end

    def self.get_total
      p2 = open("http://www.rottentomatoes.com/api/private/v1.0/m/list/find?minTomato=60&page=1&limit=30&type=dvd-all&services=netflix_iw&sortBy=release")
      json = p2.read
      JSON.parse(json)["counts"]["total"]
    end

    def self.give_attribute_full(movie)
      apikey = "5r8xr8cqaw9y3a2dhhtz2q7f"
      movie_id = movie.rotten_tomatoes_id
      response = open("http://api.rottentomatoes.com/api/public/v1.0/movies/#{movie.rotten_tomatoes_id}.json?apikey=#{apikey}").read
      attributes = JSON.parse(response)

      attributes.each do |key, value|
        case key
        when "year"
          movie.year = value
        when "genres"
          value = value.join(',')
          movie.genres = value
        when "mpaa_rating"
          movie.mpaa = value
        when "runtime"
          movie.runtime = value
        when "ratings"
          critics = value["critics_score"]
          audience = value["audience_score"]
          movie.critic_rating = critics
          movie.audience_rating = audience
        when "synopsis"
          movie.synopsis = value
        when "posters"
          movie.poster = value["detailed"]
        when "abridged_cast"
          names = value.map {|actor| actor['name'] }
          cast = names.join(', ')
          movie.cast = cast
        when "abridged_directors"
          names = value.map {|director| director['name'] }
          director = names.join(', ')
          movie.director = director
        end
      end

      return movie
    end

    def self.get_num_reviews(response)
      if response.css('#scoreStats div').length == 0
        return 0
      else
        return response.css('#scoreStats div')[1].children[3].text.strip
      end
    end

    def self.get_critic_consensus(response)
      if response.css('p.critic_consensus')[0].nil?
        return 'No consensus yet.'
      else
        return response.css('p.critic_consensus')[0].children[2].text.strip
      end
    end

    def self.get_netflixsource(response)
      if response.css('.streamNow').length == 0
        return ''
      else
        return response.css('.streamNow')[0]["href"].split('/WiMovie/')[1]
      end
    end

    def self.get_poster(response)
      response.css('div#topSection img[itemprop="image"]')[0].nil? ? nil : response.css('div#topSection img[itemprop="image"]')[0]["src"]
    end

    def self.get_synopsis(response)
      synopsis = iconvnize(response.css('#movieSynopsis').children[0].text).strip

      unless response.css('#movieSynopsisRemaining').length == 0
        second_synopsis = iconvnize(response.css('#movieSynopsisRemaining').children[0].text).strip
        synopsis = synopsis + ' ' + second_synopsis
      end

      synopsis
    end

    def self.iconvnize(text)
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      ic.iconv(text << ' ')[0..-2]
    end
end
