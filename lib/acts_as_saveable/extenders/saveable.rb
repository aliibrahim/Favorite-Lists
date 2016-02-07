module ActsAsSaveable
  module Extenders

    module Saveable

      def saveable?
        false
      end

      def acts_as_saveable
        require 'acts_as_saveable/saveable'
        include ActsAsSaveable::Saveable

        class_eval do
          def self.saveable?
            true
          end
        end

      end

    end

  end
end
