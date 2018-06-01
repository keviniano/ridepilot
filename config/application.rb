require File.expand_path('../boot', __FILE__)

require 'rails/all'
require './app/controllers/concerns/json_response_helper.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ridepilot
  class ActiveRecordOverrideRailtie < Rails::Railtie
    initializer "active_record.initialize_database.override" do |app|

      ActiveSupport.on_load(:active_record) do
        if url = ENV['DATABASE_URL']
          ApplicationRecord.connection_pool.disconnect!
          parsed_url = URI.parse(url)
          config =  {
            adapter:             'postgis',
            host:                parsed_url.host,
            encoding:            'unicode',
            database:            parsed_url.path.split("/")[-1],
            port:                parsed_url.port,
            username:            parsed_url.user,
            password:            parsed_url.password
          }
          establish_connection(config)
        end
      end
    end
  end
  
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += %W(#{config.root}/app/services/distance_duration_services)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rails -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Mountain Time (US & Canada)'

    config.i18n.enforce_available_locales = false
    config.i18n.default_locale = :en

    config.action_controller.per_form_csrf_tokens = true

    # become time zone aware
    config.active_record.time_zone_aware_types = [:datetime, :time]

    # Set default CORS settings
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # /http:\/\/localhost:(\d*)/
        resource '*',
          # headers: ['Origin', 'X-Requested-With', 'Content-Type', 'Accept',
          #   'Authorization', 'X-User-Token', 'X-User-Email',
          #   'Access-Control-Request-Headers', 'Access-Control-Request-Method'
          # ],
          headers: :any, # fixes CORS errors on OPTIONS requests
          methods: [:get, :post, :put, :delete, :options]
        end
    end

    # Sends back appropriate JSON 400 response if a bad JSON request is sent.
    config.middleware.insert_before Rack::Head, JsonResponseHelper::CatchJsonParseErrors

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
      
      # It is suggested to leave these all enabled
      # g.request_specs false
      # g.routing_specs false
      # g.controller_specs false
      # g.model_specs false
    end
    
    # Use Redis as the cache_store if it's available
    if ENV["REDISCLOUD_URL"]
      config.cache_store = :redis_store, ENV["REDISCLOUD_URL"], { expires_in: 90.minutes }
    end
  end
end
