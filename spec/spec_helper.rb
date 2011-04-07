if ENV['__test_coverage__']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/autotest/'
    add_filter '/config/'
    add_filter '/db/'
    add_filter '/deploy/'
    add_filter '/doc/'
    add_filter '/features/'
    add_filter '/lib/jobs/'
    add_filter '/lib/tasks/'
    add_filter '/log/'
    add_filter '/public/'
    add_filter '/script/'
    add_filter '/spec/'
    add_filter '/test/'
    add_filter '/tmp/'
    add_filter '/vendor/'
    add_group 'Concerns', 'app/concerns'
    add_group 'Controllers', 'app/controllers'
    add_group 'Helpers', 'app/helpers'
    add_group 'Libraries', 'lib'
    add_group 'Mailers', 'app/mailers'
    add_group 'Models', 'app/models'
    add_group 'Presenters', 'app/presenters'
    add_group 'Observers', 'app/observers'
    add_group 'Services', 'app/services'
    #add_group 'Views', 'app/views'
  end
end

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)
require 'rspec/rails'
require 'webmock/rspec'
require 'email_spec'
require 'ostruct'
require 'paperclip/matchers'
require 'pp'
require 'database_cleaner'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Rspec.configure do |config|
  config.mock_with :rspec
  config.include CustomMatchers
  config.include WebMock::API
  config.include StubbedHttpRequests
  config.include Paperclip::Shoulda::Matchers
  config.include Devise::TestHelpers, :type => :controller
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.use_transactional_fixtures = true

  config.before :each do
    stub_contribution_urls
    stub_amazon_s3_request
  end
  config.after :each do
  end
  config.before :all do
    DatabaseCleaner.start
    stub_contribution_urls
    stub_amazon_s3_request
  end
  config.after :all do
    DatabaseCleaner.clean
  end
end
