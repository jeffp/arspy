require 'rubygems'

gem 'activerecord', ENV['AR_VERSION'] ? "=#{ENV['AR_VERSION']}" : '>=2.3.2'
require 'active_record'

ActiveRecord::Base.establish_connection({'adapter' => 'sqlite3', 'database' => ':memory:'})
ActiveRecord::Base.logger = Logger.new("#{File.dirname(__FILE__)}/active_record.log")
cx = ActiveRecord::Base.connection

cx.create_table(:users, :force=>true) do |t|
  t.string :first_name
  t.string :last_name
  t.integer :age
  t.boolean :active
end
class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through=>:friendships
  has_many :blogs
  has_many :comments
  
  def full_name; "#{first_name} #{last_name}"; end
end

cx.create_table(:friendships, :force=>true) do |t|
  t.references :user
  t.references :friend
  t.integer :years_known
end
class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :class=>'User'
end


fnames = ['John', 'Ted', 'Jan', 'Beth', 'Mark', 'Mary']
lnames = ['Patrick', 'Hanson', 'Partrich', 'Meyers', 'Dougherty', 'Smith']
Factory.define(:user) do |f|
  f.sequence(:first_name) {|n| fnames[n]}
  f.sequence(:last_name) {|n| lnames[n]}
end

users=Hash[*fnames.map{|fn| [fn.downcase.to_sym, Factory(:user)]}.flatten]

friends = {
  :john => [:beth, :mark],
  :ted => [:jan, :beth, :john],
  :jan => [:ted, :john, :jan, :beth, :mark],
  :beth => [:john],
  :mark => [:john, :jan]
}
friends.each do |user, friends_list|
  friends_list.each do |friend|
    users[user].friends << users[friend]
  end
end


cx.create_table(:images, :force=>true) do |t|
  t.string :caption
  t.integer :size
end
class Image < ActiveRecord::Base
  has_many :blog, :as=>:asset
end

cx.create_table(:recordings, :force=>true) do |t|
  t.string :title
  t.integer :duration
end
class Recording < ActiveRecord::Base
  has_many :blog, :as=>:asset
end

images = ['dogs', 'cats', 'rabbits'].map_with_index do |name, index|
  Image.create(:caption=>name, :size=>index*1024)
end
recordings = ['kittens', 'puppies', 'parrots'].map_with_index do |name, index|
  Recording.create(:title=>name, :duration=>10*index)
end

cx.create_table(:blogs, :force=>true) do |t|
  t.references :user
  t.string :title
  t.datetime :published_at
  t.references :asset, :polymorphic=>true, :null=>true
end
class Blog < ActiveRecord::Base
  belongs_to :user
  belongs_to :asset, :polymorphic=>true
  has_many :comments
end
dates = [2.months.ago, 4.months.ago, 6.months.ago, 8.months.ago]
Factory.define(:blog) do |f|
  f.title 'lipsum orem'
  f.sequence(:published_at){|n| dates[n%dates.size]}
end

cx.create_table(:comments, :force=>true) do |t|
  t.references :user
  t.references :blog
  t.string :content
end
class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :blog
end

comments = ['I agree', 'I disagree', 'I like it.', 'I do not like it at all.']


