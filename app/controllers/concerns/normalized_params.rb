module NormalizedParams
  extend ActiveSupport::Concern

  INDEX_KEY = /\A\d+\z/

  private

  def normalize_array_params(params, permitted)
    permitted_params = params.to_unsafe_h.slice(*permitted_keys(permitted))

    array_keys(permitted).each do |key|
      permitted_params[key] = index_hash_to_array(permitted_params[key]) if index_hash?(permitted_params[key])
    end

    ActionController::Parameters.new(permitted_params)
  end

  def permitted_keys(permitted)
    permitted.flat_map { |entry| entry.is_a?(Hash) ? entry.keys : entry }.map(&:to_s)
  end

  def array_keys(permitted)
    permitted.grep(Hash).flat_map { |entry| entry.filter_map { |key, value| key.to_s if value == [] } }
  end

  def index_hash?(value)
    value.is_a?(Hash) && value.any? && value.keys.all? { |key| key.match?(INDEX_KEY) }
  end

  def index_hash_to_array(hash)
    hash.sort_by { |index, _| index.to_i }.map(&:last)
  end
end
