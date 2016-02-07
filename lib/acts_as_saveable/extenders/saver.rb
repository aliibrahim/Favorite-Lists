module ActsAsSaveable
  module Extenders

    module Saver

      def saver?
        false
      end

      def acts_as_saver(*args)
        require 'acts_as_saveable/saver'
        include ActsAsSaveable::Saver

        class_eval do
          def self.saver?
            true
          end
        end

      end

    end
  end
end
