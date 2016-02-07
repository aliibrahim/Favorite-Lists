require 'active_record'
require 'active_support/inflector'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module ActsAsSaveable

  if defined?(ActiveRecord::Base)
    require 'acts_as_saveable/extenders/saveable'
    require 'acts_as_saveable/extenders/saver'
    require 'acts_as_saveable/save'
    ActiveRecord::Base.extend ActsAsSaveable::Extenders::Saveable
    ActiveRecord::Base.extend ActsAsSaveable::Extenders::Saver
  end

end

require 'acts_as_saveable/extenders/controller'
ActiveSupport.on_load(:action_controller) do
  include ActsAsSaveable::Extenders::Controller
end
