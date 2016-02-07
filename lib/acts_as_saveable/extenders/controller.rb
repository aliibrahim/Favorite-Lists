module ActsAsSaveable
  module Extenders

    module Controller

      def saver_params(params_object = params[:saved])
        params_object.permit(:saveable_id, :saveable_type,
          :saver_id, :saver_type,
          :saveable, :saver,
          :save_flag, :save_scope)
      end

      def saveable_params(params_object = params[:saved])
        params_object.permit(:save_registered)
      end

    end
  end
end
