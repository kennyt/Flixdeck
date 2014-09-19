class Movie < ActiveRecord::Base
  attr_accessible :rotten_tomatoes_id, :title, :year, :runtime, :critic_rating, :audience_rating,  :critic_consensus,  :synopsis,  :mpaa,  :netflixsource,  :poster,  :cast,  :director,  :genres, :review_count
	require 'open-uri'
	require 'iconv'
	require 'cgi'

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

	def self.scrape_all_movies()
		Movie.find_each(:start => 1050) do |movie|
			scrape_individual(movie)
		end
	end

	def self.scrape_individual(movie)
		movie_id = movie.rotten_tomatoes_id
		movie_id = "enron_the_smartest_guys_in_the_room/" if movie_id == 24
		response = Nokogiri::HTML(open("http://www.rottentomatoes.com/m/#{movie_id}"))
		poster = response.css('img.pinterestImage')[0].nil? ? nil : response.css('img.pinterestImage')[0]['src']

		movie.update_attributes(:poster => poster)
		sleep(0.3)
	end

	def self.get_synopsis_consensus_reviews
		synopsis = get_synopsis(response)
		critic_consensus = response.css('p.critic_consensus').length == 0 ? 'No consensus.' : response.css('p.critic_consensus')[0].text
		num_of_reviews = response.css('p.critic_stats span').select{|stat| stat["itemprop"] == "reviewCount"}[0]
		num_of_reviews = num_of_reviews.text.to_i unless num_of_reviews.nil?
	end

	def self.get_synopsis(response)
		if response.css('span#movieSynopsisRemaining').length == 0
			synopsis = iconvnize(response.css('p#movieSynopsis.movie_synopsis').text.strip)
		else
			first_synopsis = iconvnize(response.css('p#movieSynopsis.movie_synopsis').text).split('$(')[0]
			second_synopsis = iconvnize(response.css('span#movieSynopsisRemaining').text)
			synopsis = first_synopsis.gsub(second_synopsis,'').strip + ' ' + second_synopsis.strip
		end

		synopsis
	end

	def self.iconvnize(text)
		ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
		ic.iconv(text << ' ')[0..-2]
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

	def unescape_html
		self.update_attribute(:title, CGI.unescapeHTML(title))
	end

	def self.unescape_all
		Movie.find_each do |movie|
			movie.unescape_html
		end
	end

	def self.fill_out_dummies
		Movie.find_each do |movie|
			movie.update_attributes(:runtime => 135, :critic_rating => 83, :audience_rating => 91, :critic_consensus => "A subversive and deft film. Will please moviegoers who are looking for art with their action. Also with flawless acting from Michael Bay, Tarantino, and De Niro.", :synopsis => "The success this underdog comedy from director Michael Ritchie almost single-handedly spawned the kids' sports film boom of the 1980s and '90s. When beer-breathed ex-minor-league ball player and professional pool cleaner Morris Buttermaker (Walter Matthau) agrees to coach a little league team in the San Fernando Valley, he soon finds he's in over his head, having inherited an assortment of pint-sized peons and talentless losers. They play well-organized teams and lose by tremendous margins, and the parents threaten to disband the Bears to save the kids (and themselves) any further embarrassment. Buttermaker refuses, though, and brings in a pair of ringers: Amanda (Tatum O'Neal), his ex-girlfriend's tomboy daughter, and Kelly (Jackie Earle Haley), a cigarette-smoking delinquent who happens to be a gifted athlete. With their help, the Bears manage to change their losing ways and qualify for the championship, where they face their arch-rivals, the Yankees. ~ Jeremy Beday, Rovi", :mpaa => "R", :netflixsource => "60021989", :poster => "http://content8.flixster.com/movie/11/17/81/11178198_det.jpg", :cast => "Michael Bay, De Niro, Quentin Tarantino, Tom Hanks", :director => "Paul Thomas Anderson", :genres => "Comedy, Action" )
		end
	end

	def self.get_random(genre, min_score)
		min_score -= 1
		if genre
			genre = "%#{genre}%"
	 		Movie.where(["critic_rating > ? and review_count > ? and genres LIKE ?", min_score, 20, genre]).order("RANDOM()").limit(1)[0]
	 	else
			Movie.where(["critic_rating > ? and review_count > ?", min_score, 20]).order("RANDOM()").limit(1)[0]
	 	end
	end

	def self.get_genre(num, genre)
		genre = "%#{genre}%"
		Movie.where(["critic_rating > ? and review_count > ? and genres LIKE ?", 59, 20, genre]).order("RANDOM()").limit(num)
	end

	def self.get_ordered_genre(num, genre)
		genre = "%#{genre}%"
		Movie.where(["critic_rating > ? and review_count > ? and genres LIKE ?", 59, 20, genre]).order("critic_rating DESC").limit(num)
	end

	def self.get_ultra(num)
		Movie.where(["critic_rating > ? and review_count > ?", 89, 20]).order("RANDOM()").limit(num)
	end

	def self.all_genres
		genres = ["Drama", "Romance", "Comedy", "Mystery & Suspense", "Action & Adventure", "Documentary", "Horror", "Special Interest", "Art House & International", "Science Fiction & Fantasy", "Musical & Performing Arts", "Faith & Spirituality", "Animation", "Kids & Family", "Sports & Fitness", "Classics", "Western", "Television", "Cult Movies", "Gay & Lesbian", "Anime & Manga"]
	end

	def self.generate_genre_list
		genres = []
		Movie.find_each do |movie|
			movie.genres.split(',').each do |genre|
				next if genres.include?(genre)
				genres << genre
			end
		end
		genres
	end

	def self.manual_and_natural_genres
		natural_genres = self.generate_genre_list

		self.all_genres.select do |genre|
			!natural_genres.include?(genre)
		end
	end

	def self.give_random_critic_rating
		Movie.find_each do |movie|
			movie.update_attribute(:critic_rating, rand(100))
		end
	end
end
