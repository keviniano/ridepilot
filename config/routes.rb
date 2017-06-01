Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.

  scope "(:locale)", locale: TranslationEngine.available_locales do

    mount TranslationEngine::Engine => "/translation_engine"

    root :to => "trips_runs#index"

    get "admin", :controller => :home, :action => :index

    devise_for :users

    devise_scope :user do
      get "new_user" => "users#new_user"
      post "create_user" => "users#create_user"
      get "show_change_password" => "users#show_change_password"
      patch "change_password"  => "users#change_password"
      get "show_change_email" => "users#show_change_email"
      patch "change_email"  => "users#change_email"
      get "show_change_expiration" => "users#show_change_expiration"
      patch "change_expiration"  => "users#change_expiration"
      post "change_provider" => "users#change_provider"
      get "check_session" => "users#check_session"
      get "touch_session" => "users#touch_session"
      get "restore_user" => "users#restore"
    end

    resources :users, only: [:show, :edit, :update] do 
      member do 
        get :show_reset_password
        patch :reset_password
      end
    end

    resource :application_settings, only: [:edit, :update] do
      collection do
        get :index
      end
    end

    resources :customers do
      post :inactivate, :as => :inactivate
      post :activate, :as => :activate

      collection do
        get :autocomplete
        get :found
        get :search
        post :data_for_trip
      end

      member do
        get :delete_photo
      end
    end

    resources :trips do
      post :confirm
      post :no_show
      post :reached
      post :send_to_cab
      post :turndown
      patch :callback
      patch :change_result

      member do
        get :clone
        get :return
      end

      collection do
        get :reconcile_cab
        get :trips_requiring_callback
        get :unscheduled
        get :customer_trip_summary
        post :check_double_booked
      end
    end

    resources :repeating_trips do
      collection do
        get :clone_from_daily_trip
      end
    end
    resources :repeating_runs

    resources :providers, :except => [:edit, :update, :destroy] do
      post :change_role
      post :delete_role
      member do
        post :change_cab_enabled
        post :change_reimbursement_rates
        post :change_scheduling
        post :change_run_tracking
        post :change_advance_day_scheduling
        post :change_eligible_age
        post :change_fields_required_for_run_completion
        post :save_region
        post :save_viewport
        patch :save_operating_hours
      end
    end

    resources :recurring_driver_compliances do
      collection do
        get :schedule_preview
        get :future_schedule_preview
        get :compliance_based_schedule_preview
        put :generate, action: "generate!"
      end
      member do
        get :delete
      end
    end

    resources :recurring_vehicle_maintenance_compliances do
      collection do
        get :schedule_preview
        get :future_schedule_preview
        get :compliance_based_schedule_preview
        put :generate, action: "generate!"
      end
      member do
        get :delete
      end
    end

    resources :provider_common_addresses, :only => [:create, :edit, :update, :destroy] do
      collection do
        get :search
        patch :upload
        get :autocomplete
      end
    end
    get "check_address_loading_status" => "provider_common_addresses#check_loading_status"

    resources :addresses, :only => [] do
      collection do
        post :validate_customer_specific
        get :autocomplete_public
      end
    end
    get "trip_address_autocomplete" => "addresses#trippable_autocomplete"

    resources :device_pools, :except => [:index, :show] do
      resources :device_pool_drivers, :only => [:create, :destroy]
    end

    resources :drivers do
      member do
        get :delete_photo
        get :check_time_range_availability
      end

      resources :documents, except: [:index, :show]
      resources :driver_histories, except: [:index, :show]
      resources :driver_compliances, except: [:index, :show]
    end
    resources :monthlies, :except => [:show, :destroy]
    resources :vehicles do
      resources :documents, except: [:index, :show]
      resources :vehicle_maintenance_events, :except => [:index, :show]
      resources :vehicle_maintenance_compliances, :except => [:index, :show]
      resources :vehicle_warranties, :except => [:index, :show]

      member do 
        get  :edit_initial_mileage
        post :update_initial_mileage
      end
    end

    resources :runs do
      collection do
        get :for_date
        get :uncompleted_runs
        patch :cancel_multiple
        delete :delete_multiple
      end
    end

    resources :trips_runs, only: [:index] do
      collection do
        post :schedule
        get :runs_by_date
      end
    end

    resources :cab_trips, :only => [:index] do
      collection do
        get :edit_multiple
        put :update_multiple
      end
    end

    scope :via => :post, :constraints => { :format => "json" , :protocol => "https://" } do
      match "device_pool_drivers/" => "v1/device_pool_drivers#index", :as => "v1_device_pool_drivers"
      match "v1/device_pool_drivers/:id" => "v1/device_pool_drivers#update", :as => "v1_device_pool_driver"
    end

    get "dispatch", :controller => :dispatch, :action => :index
    #get "reports", :controller=>:reports, :action=>:index
    get "custom_reports/:id", :controller=>:reports, :action=>:show, as: :custom_report
    get "reports/:action", :controller=>:reports
    get "reports/:action/:id", :controller=>:reports
    # reporting engine
    mount Reporting::Engine, at: "/reporting"


    get "test_exception_notification" => "application#test_exception_notification"

    resources :lookup_tables, :only => [:index, :show] do
      member do
        post :add_value
        put :update_value
        put :destroy_value
        put :hide_value
        put :show_value
      end
    end
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      match "authenticate_customer", :controller => :customers, :action => :show, :via => [:get, :options]
      match "authenticate_provider", :controller => :providers, :action => :show, :via => [:get, :options]
      match "trip_purposes", :controller => :trip_purposes, :action => :index, :via => [:get, :options]
      match "create_trip", :controller => :trips, :action => :create, :via => [:post, :options]
      match "cancel_trip", :controller => :trips, :action => :destroy, :via => [:delete, :options]
      match "trip_status", :controller => :trips, :action => :show, :via => [:get, :options]
    end
  end
end
