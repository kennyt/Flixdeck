class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
    	t.integer :rotten_tomatoes_id
    	t.string :title
    	t.integer :year
    	t.integer :runtime
    	t.integer :critic_rating
    	t.integer :audience_rating
    	t.text :critic_consensus
    	t.text :synopsis
    	t.string :mpaa
    	t.string :netflixsource
    	t.string :poster
    	t.text :cast
    	t.string :director
    	t.string :genres

      t.timestamps
    end
  end
end