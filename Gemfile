source 'https://rubygems.org'

ruby '2.2.1'

gem 'rails', '~> 4.1.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

gem 'translation_engine', github: 'camsys/translation_engine'
#gem 'translation_engine', path: '~/code/translation_engine'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'pg'
gem 'cancancan', '~> 1.10.1'
gem 'devise', '~> 3.4.1'
gem 'devise_account_expireable', '~> 0.0.2'

# gem 'devise_security_extension', '~> 0.9.2'
# Use specific commit to fix password_salt error, until new version released
gem 'devise_security_extension', :git => 'git://github.com/phatworx/devise_security_extension.git', :ref => '2132a72d'

# RADAR v3.x will support ActiveRecord 4.2
gem 'rgeo'
gem 'activerecord-postgis-adapter', '~> 2.2.1'

# Manage app-specific cron tasks using a Ruby DSL, see config/schedule.rb
gem 'whenever', '~> 0.9.4', :require => false

# RADAR current version is 0.13.0, but schedule_atts requires > 0.7.0
gem 'ice_cube', '~> 0.6.8'

# Fork with Rails 4.x compatibility
gem 'jc-validates_timeliness', '~> 3.1.1'

# For attachment processing. Using Fog for storage so that we can use
# AWS SDK v2 separately for other tasks.
gem 'paperclip', '~> 4.3.0'
gem 'fog', '~> 1.32.0'
gem 'remotipart', '~> 1.2' # allows remote multipart (file upload) forms

gem 'will_paginate', '~> 3.0.7'
gem 'attribute_normalizer', '~> 1.2.0'

# For Address Uploading
# Note: not used by Paperclip internally per
# https://github.com/thoughtbot/paperclip/issues/1764
gem 'aws-sdk', '~> 2.1.8'

# For change tracking and auditing
gem 'paper_trail', '~> 4.0.0.rc'

gem 'rails-jquery-autocomplete', '~> 1.0.0'
# needed for trip address picker
gem 'twitter-typeahead-rails', github: 'camsys/twitter-typeahead-rails'
gem 'handlebars_assets'

# RADAR Not updated since 2011, used by RecurringTrip model
# TODO could recurring_select gem replace this?
gem 'schedule_atts', :git => 'git://github.com/zpearce/Schedule-Attributes.git'

gem 'haml'

# ENV var management
gem 'figaro'

# datatables
gem 'jquery-datatables-rails', '~> 3.3.0'

# bootstrap
gem 'bootstrap-sass', '~> 3.3.5'

# soft-delete
gem "paranoia", "~> 2.0"

# Manage application-level settings
gem 'rails-settings-cached', '~> 0.4.1'

# Use redis as the cache_store for Rails
gem 'redis-rails', '~> 4.0.0'

# font-awesome icons
gem "font-awesome-rails"

# jQuery full calendar plugin with resource views
gem 'rails-fullcalendar-resourceviews', '~> 1.6.5.7', github: 'xudongcamsys/rails-fullcalendar-resourceviews'

# overcome IE9 4096 per stylesheet limit
gem 'css_splitter'

# background workder
gem 'sidekiq'

# Form helper for accepts_nested_attributes_for
gem 'nested_form', '~> 0.3.2'

# reporting engine
gem 'reporting', :github => 'camsys/reporting', :branch => 'master'

# styling
gem 'bootstrap-kaminari-views'

# momentjs for datetime parsing
gem 'momentjs-rails'

# phone number validation and display
gem 'phony_rails'

# logging activities for Tracker Action Log
gem 'public_activity'

# twitter typeahed
#gem 'twitter-typeahead-rails'

# new relic for app monitoring
gem 'newrelic_rpm'

# Printing
gem 'wicked_pdf'

# In-line editing
gem 'bootstrap-editable-rails'

group :integration, :qa, :production do
  gem 'rails_12factor'
  gem 'unicorn'
  gem 'rack-timeout'
  gem 'wkhtmltopdf-binary'
end

group :development do
  # preview mail in dev
  gem "letter_opener"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem "spring-commands-rspec"
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :production do
  gem 'exception_notification', '~> 4.0'
end

group :test, :development do
  gem 'byebug'
  gem 'rspec-rails', '~> 3.2'
  gem 'capybara', '~> 2.4'
  gem 'factory_girl_rails', '~> 4.5'
  gem 'database_cleaner', '~> 1.4'
  gem 'faker', '~> 1.4'
  gem 'timecop', '~> 0.8'
end

group :test do
  gem 'launchy'
  gem 'selenium-webdriver'
end

# Support code coverage analysis with Coveralls
gem 'coveralls', require: false
