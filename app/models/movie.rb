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
      movie = make_or_update(movie)
      give_attribute_full(movie)
      scrape_individual(movie)
	  end
	end

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

	def self.add_netflixsource(movie)
		old_movie = Movie.find_by_rotten_tomatoes_id(movie["id"])
		old_movie.netflixsource = movie["netflixsource"].split('/movies/')[1]
		old_movie.save!
	end

	# def self.scrape_all_movies()
	# 	Movie.find_each(:start => 1050) do |movie|
	# 		scrape_individual(movie)
	# 	end
	# end

	def self.scrape_individual(movie)
		movie_id = movie.rotten_tomatoes_id

    #duct tape code due to rottentomatoes' bugs
		movie_id = "enron_the_smartest_guys_in_the_room/" if movie_id == 24
    movie_id = "1144992-crash/" if movie_id == 12

    #test 771374347
		response = Nokogiri::HTML(open("http://www.rottentomatoes.com/m/#{movie_id}"))

    movie.netflixsource = get_netflixsource(response)
    movie.synopsis = get_synopsis(response)
    movie.poster = get_poster(response)
    movie.critic_consensus = get_critic_consensus(response)
    num_of_reviews = get_num_reviews(response)
    movie.review_count = num_of_reviews.to_i unless num_of_reviews.nil?

    movie.save!
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

	# def self.get_cookie
	# 	response = open('http://www.rottentomatoes.com/dvd/netflix/#endyear=2014&exclude_rated=true&genres=1%3B2%3B4%3B5%3B6%3B8%3B9%3B10%3B11%3B12%3B18%3B14&maxtomato=100&mintomato=0&mpaa_max=6&mpaa_min=1&startyear=1920&wts_only=false')
	# 	response.meta['set-cookie']
	# end

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

	# def self.fill_info_from_RT_api
	# 	Movie.all.each do |movie|
	# 		give_attribute_full(movie)
	# 		sleep(1.1)
	# 	end
	# end

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

	# def self.fill_out_dummies
	# 	Movie.find_each do |movie|
	# 		movie.update_attributes(:runtime => 135, :critic_rating => 83, :audience_rating => 91, :critic_consensus => "A subversive and deft film. Will please moviegoers who are looking for art with their action. Also with flawless acting from Michael Bay, Tarantino, and De Niro.", :synopsis => "The success this underdog comedy from director Michael Ritchie almost single-handedly spawned the kids' sports film boom of the 1980s and '90s. When beer-breathed ex-minor-league ball player and professional pool cleaner Morris Buttermaker (Walter Matthau) agrees to coach a little league team in the San Fernando Valley, he soon finds he's in over his head, having inherited an assortment of pint-sized peons and talentless losers. They play well-organized teams and lose by tremendous margins, and the parents threaten to disband the Bears to save the kids (and themselves) any further embarrassment. Buttermaker refuses, though, and brings in a pair of ringers: Amanda (Tatum O'Neal), his ex-girlfriend's tomboy daughter, and Kelly (Jackie Earle Haley), a cigarette-smoking delinquent who happens to be a gifted athlete. With their help, the Bears manage to change their losing ways and qualify for the championship, where they face their arch-rivals, the Yankees. ~ Jeremy Beday, Rovi", :mpaa => "R", :netflixsource => "60021989", :poster => "http://content8.flixster.com/movie/11/17/81/11178198_det.jpg", :cast => "Michael Bay, De Niro, Quentin Tarantino, Tom Hanks", :director => "Paul Thomas Anderson", :genres => "Comedy, Action" )
	# 	end
	# end

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
