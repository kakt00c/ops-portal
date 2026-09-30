module NormalizedParams
  extend ActiveSupport::Concern

  INDEX_KEY = /\A\d+\z/

  private

  # Returns unpermitted params with only the keys of the `permitted` list (as passed to `permit`),
  # turning index-keyed hashes back into arrays for the keys permitted as arrays (`{ key => [] }`).
  #
  # Rack parses `foo[]=a&foo[]=b` as an array but `foo[0]=a&foo[1]=b` as a hash
  # keyed by "0", "1", ... Rails never generates the indexed form, but crawlers and
  # other tools re-serialize our links that way, so both forms should behave the same.
  def normalize_array_params(params, permitted)
    keys = permitted.flat_map { |entry| entry.is_a?(Hash) ? entry.keys : entry }.map(&:to_s)
    array_keys = permitted.grep(Hash).flat_map { |entry| entry.select { |_, value| value == [] }.keys }.map(&:to_s)

    normalized = params.to_unsafe_h.slice(*keys).to_h do |key, value|
      [ key, array_keys.include?(key) ? normalize_array_param(value) : value ]
    end

    ActionController::Parameters.new(normalized)
  end

  # Returns a hash keyed only by indexes as an Array ordered by index, anything else as is.
  def normalize_array_param(value)
    return value unless value.is_a?(Hash) && value.any? && value.keys.all? { |key| key.to_s.match?(INDEX_KEY) }

    value.sort_by { |key, _| key.to_s.to_i }.map(&:last)
  end
end
