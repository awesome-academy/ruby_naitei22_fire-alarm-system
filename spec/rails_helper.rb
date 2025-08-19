require "simplecov"
require "simplecov-rcov"

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter
]

SimpleCov.start "rails" do
  add_filter "/bin/"
  add_filter "/db/"
  add_filter "/spec/"
end

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

Rails.application.eager_load!

require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.fixture_path = Rails.root.join("spec/fixtures")

  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
end
