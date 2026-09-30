module SearchEngine
  module Controls
    class Hidden
      include ActiveModel::Conversion

      def initialize(param_name:, filter:, filter_label: -> { _1.join(", ") })
        @param_name = param_name
        @filter = filter
        @filter_label = filter_label
      end

      def apply(scope, params)
        return scope unless params[@param_name].present?
        @filter.call(scope, params)
      end

      def required_params
        [ @param_name ]
      end

      def add_applied_filter(results)
        return unless results.search_params[@param_name].present?

        values = Array(results.search_params[@param_name])

        results.applied_filters << RemoveFilter.new(
          label: @filter_label.respond_to?(:call) ? @filter_label.call(values) : @filter_label,
          remove_filter_params: results.search_params.except(@param_name),
        )
      end

      def add_visible_filter(results) end
    end
  end
end
