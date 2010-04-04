require 'rubygems'

gem 'activerecord', ENV['AR_VERSION'] ? "=#{ENV['AR_VERSION']}" : '>=2.1.0'
require 'active_record'

ActiveRecord::Base.establish_connection({'adapter' => 'sqlite3', 'database' => ':memory:'})
ActiveRecord::Base.logger = Logger.new("#{File.dirname(__FILE__)}/active_record.log")
cx = ActiveRecord::Base.connection

cx.create_table(:things, :force=>true) do |t|

end
cx.create_table(:one_manies, :force=>true) do |t|

end
cx.create_table(:many_manies, :force=>true) do |t|

end
cx.create_table(:many_manies_things, :force=>true) do |t|

end
cx.create_table(:manies_one, :force=>true) do |t|

end

#basic_associations
connection.create_table(:companies, :force=>true) do |t|
  t.string :name
  t.string :status
end
connection.create_table(:contract_workers, :force=>true) do |t|
  t.references :company
  t.references :contractor
  t.string :status
end
connection.create_table(:licenses, :force=>true) do |t|
  t.references :company
  t.string :status
end
connection.create_table(:contractors, :force=>true) do |t|
  t.string :name
  t.string :status
end
connection.create_table(:employees, :force=>true) do |t|
  t.references :company
  t.string :name
  t.string :status
end

#polymorphic_associations
connection.create_table(:comments, :force=>true) do |t|
  t.references :document, :polymorphic=>true
  t.text :comment
  t.string :status
end
connection.create_table(:articles, :force=>true) do |t|
  t.string :name
  t.string :status
end
connection.create_table(:images, :force=>true) do |t|
  t.string :name
  t.string :status
end
