class ActsAsSaveableMigration < ActiveRecord::Migration
  def self.up
    create_table :saves do |t|

      t.references :saveable, :polymorphic => true
      t.references :saver, :polymorphic => true

      t.boolean :save_flag
      t.string :save_scope
      t.integer :save_weight

      t.timestamps
    end

    if ActiveRecord::VERSION::MAJOR < 4
      add_index :saves, [:saveable_id, :saveable_type]
      add_index :saves, [:saver_id, :saver_type]
    end

    add_index :saves, [:saver_id, :saver_type, :save_scope]
    add_index :saves, [:saveable_id, :saveable_type, :save_scope]
  end

  def self.down
    drop_table :saves
  end
end
