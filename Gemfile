source "https://rubygems.org"

gem "dotenv", groups: [ :development, :test ]

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

gem "rails-i18n", "~> 8.1.0"

gem "dartsass-rails" # temporarily use sass

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
# gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

gem "exif"

gem "zammad_api"

gem "faraday-patron"
gem "open-uri"
gem "jwt"


group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "pry"
  gem "minitest"
  gem "minitest-mock"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "faker"
  gem "simplecov"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "foreman"
  gem "annotaterb"
  gem "letter_opener_web"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock"
end

gem "good_job"

gem "rack-cors"

# Auth
gem "rodauth-rails", "~> 2.1"
gem "rodauth-i18n"
gem "rodauth-omniauth", "~> 0.6"
gem "omniauth-facebook", "~> 10.0"
gem "omniauth-google-oauth2", "~> 1.2"

# Used by Rodauth. Enables Sequel to use Active Record's database connection
gem "sequel-activerecord_connection", "~> 2.0"
# Used by Rodauth for password hashing
gem "bcrypt", "~> 3.1"
# Used by Rodauth for rendering built-in view and email templates
gem "tilt", "~> 2.4"

# deployment
gem "kamal", "~> 2.6"

# pagination
gem "kaminari"

gem "discourse_api"

gem "aws-sdk-s3"
gem "aws-sdk-pinpointsmsvoicev2"

gem "rollbar"

gem "email_reply_parser"

gem "sitemap_generator"
