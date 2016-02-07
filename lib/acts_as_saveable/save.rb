require 'acts_as_saveable/helpers/words'

module ActsAsSaveable
  class Save < ::ActiveRecord::Base

    include Helpers::Words

    if defined?(ProtectedAttributes) || ::ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :saveable_id, :saveable_type,
        :saver_id, :saver_type,
        :saveable, :saver,
        :save_flag, :save_scope
    end

    belongs_to :saveable, :polymorphic => true
    belongs_to :saver, :polymorphic => true

    scope :up, lambda{ where(:save_flag => true) }
    scope :down, lambda{ where(:save_flag => false) }
    scope :for_type, lambda{ |klass| where(:saveable_type => klass) }
    scope :by_type,  lambda{ |klass| where(:saver_type => klass) }

    validates_presence_of :saveable_id
    validates_presence_of :saver_id

  end

end
