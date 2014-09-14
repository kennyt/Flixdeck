class MoviesController < ApplicationController
	# require 'nokogiri'
	# require 'json'

	def show
		@movies = Movie.first(500)
	end
end