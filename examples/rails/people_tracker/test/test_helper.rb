require_relative "../config/initializers/bazel_ruby_patches"

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Load schema once for in-memory database before fixtures
ActiveRecord::Tasks::DatabaseTasks.load_schema_current

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Use transactional tests for automatic rollback (this is the default)
    self.use_transactional_tests = true

    # Add more helper methods to be used by all tests here...
  end
end
