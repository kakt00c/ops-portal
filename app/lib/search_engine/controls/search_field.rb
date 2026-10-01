module SearchEngine
  module Controls
    class SearchField
      include ActiveModel::Conversion

      attr_reader :param_name, :label

      Filled = Struct.new(:control, :value, keyword_init: true) do
        delegate :to_partial_path, to: :control
      end

      def initialize(param_name:, label:, filter:)
        @param_name = param_name
        @label = label
        @filter = filter
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

        filter_result = RemoveFilter.new(
          label: @label,
          remove_filter_params: results.search_params.except(@param_name),
        )
        results.applied_filters << filter_result
      end

      def add_visible_filter(results)
        results.visible_filters << Filled.new(
          control: self,
          value: results.search_params[@param_name]
        )
      end
    end
  end
end
