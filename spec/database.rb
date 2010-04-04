require 'rubygems'

gem 'activerecord', ENV['AR_VERSION'] ? "=#{ENV['AR_VERSION']}" : '>=2.3.2'
require 'active_record'

ActiveRecord::Base.establish_connection({'adapter' => 'sqlite3', 'database' => ':memory:'})
ActiveRecord::Base.logger = Logger.new("#{File.dirname(__FILE__)}/active_record.log")
cx = ActiveRecord::Base.connection

cx.create_table(:people, :force=>true) do |t|
  t.string :first_name
  t.string :last_name
  t.integer :age
  t.boolean :active
end

class Person < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through=>:friendships
  has_many :blogs
  has_many :comments
  
  def full_name; "#{first_name} #{last_name}"; end
end

cx.create_table(:friendships, :force=>true) do |t|
  t.references :person
  t.references :friend
  t.integer :years_known
end

class Friendship < ActiveRecord::Base
  belongs_to :person
  belongs_to :friend, :class=>'Person'
end

cx.create_table(:blogs, :force=>true) do |t|
  t.references :person
  t.string :title
  t.datetime :published_at
  t.references :asset, :polymorphic=>true
end

class Blog < ActiveRecord::Base
  belongs_to :person
  belongs_to :asset, :polymorphic=>true
  has_many :comments
end

cx.create_table(:comments, :force=>true) do |t|
  t.references :person
  t.references :blog
  t.string :content
end

class Comment < ActiveRecord::Base
  belongs_to :person
  belongs_to :blog
end

cx.create_table(:images, :force=>true) do |t|
  t.string :caption
  t.integer :size
end

class Image < ActiveRecord::Base
  has_one :blog, :as=>:asset
end

cx.create_table(:recordings, :force=>true) do |t|
  t.string :title
  t.integer :duration
end

class Recording < ActiveRecord::Base
  has_one :blog, :as=>:asset
end



