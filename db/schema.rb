# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140914001257) do

  create_table "movies", :force => true do |t|
    t.integer  "rotten_tomatoes_id"
    t.string   "title"
    t.integer  "year"
    t.integer  "runtime"
    t.integer  "critic_rating"
    t.integer  "audience_rating"
    t.text     "critic_consensus"
    t.text     "synopsis"
    t.string   "mpaa"
    t.string   "netflixsource"
    t.string   "poster"
    t.text     "cast"
    t.string   "director"
    t.string   "genres"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

end
