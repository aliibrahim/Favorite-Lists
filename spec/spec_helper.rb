$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'sqlite3'
require 'acts_as_saveable'

Dir["./spec/shared_example/**/*.rb"].sort.each {|f| require f}
Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :saves do |t|
    t.references :saveable, :polymorphic => true
    t.references :saver, :polymorphic => true

    t.boolean :save_flag
    t.string :save_scope
    t.integer :save_weight

    t.timestamps
  end

  add_index :saves, [:saveable_id, :saveable_type]
  add_index :saves, [:saver_id, :saver_type]
  add_index :saves, [:saver_id, :saver_type, :save_scope]
  add_index :saves, [:saveable_id, :saveable_type, :save_scope]

  create_table :savers do |t|
    t.string :name
  end

  create_table :not_savers do |t|
    t.string :name
  end

  create_table :saveables do |t|
    t.string :name
  end

  create_table :saveable_savers do |t|
    t.string :name
  end

  create_table :sti_saveables do |t|
    t.string :name
    t.string :type
  end

  create_table :sti_not_saveables do |t|
    t.string :name
    t.string :type
  end

  create_table :not_saveables do |t|
    t.string :name
  end

  create_table :saveable_caches do |t|
    t.string :name
    t.integer :cached_saves_total
    t.integer :cached_saves_score
    t.integer :cached_saves_up
    t.integer :cached_saves_down
    t.integer :cached_weighted_total
    t.integer :cached_weighted_score
    t.float :cached_weighted_average

    t.integer :cached_scoped_test_saves_total
    t.integer :cached_scoped_test_saves_score
    t.integer :cached_scoped_test_saves_up
    t.integer :cached_scoped_test_saves_down
    t.integer :cached_scoped_weighted_total
    t.integer :cached_scoped_weighted_score
    t.float :cached_scoped_weighted_average
  end

end


class Saver < ActiveRecord::Base
  acts_as_saver
end

class NotSaver < ActiveRecord::Base

end

class Saveable < ActiveRecord::Base
  acts_as_saveable
  validates_presence_of :name
end

class SaveableSaver < ActiveRecord::Base
  acts_as_saveable
  acts_as_saver
end

class StiSaveable < ActiveRecord::Base
  acts_as_saveable
end

class ChildOfStiSaveable < StiSaveable
end

class StiNotSaveable < ActiveRecord::Base
  validates_presence_of :name
end

class SaveableChildOfStiNotSaveable < StiNotSaveable
  acts_as_saveable
end

class NotSaveable < ActiveRecord::Base
end

class SaveableCache < ActiveRecord::Base
  acts_as_saveable
  validates_presence_of :name
end

class ABoringClass
  def self.hw
    'hello world'
  end
end


def clean_database
  models = [ActsAsSaveable::Save, Saver, NotSaver, Saveable, NotSaveable, SaveableCache]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end
