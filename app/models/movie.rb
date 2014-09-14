class Movie < ActiveRecord::Base
  attr_accessible :rotten_tomatoes_id, :title, :year
	require 'open-uri'
  def self.generate_database
		page = 1
		total_movies = 2820
		cookie = get_cookie

		until page > total_movies/20
	  	data = get_data(cookie, page)
		  data.each do |key, value|
		  	if movie_list?(key)
		  		value.each{|movie| create_new_movie(movie)}
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
		end
	end
end
