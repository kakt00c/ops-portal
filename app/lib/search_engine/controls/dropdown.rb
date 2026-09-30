module SearchEngine
  module Controls
    class Dropdown
      include ActiveModel::Conversion

      attr_reader :name, :label, :items

      Item = Struct.new(:label, :value, :selected, :add_params, :remove_params, keyword_init: true) do
        def selected?
          selected
        end
      end

      Filled = Struct.new(:control, :value, :items, :default_label, :multiple, keyword_init: true) do
        delegate :to_partial_path, to: :control
      end

      def initialize(param_name:, label:, items:, filter:, filter_label: -> { _1 }, multiple: true, default_label: "Všetko", sort: true)
        @param_name = param_name
        @label = label
        @items = items
        @filter = filter
        @filter_label = filter_label
        @multiple = multiple
        @default_label = default_label
        @sort = sort
      end

      def apply(scope, params)
        return scope unless params[@param_name].present?
        @filter.call(scope, params)
      end

      def required_params
        [ @param_name, { @param_name => [] } ] # allow arrays too
      end

      def add_applied_filter(results)
        return unless results.search_params[@param_name].present?

        values = Array(results.search_params[@param_name])

        values.each do |value|
          results.applied_filters << RemoveFilter.new(
            label: @filter_label.respond_to?(:call) ? @filter_label.call(value) : @filter_label,
            remove_filter_params: results.search_params.merge(@param_name => (values - [ value ]).uniq),
          )
        end
      end

      def build_items(results, items)
        if items.respond_to?(:call)
          items = items.arity == 1 ? items.call(results.search_params) : items.call
        end

        values = Array(results.search_params[@param_name])

        out = items.map do |value|
          Item.new(
            label: value,
            value: value,
            selected: values.include?(value),
            add_params: results.search_params.merge(@param_name => @multiple ? (values + [ value ]).uniq : value),
            remove_params: results.search_params.merge(@param_name => @multiple ? (values - [ value ]).uniq : nil),
          )
        end

        out = out.partition(&:selected?).flatten if @sort

        out
      end

      def add_visible_filter(results)
        items_data = build_items(results, @items)
        return if items_data.empty?

        results.visible_filters << Filled.new(
          control: self,
          value: results.search_params[@param_name],
          items: items_data,
          default_label: @default_label,
          multiple: @multiple,
        )
      end
    end
  end
end
