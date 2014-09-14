class Movie < ActiveRecord::Base
  attr_accessible :rotten_tomatoes_id, :title, :year, :runtime, :critic_rating, :audience_rating,  :critic_consensus,  :synopsis,  :mpaa,  :netflixsource,  :poster,  :cast,  :director,  :genres, :review_count
	require 'open-uri'
	require 'iconv'
  def self.generate_database
		page = 1
		total_movies = 2820
		cookie = get_cookie

		until page > total_movies/20
	  	data = get_data(cookie, page)
		  data.each do |key, value|
		  	if movie_list?(key)
		  		value.each{|movie| add_netflixsource(movie)}
		  	end
		  end

		  page += 1
		  sleep(1)
		end
	end

	def self.create_new_movie(movie)
		current_movie = Movie.new
		movie.each do |key, value|
			give_attribute(key, value, current_movie)
		end
		current_movie.save!
	end

	def self.add_netflixsource(movie)
		old_movie = Movie.find_by_rotten_tomatoes_id(movie["id"])
		old_movie.netflixsource = movie["netflixsource"].split('/movies/')[1]
		old_movie.save!
	end

	def self.scrape_all_movies
		Movie.find_each do |movie|
			scrape_individual(movie)
		end
	end

	def self.scrape_individual(movie)
		movie_id = movie.rotten_tomatoes_id
		response = Nokogiri::HTML(open("http://www.rottentomatoes.com/m/#{movie_id}"))
		synopsis = get_synopsis(response)
		critic_consensus = response.css('p.critic_consensus')[0].text
		num_of_reviews = response.css('p.critic_stats span').select{|stat| stat["itemprop"] == "reviewCount"}[0].text
		num_of_reviews = num_of_reviews.to_i

		movie.update_attributes(:review_count => num_of_reviews, :critic_consensus => critic_consensus, :synopsis => synopsis)
		sleep(0.17)
	end

	def self.get_synopsis(response)
		if response.css('span#movieSynopsisRemaining').length == 0
			synopsis = response.css('p#movieSynopsis.movie_synopsis').text.strip
		else
			first_synopsis = response.css('p#movieSynopsis.movie_synopsis').text.split('$(')[0]
			second_synopsis = response.css('span#movieSynopsisRemaining').text
			synopsis = first_synopsis.gsub(second_synopsis,'').strip + ' ' + second_synopsis.strip
		end
		ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
		ic.iconv(synopsis << ' ')[0..-2]
	end

	def self.get_cookie
		response = open('http://www.rottentomatoes.com/dvd/netflix/#endyear=2014&exclude_rated=true&genres=1%3B2%3B4%3B5%3B6%3B8%3B9%3B10%3B11%3B12%3B18%3B14&maxtomato=100&mintomato=0&mpaa_max=6&mpaa_min=1&startyear=1920&wts_only=false')
		response.meta['set-cookie']
	end

	def self.get_data(cookie, page)
		p2 = open("http://www.rottentomatoes.com/api/private/v1.0/list/movies/netflix/?title=&celeb=&genre=1%3B2%3B4%3B5%3B6%3B8%3B9%3B10%3B11%3B12%3B18%3B14&minrating=1&maxrating=6&mintomato=0&maxtomato=100&minyear=1920&maxyear=2014&excludemymovies=true&wtsonly=false&sorttomato=false&page=#{page}",
          'Cookie' => cookie)
  	json = p2.read
  	JSON.parse(json)
	end

	def self.movie_list?(key)
		key == "movies"
	end

	def self.give_attribute(key, value, movie)
		case key
		when "id"
			movie.rotten_tomatoes_id = value
		when "title"
			movie.title = value
		when "netflixsource"
			movie.netflixsource = value.split('/movies/')[1]
		end
	end

	def self.fill_info_from_RT_api
		Movie.all.each do |movie|
			give_attribute_full(movie)
			sleep(1.1)
		end
	end

	def self.give_attribute_full(movie)
		apikey = "5r8xr8cqaw9y3a2dhhtz2q7f"
		movie_id = movie.rotten_tomatoes_id
		response = open("http://api.rottentomatoes.com/api/public/v1.0/movies/#{movie_id}.json?apikey=#{apikey}").read
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

  	movie.save!
	end
end
