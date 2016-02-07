require 'acts_as_saveable/helpers/words'

module ActsAsSaveable
  module Saveable

    include Helpers::Words

    def self.included base

      # allow the user to define these himself
      aliases = {

        :save_up => [
          :upsaved_by, :upsave_from, :upsave_by, :save_from
        ],

        :save_down => [
          :downsave_by, :downsave_from, :downsaved_by, :downsave_from
        ],

        :get_up_saves => [
          :get_true_saves, :get_upsaves, :get_for_saves
        ],

        :get_down_saves => [
          :get_false_saves, :get_downsaves
        ],
        :unsave_by => [
          :unsave_up, :unsave_down
        ]
      }

      base.class_eval do
        has_many :saves_for, :class_name => 'ActsAsSaveable::Save', :as => :saveable, :dependent => :destroy do
          def savers
            includes(:saver).map(&:saver)
          end
        end

        aliases.each do |method, links|
          links.each do |new_method|
            alias_method(new_method, method)
          end
        end

      end
    end

    attr_accessor :save_registered

    def save_registered?
      return self.save_registered
    end

    def default_conditions
      {
        :saveable_id => self.id,
        :saveable_type => self.class.base_class.name.to_s
      }
    end

    # saving
    def save_by args = {}

      options = {
        :saved => true,
        :save_scope => nil
      }.merge(args)

      self.save_registered = false

      if options[:saver].nil?
        return false
      end

      # find the saved
      _saves_ = find_saves_for({
        :saver_id => options[:saver].id,
        :save_scope => options[:save_scope],
        :saver_type => options[:saver].class.base_class.name
      })

      if _saves_.count == 0 or options[:duplicate]
        # this saver has never saved
        saved = ActsAsSaveable::Save.new(
          :saveable => self,
          :saver => options[:saver],
          :save_scope => options[:save_scope]
        )
      else
        # this saver is potentially changing his saved
        saved = _saves_.last
      end

      last_update = saved.updated_at

      saved.save_flag = saveable_words.meaning_of(options[:saved])

      #Allowing for a save_weight to be associated with every saved. Could change with every saver object
      saved.save_weight = (options[:save_weight].to_i if options[:save_weight].present?) || 1

      if saved.save
        self.save_registered = true if last_update != saved.updated_at
        update_cached_saves options[:save_scope]
        return true
      else
        self.save_registered = false
        return false
      end

    end

    def unsaved args = {}
      return false if args[:saver].nil?
      _saves_ = find_saves_for(:saver_id => args[:saver].id, :save_scope => args[:save_scope], :saver_type => args[:saver].class.base_class.name)

      return true if _saves_.size == 0
      _saves_.each(&:destroy)
      update_cached_saves args[:save_scope]
      self.save_registered = false if saves_for.count == 0
      return true
    end

    def save_up saver, options={}
      self.save_by :saver => saver, :saved => true, :save_scope => options[:save_scope], :save_weight => options[:save_weight]
    end

    def save_down saver, options={}
      self.save_by :saver => saver, :saved => false, :save_scope => options[:save_scope], :save_weight => options[:save_weight]
    end

    def unsave_by  saver, options = {}
      self.unsaved :saver => saver, :save_scope => options[:save_scope] #Does not need save_weight since the saves_for are anyway getting destroyed
    end

    def scope_cache_field field, save_scope
      return field if save_scope.nil?

      case field
      when :cached_saves_total=
        "cached_scoped_#{save_scope}_saves_total="
      when :cached_saves_total
        "cached_scoped_#{save_scope}_saves_total"
      when :cached_saves_up=
        "cached_scoped_#{save_scope}_saves_up="
      when :cached_saves_up
        "cached_scoped_#{save_scope}_saves_up"
      when :cached_saves_down=
        "cached_scoped_#{save_scope}_saves_down="
      when :cached_saves_down
        "cached_scoped_#{save_scope}_saves_down"
      when :cached_saves_score=
        "cached_scoped_#{save_scope}_saves_score="
      when :cached_saves_score
        "cached_scoped_#{save_scope}_saves_score"
      when :cached_weighted_total
        "cached_weighted_#{save_scope}_total"
      when :cached_weighted_total=
        "cached_weighted_#{save_scope}_total="
      when :cached_weighted_score
        "cached_weighted_#{save_scope}_score"
      when :cached_weighted_score=
        "cached_weighted_#{save_scope}_score="
      when :cached_weighted_average
        "cached_weighted_#{save_scope}_average"
      when :cached_weighted_average=
        "cached_weighted_#{save_scope}_average="
      end
    end

    # caching
    def update_cached_saves save_scope = nil

      updates = {}

      if self.respond_to?(:cached_saves_total=)
        updates[:cached_saves_total] = count_saves_total(true)
      end

      if self.respond_to?(:cached_saves_up=)
        updates[:cached_saves_up] = count_saves_up(true)
      end

      if self.respond_to?(:cached_saves_down=)
        updates[:cached_saves_down] = count_saves_down(true)
      end

      if self.respond_to?(:cached_saves_score=)
        updates[:cached_saves_score] = (
          (updates[:cached_saves_up] || count_saves_up(true)) -
          (updates[:cached_saves_down] || count_saves_down(true))
        )
      end

      if self.respond_to?(:cached_weighted_total=)
        updates[:cached_weighted_total] = weighted_total(true)
      end

      if self.respond_to?(:cached_weighted_score=)
        updates[:cached_weighted_score] = weighted_score(true)
      end

      if self.respond_to?(:cached_weighted_average=)
        updates[:cached_weighted_average] = weighted_average(true)
      end

      if save_scope
        if self.respond_to?(scope_cache_field :cached_saves_total=, save_scope)
          updates[scope_cache_field :cached_saves_total, save_scope] = count_saves_total(true, save_scope)
        end

        if self.respond_to?(scope_cache_field :cached_saves_up=, save_scope)
          updates[scope_cache_field :cached_saves_up, save_scope] = count_saves_up(true, save_scope)
        end

        if self.respond_to?(scope_cache_field :cached_saves_down=, save_scope)
          updates[scope_cache_field :cached_saves_down, save_scope] = count_saves_down(true, save_scope)
        end

        if self.respond_to?(scope_cache_field :cached_weighted_total=, save_scope)
          updates[scope_cache_field :cached_weighted_total, save_scope] = weighted_total(true, save_scope)
        end

        if self.respond_to?(scope_cache_field :cached_weighted_score=, save_scope)
          updates[scope_cache_field :cached_weighted_score, save_scope] = weighted_score(true, save_scope)
        end

        if self.respond_to?(scope_cache_field :cached_saves_score=, save_scope)
          updates[scope_cache_field :cached_saves_score, save_scope] = (
            (updates[scope_cache_field :cached_saves_up, save_scope] || count_saves_up(true, save_scope)) -
            (updates[scope_cache_field :cached_saves_down, save_scope] || count_saves_down(true, save_scope))
          )
        end

        if self.respond_to?(scope_cache_field :cached_weighted_average=, save_scope)
          updates[scope_cache_field :cached_weighted_average, save_scope] = weighted_average(true, save_scope)
        end
      end

      if (::ActiveRecord::VERSION::MAJOR == 3) && (::ActiveRecord::VERSION::MINOR != 0)
        self.update_attributes(updates, :without_protection => true) if updates.size > 0
      else
        self.update_attributes(updates) if updates.size > 0
      end

    end


    # results
    def find_saves_for extra_conditions = {}
      saves_for.where(extra_conditions)
    end

    def get_up_saves options={}
      save_scope_hash = scope_or_empty_hash(options[:save_scope])
      find_saves_for({:save_flag => true}.merge(save_scope_hash))
    end

    def get_down_saves options={}
      save_scope_hash = scope_or_empty_hash(options[:save_scope])
      find_saves_for({:save_flag => false}.merge(save_scope_hash))
    end


    # counting
    def count_saves_total skip_cache = false, save_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_saves_total, save_scope)
        return self.send(scope_cache_field :cached_saves_total, save_scope)
      end
      find_saves_for(scope_or_empty_hash(save_scope)).count
    end

    def count_saves_up skip_cache = false, save_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_saves_up, save_scope)
        return self.send(scope_cache_field :cached_saves_up, save_scope)
      end
      get_up_saves(:save_scope => save_scope).count
    end

    def count_saves_down skip_cache = false, save_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_saves_down, save_scope)
        return self.send(scope_cache_field :cached_saves_down, save_scope)
      end
      get_down_saves(:save_scope => save_scope).count
    end

    def weighted_total skip_cache = false, save_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_total, save_scope)
        return self.send(scope_cache_field :cached_weighted_total, save_scope)
      end
      ups = get_up_saves(:save_scope => save_scope).sum(:save_weight)
      downs = get_down_saves(:save_scope => save_scope).sum(:save_weight)
      ups + downs
    end

    def weighted_score skip_cache = false, save_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_score, save_scope)
        return self.send(scope_cache_field :cached_weighted_score, save_scope)
      end
      ups = get_up_saves(:save_scope => save_scope).sum(:save_weight)
      downs = get_down_saves(:save_scope => save_scope).sum(:save_weight)
      ups - downs
    end

    def weighted_average skip_cache = false, save_scope = nil
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_average, save_scope)
        return self.send(scope_cache_field :cached_weighted_average, save_scope)
      end

      count = count_saves_total(skip_cache, save_scope).to_i
      if count > 0
        weighted_score(skip_cache, save_scope).to_f / count
      else
        0.0
      end
    end

    # savers
    def saved_on_by? saver
      saves = find_saves_for :saver_id => saver.id, :saver_type => saver.class.base_class.name
      saves.count > 0
    end

    private

    def scope_or_empty_hash(save_scope)
      save_scope ? { :save_scope => save_scope } : {}
    end
  end
end
