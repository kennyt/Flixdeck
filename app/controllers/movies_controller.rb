class MoviesController < ApplicationController
	# require 'nokogiri'
	# require 'json'

	def show
		@movies = Movie.limit(30)
	end
end