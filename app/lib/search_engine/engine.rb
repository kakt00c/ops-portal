module SearchEngine
  class Engine
    def initialize(filters:, sorts: [], per_page: nil)
      @filters = filters
      @sorts = sorts
      @per_page = per_page
    end

    def required_params
      @filters.flat_map(&:required_params) + [ :sort, :page ]
    end

    def search(scope, permitted_params)
      results = build_results_with_filters(permitted_params)
      search_params = results.search_params

      scope = apply_filters(scope, search_params)
      scope = apply_sort(scope, search_params)

      scope = scope.page(search_params[:page])
      scope = scope.per(@per_page) if @per_page

      results.hits = scope

      results
    end

    def stats(scope, permitted_params, &block)
      results = build_results_with_filters(permitted_params)

      scope = apply_filters(scope, results.search_params)

      scope = scope.reorder("") # reset order due to optional fulltext search

      block.call(scope, results) if block_given?

      results
    end

    private

    def apply_filters(scope, params)
      @filters.each do |filter|
        scope = filter.apply(scope, params)
      end

      scope
    end

    def apply_sort(scope, params)
      @sorts.each do |sort|
        scope = sort.apply(scope, params)
      end

      scope
    end

    def build_results_with_filters(permitted_params)
      results = Results.new
      results.search_params = permitted_params.to_h.with_indifferent_access

      @filters.each do |filter|
        filter.add_applied_filter(results)
      end

      @filters.each do |filter|
        filter.add_visible_filter(results)
      end

      @sorts.each do |sort|
        sort.add_sort(results)
      end

      results
    end
  end
end
