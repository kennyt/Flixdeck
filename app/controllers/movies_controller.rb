class MoviesController < ApplicationController
	# require 'nokogiri'
	# require 'json'

	def show
		@movies = Movie.order('id').first(500)
	end
end