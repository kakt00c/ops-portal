ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "webmock/minitest"
require_relative "support/municipality_boundary_test_helper"

Minitest.load_plugins
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    include MunicipalityBoundaryTestHelper

    # PostGIS does not handle process forking well and can cause segfaults
    # in the pg gem when running tests in parallel. Disable parallelization
    # to ensure stable test runs.
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used all tests here...

    # Use the test adapter for Active Job
    ActiveJob::Base.queue_adapter = :test
  end
end
