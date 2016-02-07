module ActsAsSaveable
  module Saver

    def self.included(base)

      # allow user to define these
      aliases = {
        :save_up_for    => [:likes, :upsaves, :up_saves],
        :save_down_for  => [:dislikes, :downsaves, :down_saves],
        :unsave_for     => [:unlike, :undislike],
        :saved_on?      => [:saved_for?],
        :saved_up_on?   => [:saved_up_for?, :liked?],
        :saved_down_on? => [:saved_down_for?, :disliked?],
        :saved_as_when_saving_on => [:saved_as_when_saved_on, :saved_as_when_saving_for, :saved_as_when_saved_for],
        :find_up_saved_items   => [:find_liked_items],
        :find_down_saved_items => [:find_disliked_items]
      }

      base.class_eval do

        has_many :saves, :class_name => 'ActsAsSaveable::Save', :as => :saver, :dependent => :destroy do
          def saveables
            includes(:saveable).map(&:saveable)
          end
        end

        aliases.each do |method, links|
          links.each do |new_method|
            alias_method(new_method, method)
          end
        end

      end

    end

    # saving
    def saved args
      args[:saveable].save_by args.merge({:saver => self})
    end

    def save_up_for model=nil, args={}
      saved :saveable => model, :save_scope => args[:save_scope], :saved => true
    end

    def save_down_for model=nil, args={}
      saved :saveable => model, :save_scope => args[:save_scope], :saved => false
    end

    def unsave_for model, args={}
      model.unsaved :saver => self, :save_scope => args[:save_scope]
    end

    # results
    def saved_on? saveable, args={}
      saves = find_saves(:saveable_id => saveable.id, :saveable_type => saveable.class.base_class.name,
                         :save_scope => args[:save_scope])
      saves.size > 0
    end

    def saved_up_on? saveable, args={}
      saves = find_saves(:saveable_id => saveable.id, :saveable_type => saveable.class.base_class.name,
                         :save_scope => args[:save_scope], :save_flag => true)
      saves.size > 0
    end

    def saved_down_on? saveable, args={}
      saves = find_saves(:saveable_id => saveable.id, :saveable_type => saveable.class.base_class.name,
                         :save_scope => args[:save_scope], :save_flag => false)
      saves.size > 0
    end

    def saved_as_when_saving_on saveable, args={}
      saved = find_saves(:saveable_id => saveable.id, :saveable_type => saveable.class.base_class.name,
                         :save_scope => args[:save_scope]).select(:save_flag).last
      return nil unless saved
      return saved.save_flag
    end

    def find_saves extra_conditions = {}
      saves.where(extra_conditions)
    end

    def find_up_saves args={}
      find_saves :save_flag => true, :save_scope => args[:save_scope]
    end

    def find_down_saves args={}
      find_saves :save_flag => false, :save_scope => args[:save_scope]
    end

    def find_saves_for_class klass, extra_conditions = {}
      find_saves extra_conditions.merge({:saveable_type => klass.name})
    end

    def find_up_saves_for_class klass, args={}
      find_saves_for_class klass, :save_flag => true, :save_scope => args[:save_scope]
    end

    def find_down_saves_for_class klass, args={}
      find_saves_for_class klass, :save_flag => false, :save_scope => args[:save_scope]
    end

    # Including polymporphic relations for eager loading
    def include_objects
      ActsAsSaveable::Save.includes(:saveable)
    end

    def find_saved_items extra_conditions = {}
      options = extra_conditions.merge :saver_id => id, :saver_type => self.class.base_class.name
      include_objects.where(options).collect(&:saveable)
    end

    def find_up_saved_items extra_conditions = {}
      find_saved_items extra_conditions.merge(:save_flag => true)
    end

    def find_down_saved_items extra_conditions = {}
      find_saved_items extra_conditions.merge(:save_flag => false)
    end

    def get_saved klass, extra_conditions = {}
      klass.joins(:saves_for).merge find_saves(extra_conditions)
    end

    def get_up_saved klass
      klass.joins(:saves_for).merge find_up_saves
    end

    def get_down_saved klass
      klass.joins(:saves_for).merge find_down_saves
    end
  end
end
