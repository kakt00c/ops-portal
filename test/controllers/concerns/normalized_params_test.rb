require "test_helper"

class NormalizedParamsTest < ActiveSupport::TestCase
  include NormalizedParams

  PERMITTED = [ :kategoria, { kategoria: [] }, :obec, { obec: [] }, :stav, :page ].freeze

  test "turns index-keyed hashes into arrays ordered by index" do
    normalized = normalize("kategoria[1]=B&kategoria[0]=A&kategoria[10]=C&obec[0]=X")

    assert_equal [ "A", "B", "C" ], normalized[:kategoria]
    assert_equal [ "X" ], normalized[:obec]
  end

  test "keeps arrays and scalars as they are" do
    normalized = normalize("kategoria[]=A&kategoria[]=B&stav=Novy&page=2")

    assert_equal [ "A", "B" ], normalized[:kategoria]
    assert_equal "Novy", normalized[:stav]
    assert_equal "2", normalized[:page]
  end

  test "does not turn index-keyed hashes into arrays for keys not permitted as arrays" do
    normalized = normalize("stav[0]=Novy")

    assert_equal({ "0" => "Novy" }, normalized[:stav].to_unsafe_h)
    assert_empty normalized.permit(*PERMITTED).to_h
  end

  test "keeps hashes with non-index keys so permit drops them" do
    normalized = normalize("kategoria[foo]=bar&obec[0]=X&obec[x]=Y")

    assert_empty normalized.permit(*PERMITTED).to_h
  end

  test "returns only the listed keys, unpermitted" do
    normalized = normalize("kategoria=A&tab=map&utm_source=x")

    assert_not normalized.permitted?
    assert_equal({ "kategoria" => "A" }, normalized.to_unsafe_h)
  end

  private

  def normalize(query)
    normalize_array_params(ActionController::Parameters.new(Rack::Utils.parse_nested_query(query)), PERMITTED)
  end
end
