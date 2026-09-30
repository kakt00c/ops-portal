require "test_helper"
require "test_helpers/api_helper"

class Api::V1::ResponsibleSubjectControllerTest < ActionDispatch::IntegrationTest
  include ApiHelper

  test "index lists active responsible subjects" do
    get api_v1_responsible_subjects_url

    assert_response :success
    response.parsed_body.each { |rs| assert_json_schema({ id: Integer, name: String }, rs) }
    names = response.parsed_body.map { |rs| rs["name"] }
    assert_includes names, responsible_subjects(:one).subject_name
    assert_not_includes names, responsible_subjects(:archived).subject_name
  end

  test "search matches the beginning of the name or of a word in it" do
    get search_api_v1_responsible_subjects_url(q: "bv")
    assert_equal [ { "id" => responsible_subjects(:two).id, "name" => "BVS" } ], response.parsed_body

    get search_api_v1_responsible_subjects_url(q: "staré")
    assert_equal [ responsible_subjects(:one).subject_name ], response.parsed_body.map { |rs| rs["name"] }

    get search_api_v1_responsible_subjects_url(q: "zrušený")
    assert_equal [], response.parsed_body
  end
end
