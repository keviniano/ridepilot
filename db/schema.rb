# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171206164011) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "postgis_topology"
  enable_extension "fuzzystrmatch"
  enable_extension "uuid-ossp"

  create_table "activities", force: true do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "key"
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], :name => "index_activities_on_owner_id_and_owner_type"
  add_index "activities", ["recipient_id", "recipient_type"], :name => "index_activities_on_recipient_id_and_recipient_type"
  add_index "activities", ["trackable_id", "trackable_type"], :name => "index_activities_on_trackable_id_and_trackable_type"

  create_table "ada_questions", force: true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ada_questions", ["provider_id"], :name => "index_ada_questions_on_provider_id"

  create_table "address_groups", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "address_upload_flags", force: true do |t|
    t.boolean  "is_loading",          default: false
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "last_upload_summary"
  end

  add_index "address_upload_flags", ["provider_id"], :name => "index_address_upload_flags_on_provider_id"

  create_table "addresses", force: true do |t|
    t.string   "name"
    t.string   "building_name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.boolean  "in_district"
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                                                                  default: 0
    t.string   "phone_number"
    t.boolean  "inactive",                                                                      default: false
    t.string   "trip_purpose_old"
    t.spatial  "the_geom",             limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.integer  "trip_purpose_id"
    t.text     "notes"
    t.datetime "deleted_at"
    t.integer  "customer_id"
    t.boolean  "is_driver_associated",                                                          default: false
    t.boolean  "is_user_associated"
    t.string   "type"
    t.integer  "address_group_id"
  end

  add_index "addresses", ["address_group_id"], :name => "index_addresses_on_address_group_id"
  add_index "addresses", ["customer_id"], :name => "index_addresses_on_customer_id"
  add_index "addresses", ["deleted_at"], :name => "index_addresses_on_deleted_at"
  add_index "addresses", ["provider_id"], :name => "index_addresses_on_provider_id"
  add_index "addresses", ["the_geom"], :name => "index_addresses_on_the_geom", :spatial => true
  add_index "addresses", ["trip_purpose_id"], :name => "index_addresses_on_trip_purpose_id"

  create_table "addresses_customers_old", force: true do |t|
    t.integer  "customer_id"
    t.integer  "address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "addresses_customers_old", ["address_id"], :name => "index_addresses_customers_old_on_address_id"
  add_index "addresses_customers_old", ["customer_id"], :name => "index_addresses_customers_old_on_customer_id"

  create_table "booking_users", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "url"
    t.uuid     "token",      default: "uuid_generate_v4()"
  end

  add_index "booking_users", ["user_id"], :name => "index_booking_users_on_user_id"

  create_table "boolean_lookup", force: true do |t|
    t.string "name", limit: 16
    t.string "note", limit: 16
  end

  create_table "capacities", force: true do |t|
    t.integer  "capacity_type_id"
    t.integer  "capacity"
    t.integer  "host_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
  end

  add_index "capacities", ["capacity_type_id"], :name => "index_capacities_on_capacity_type_id"
  add_index "capacities", ["host_id"], :name => "index_capacities_on_host_id"

  create_table "capacity_types", force: true do |t|
    t.string   "name"
    t.integer  "provider_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "capacity_types", ["provider_id"], :name => "index_capacity_types_on_provider_id"

  create_table "custom_reports", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "redirect_to_results", default: false
    t.string   "title"
    t.string   "version"
  end

  create_table "customer_ada_questions", force: true do |t|
    t.integer  "customer_id"
    t.integer  "ada_question_id"
    t.boolean  "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customer_ada_questions", ["ada_question_id"], :name => "index_customer_ada_questions_on_ada_question_id"
  add_index "customer_ada_questions", ["customer_id"], :name => "index_customer_ada_questions_on_customer_id"

  create_table "customer_address_types", force: true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "deleted_at"
  end

  create_table "customer_eligibilities", force: true do |t|
    t.integer  "customer_id"
    t.integer  "eligibility_id"
    t.text     "ineligible_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "eligible"
  end

  add_index "customer_eligibilities", ["customer_id"], :name => "index_customer_eligibilities_on_customer_id"
  add_index "customer_eligibilities", ["eligibility_id"], :name => "index_customer_eligibilities_on_eligibility_id"

  create_table "customers", force: true do |t|
    t.string   "first_name"
    t.string   "middle_initial"
    t.string   "last_name"
    t.string   "phone_number_1"
    t.string   "phone_number_2"
    t.integer  "address_id"
    t.string   "email"
    t.date     "activated_date"
    t.date     "inactivated_date"
    t.string   "inactivated_reason"
    t.date     "birth_date"
    t.integer  "mobility_id"
    t.text     "mobility_notes"
    t.string   "ethnicity"
    t.text     "emergency_contact_notes"
    t.text     "private_notes"
    t.text     "public_notes"
    t.integer  "provider_id"
    t.boolean  "group",                        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                 default: 0
    t.boolean  "medicaid_eligible"
    t.string   "prime_number"
    t.integer  "default_funding_source_id"
    t.boolean  "ada_eligible"
    t.string   "service_level_old"
    t.integer  "service_level_id"
    t.boolean  "is_elderly"
    t.string   "gender"
    t.datetime "deleted_at"
    t.text     "message"
    t.string   "token"
    t.boolean  "active"
    t.date     "inactivated_start_date"
    t.date     "inactivated_end_date"
    t.text     "active_status_changed_reason"
    t.text     "comments"
    t.text     "ada_ineligible_reason"
    t.string   "code"
  end

  add_index "customers", ["address_id"], :name => "index_customers_on_address_id"
  add_index "customers", ["default_funding_source_id"], :name => "index_customers_on_default_funding_source_id"
  add_index "customers", ["deleted_at"], :name => "index_customers_on_deleted_at"
  add_index "customers", ["mobility_id"], :name => "index_customers_on_mobility_id"
  add_index "customers", ["provider_id"], :name => "index_customers_on_provider_id"
  add_index "customers", ["service_level_id"], :name => "index_customers_on_service_level_id"

  create_table "customers_providers", id: false, force: true do |t|
    t.integer "provider_id"
    t.integer "customer_id"
  end

  add_index "customers_providers", ["customer_id", "provider_id"], :name => "index_customers_providers_on_customer_id_and_provider_id"
  add_index "customers_providers", ["customer_id"], :name => "index_customers_providers_on_customer_id"
  add_index "customers_providers", ["provider_id"], :name => "index_customers_providers_on_provider_id"

  create_table "daily_operating_hours", force: true do |t|
    t.date     "date"
    t.time     "start_time"
    t.time     "end_time"
    t.integer  "operatable_id"
    t.string   "operatable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_all_day",      default: false
    t.boolean  "is_unavailable",  default: false
  end

  create_table "device_pool_drivers", force: true do |t|
    t.string   "status"
    t.float    "lat"
    t.float    "lng"
    t.integer  "device_pool_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "driver_id"
    t.datetime "posted_at"
    t.integer  "vehicle_id"
  end

  add_index "device_pool_drivers", ["device_pool_id"], :name => "index_device_pool_drivers_on_device_pool_id"
  add_index "device_pool_drivers", ["driver_id"], :name => "index_device_pool_drivers_on_driver_id"
  add_index "device_pool_drivers", ["vehicle_id"], :name => "index_device_pool_drivers_on_vehicle_id"

  create_table "device_pools", force: true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.string   "color"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "device_pools", ["deleted_at"], :name => "index_device_pools_on_deleted_at"
  add_index "device_pools", ["provider_id"], :name => "index_device_pools_on_provider_id"

  create_table "document_associations", force: true do |t|
    t.integer  "document_id"
    t.integer  "associable_id"
    t.string   "associable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "document_associations", ["associable_id", "associable_type"], :name => "index_document_associations_on_associable_id_and_associable_typ"
  add_index "document_associations", ["document_id", "associable_id", "associable_type"], :name => "index_document_associations_document_id_associable"
  add_index "document_associations", ["document_id"], :name => "index_document_associations_on_document_id"

  create_table "documents", force: true do |t|
    t.integer  "documentable_id"
    t.string   "documentable_type"
    t.string   "description"
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "documents", ["documentable_id", "documentable_type"], :name => "index_documents_on_documentable_id_and_documentable_type"

  create_table "donations", force: true do |t|
    t.datetime "date"
    t.float    "amount"
    t.text     "notes"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.integer  "user_id"
    t.integer  "trip_id"
  end

  add_index "donations", ["customer_id"], :name => "index_donations_on_customer_id"
  add_index "donations", ["trip_id"], :name => "index_donations_on_trip_id"
  add_index "donations", ["user_id"], :name => "index_donations_on_user_id"

  create_table "driver_compliances", force: true do |t|
    t.integer  "driver_id"
    t.string   "event"
    t.text     "notes"
    t.date     "due_date"
    t.date     "compliance_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "recurring_driver_compliance_id"
    t.boolean  "legal"
    t.integer  "driver_requirement_template_id"
  end

  add_index "driver_compliances", ["driver_id"], :name => "index_driver_compliances_on_driver_id"
  add_index "driver_compliances", ["driver_requirement_template_id"], :name => "index_driver_compliances_on_driver_requirement_template_id"
  add_index "driver_compliances", ["recurring_driver_compliance_id"], :name => "index_driver_compliances_on_recurring_driver_compliance_id"

  create_table "driver_histories", force: true do |t|
    t.integer  "driver_id"
    t.string   "event"
    t.text     "notes"
    t.date     "event_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "driver_histories", ["driver_id"], :name => "index_driver_histories_on_driver_id"

  create_table "driver_requirement_templates", force: true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.boolean  "legal"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reoccuring"
    t.datetime "deleted_at"
  end

  add_index "driver_requirement_templates", ["provider_id"], :name => "index_driver_requirement_templates_on_provider_id"

  create_table "drivers", force: true do |t|
    t.boolean  "active"
    t.boolean  "paid"
    t.integer  "provider_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                 default: 0
    t.integer  "user_id"
    t.string   "email"
    t.integer  "address_id"
    t.datetime "deleted_at"
    t.string   "phone_number"
    t.integer  "alt_address_id"
    t.string   "alt_phone_number"
    t.date     "inactivated_start_date"
    t.date     "inactivated_end_date"
    t.text     "active_status_changed_reason"
  end

  add_index "drivers", ["address_id"], :name => "index_drivers_on_address_id"
  add_index "drivers", ["alt_address_id"], :name => "index_drivers_on_alt_address_id"
  add_index "drivers", ["deleted_at"], :name => "index_drivers_on_deleted_at"
  add_index "drivers", ["provider_id"], :name => "index_drivers_on_provider_id"
  add_index "drivers", ["user_id"], :name => "index_drivers_on_user_id"

  create_table "eligibilities", force: true do |t|
    t.string   "code",        null: false
    t.string   "description", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emergency_contacts", force: true do |t|
    t.integer  "geocoded_address_id"
    t.integer  "driver_id"
    t.string   "name"
    t.string   "phone_number"
    t.string   "relationship"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "ethnicities", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "ethnicities", ["deleted_at"], :name => "index_ethnicities_on_deleted_at"

  create_table "field_configs", force: true do |t|
    t.integer  "provider_id",                 null: false
    t.string   "table_name",                  null: false
    t.string   "field_name",                  null: false
    t.boolean  "visible",     default: true
    t.boolean  "required",    default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "field_configs", ["provider_id"], :name => "index_field_configs_on_provider_id"

  create_table "funding_authorization_numbers", force: true do |t|
    t.integer  "funding_source_id"
    t.integer  "customer_id"
    t.string   "number"
    t.text     "contact_info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "funding_authorization_numbers", ["customer_id"], :name => "index_funding_authorization_numbers_on_customer_id"
  add_index "funding_authorization_numbers", ["funding_source_id"], :name => "index_funding_authorization_numbers_on_funding_source_id"

  create_table "funding_source_visibilities", force: true do |t|
    t.integer "funding_source_id"
    t.integer "provider_id"
  end

  add_index "funding_source_visibilities", ["funding_source_id"], :name => "index_funding_source_visibilities_on_funding_source_id"
  add_index "funding_source_visibilities", ["provider_id"], :name => "index_funding_source_visibilities_on_provider_id"

  create_table "funding_sources", force: true do |t|
    t.string   "name"
    t.datetime "deleted_at"
    t.integer  "provider_id"
  end

  add_index "funding_sources", ["deleted_at"], :name => "index_funding_sources_on_deleted_at"
  add_index "funding_sources", ["provider_id"], :name => "index_funding_sources_on_provider_id"

  create_table "hidden_lookup_table_values", force: true do |t|
    t.integer  "provider_id"
    t.string   "table_name"
    t.integer  "value_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hidden_lookup_table_values", ["provider_id"], :name => "index_hidden_lookup_table_values_on_provider_id"

  create_table "images", force: true do |t|
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "images", ["imageable_id", "imageable_type"], :name => "index_images_on_imageable_id_and_imageable_type"

  create_table "locales", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_tables", force: true do |t|
    t.string   "caption"
    t.string   "name"
    t.string   "value_column_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "add_value_allowed",       default: true
    t.boolean  "edit_value_allowed",      default: true
    t.boolean  "delete_value_allowed",    default: true
    t.string   "model_name"
    t.string   "code_column_name"
    t.string   "description_column_name"
  end

  create_table "mobilities", force: true do |t|
    t.string   "name"
    t.datetime "deleted_at"
  end

  add_index "mobilities", ["deleted_at"], :name => "index_mobilities_on_deleted_at"

  create_table "monthlies", force: true do |t|
    t.date     "start_date"
    t.integer  "volunteer_escort_hours"
    t.integer  "volunteer_admin_hours"
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",           default: 0
    t.integer  "funding_source_id"
  end

  add_index "monthlies", ["funding_source_id"], :name => "index_monthlies_on_funding_source_id"
  add_index "monthlies", ["provider_id"], :name => "index_monthlies_on_provider_id"

  create_table "old_passwords", force: true do |t|
    t.string   "encrypted_password",       null: false
    t.string   "password_archivable_type", null: false
    t.integer  "password_archivable_id",   null: false
    t.datetime "created_at"
  end

  add_index "old_passwords", ["password_archivable_type", "password_archivable_id"], :name => "index_password_archivable"

  create_table "operating_hours", force: true do |t|
    t.integer  "operatable_id"
    t.integer  "day_of_week"
    t.time     "start_time"
    t.time     "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "operatable_type"
    t.boolean  "is_all_day",      default: false
    t.boolean  "is_unavailable",  default: false
  end

  add_index "operating_hours", ["operatable_id", "operatable_type"], :name => "index_operating_hours_on_operatable_id_and_operatable_type"
  add_index "operating_hours", ["operatable_id"], :name => "index_operating_hours_on_operatable_id"

  create_table "planned_leaves", force: true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.text     "reason"
    t.integer  "leavable_id"
    t.string   "leavable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "planned_leaves", ["leavable_id", "leavable_type"], :name => "index_planned_leaves_on_leavable_id_and_leavable_type"

  create_table "provider_lookup_tables", force: true do |t|
    t.string   "caption"
    t.string   "name"
    t.string   "value_column_name"
    t.string   "model_name"
    t.string   "code_column_name"
    t.string   "description_column_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "provider_reports", force: true do |t|
    t.integer  "provider_id"
    t.integer  "custom_report_id"
    t.boolean  "inactive"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "provider_reports", ["custom_report_id"], :name => "index_provider_reports_on_custom_report_id"
  add_index "provider_reports", ["provider_id"], :name => "index_provider_reports_on_provider_id"

  create_table "providers", force: true do |t|
    t.string   "name"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.boolean  "dispatch"
    t.boolean  "scheduling"
    t.integer  "viewport_zoom"
    t.boolean  "allow_trip_entry_from_runs_page"
    t.decimal  "oaa3b_per_ride_reimbursement_rate",                                                                        precision: 8, scale: 2
    t.decimal  "ride_connection_per_ride_reimbursement_rate",                                                              precision: 8, scale: 2
    t.decimal  "trimet_per_ride_reimbursement_rate",                                                                       precision: 8, scale: 2
    t.decimal  "stf_van_per_ride_reimbursement_rate",                                                                      precision: 8, scale: 2
    t.decimal  "stf_taxi_per_ride_administrative_fee",                                                                     precision: 8, scale: 2
    t.decimal  "stf_taxi_per_ride_ambulatory_load_fee",                                                                    precision: 8, scale: 2
    t.decimal  "stf_taxi_per_ride_wheelchair_load_fee",                                                                    precision: 8, scale: 2
    t.decimal  "stf_taxi_per_mile_ambulatory_reimbursement_rate",                                                          precision: 8, scale: 2
    t.decimal  "stf_taxi_per_mile_wheelchair_reimbursement_rate",                                                          precision: 8, scale: 2
    t.spatial  "region_nw_corner",                                limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.spatial  "region_se_corner",                                limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.spatial  "viewport_center",                                 limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.text     "fields_required_for_run_completion"
    t.datetime "deleted_at"
    t.integer  "min_trip_time_gap_in_mins",                                                                                                        default: 30
    t.boolean  "customer_nonsharable",                                                                                                             default: false
    t.datetime "inactivated_date"
    t.string   "inactivated_reason"
    t.integer  "advance_day_scheduling"
    t.boolean  "cab_enabled"
    t.integer  "eligible_age"
    t.boolean  "run_tracking"
    t.string   "phone_number"
    t.string   "alt_phone_number"
    t.string   "url"
    t.string   "primary_contact_name"
    t.string   "primary_contact_phone_number"
    t.string   "primary_contact_email"
    t.integer  "business_address_id"
    t.integer  "mailing_address_id"
    t.string   "admin_name"
    t.integer  "driver_availability_min_hour",                                                                                                     default: 6
    t.integer  "driver_availability_max_hour",                                                                                                     default: 22
    t.integer  "driver_availability_interval_min",                                                                                                 default: 30
    t.integer  "driver_availability_days_ahead",                                                                                                   default: 30
  end

  add_index "providers", ["business_address_id"], :name => "index_providers_on_business_address_id"
  add_index "providers", ["deleted_at"], :name => "index_providers_on_deleted_at"
  add_index "providers", ["mailing_address_id"], :name => "index_providers_on_mailing_address_id"

  create_table "recurring_driver_compliances", force: true do |t|
    t.integer  "provider_id"
    t.string   "event_name"
    t.text     "event_notes"
    t.string   "recurrence_schedule"
    t.integer  "recurrence_frequency"
    t.text     "recurrence_notes"
    t.date     "start_date"
    t.string   "future_start_rule"
    t.string   "future_start_schedule"
    t.integer  "future_start_frequency"
    t.boolean  "compliance_based_scheduling", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "recurring_driver_compliances", ["provider_id"], :name => "index_recurring_driver_compliances_on_provider_id"

  create_table "recurring_vehicle_maintenance_compliances", force: true do |t|
    t.integer  "provider_id"
    t.string   "event_name"
    t.text     "event_notes"
    t.string   "recurrence_type"
    t.string   "recurrence_schedule"
    t.integer  "recurrence_frequency"
    t.integer  "recurrence_mileage"
    t.text     "recurrence_notes"
    t.date     "start_date"
    t.string   "future_start_rule"
    t.string   "future_start_schedule"
    t.integer  "future_start_frequency"
    t.boolean  "compliance_based_scheduling", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "recurring_vehicle_maintenance_compliances", ["provider_id"], :name => "index_recurring_vehicle_maintenance_compliances_on_provider_id"

  create_table "regions", force: true do |t|
    t.string   "name"
    t.spatial  "the_geom",   limit: {:srid=>4326, :type=>"polygon", :geographic=>true}
    t.datetime "deleted_at"
    t.boolean  "is_primary"
  end

  add_index "regions", ["deleted_at"], :name => "index_regions_on_deleted_at"
  add_index "regions", ["the_geom"], :name => "index_regions_on_the_geom", :spatial => true

  create_table "repeating_run_manifest_orders", force: true do |t|
    t.integer  "repeating_run_id"
    t.integer  "wday"
    t.text     "manifest_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "repeating_run_manifest_orders", ["repeating_run_id"], :name => "index_repeating_run_manifest_orders_on_repeating_run_id"

  create_table "repeating_runs", force: true do |t|
    t.text     "schedule_yaml"
    t.string   "name"
    t.date     "date"
    t.datetime "scheduled_start_time"
    t.datetime "scheduled_end_time"
    t.integer  "vehicle_id"
    t.integer  "driver_id"
    t.boolean  "paid"
    t.integer  "provider_id"
    t.integer  "lock_version",                default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "comments"
    t.integer  "unpaid_driver_break_time"
    t.date     "scheduled_through"
    t.text     "manifest_order"
    t.string   "scheduled_start_time_string"
    t.string   "scheduled_end_time_string"
  end

  add_index "repeating_runs", ["driver_id"], :name => "index_repeating_runs_on_driver_id"
  add_index "repeating_runs", ["provider_id"], :name => "index_repeating_runs_on_provider_id"
  add_index "repeating_runs", ["vehicle_id"], :name => "index_repeating_runs_on_vehicle_id"

  create_table "repeating_trips", force: true do |t|
    t.text     "schedule_yaml"
    t.integer  "provider_id"
    t.integer  "customer_id"
    t.datetime "pickup_time"
    t.datetime "appointment_time"
    t.integer  "guest_count",                    default: 0
    t.integer  "attendant_count",                default: 0
    t.integer  "group_size",                     default: 0
    t.integer  "pickup_address_id"
    t.integer  "dropoff_address_id"
    t.integer  "mobility_id"
    t.integer  "funding_source_id"
    t.string   "trip_purpose_old"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                   default: 0
    t.integer  "driver_id"
    t.integer  "vehicle_id"
    t.boolean  "cab",                            default: false
    t.boolean  "customer_informed"
    t.integer  "trip_purpose_id"
    t.string   "direction",                      default: "outbound"
    t.integer  "service_level_id"
    t.boolean  "medicaid_eligible"
    t.integer  "mobility_device_accommodations"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "comments"
    t.integer  "repeating_run_id"
    t.date     "scheduled_through"
    t.string   "pickup_address_notes"
    t.string   "dropoff_address_notes"
    t.integer  "customer_space_count"
    t.integer  "service_animal_space_count"
  end

  add_index "repeating_trips", ["customer_id"], :name => "index_repeating_trips_on_customer_id"
  add_index "repeating_trips", ["driver_id"], :name => "index_repeating_trips_on_driver_id"
  add_index "repeating_trips", ["dropoff_address_id"], :name => "index_repeating_trips_on_dropoff_address_id"
  add_index "repeating_trips", ["funding_source_id"], :name => "index_repeating_trips_on_funding_source_id"
  add_index "repeating_trips", ["mobility_id"], :name => "index_repeating_trips_on_mobility_id"
  add_index "repeating_trips", ["pickup_address_id"], :name => "index_repeating_trips_on_pickup_address_id"
  add_index "repeating_trips", ["provider_id"], :name => "index_repeating_trips_on_provider_id"
  add_index "repeating_trips", ["service_level_id"], :name => "index_repeating_trips_on_service_level_id"
  add_index "repeating_trips", ["trip_purpose_id"], :name => "index_repeating_trips_on_trip_purpose_id"
  add_index "repeating_trips", ["vehicle_id"], :name => "index_repeating_trips_on_vehicle_id"

  create_table "reporting_filter_fields", force: true do |t|
    t.integer  "filter_group_id",             null: false
    t.integer  "filter_type_id",              null: false
    t.integer  "lookup_table_id"
    t.string   "name",                        null: false
    t.string   "title"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "sort_order",      default: 1, null: false
    t.string   "value_type"
  end

  add_index "reporting_filter_fields", ["filter_group_id"], :name => "index_reporting_filter_fields_on_filter_group_id"
  add_index "reporting_filter_fields", ["filter_type_id"], :name => "index_reporting_filter_fields_on_filter_type_id"
  add_index "reporting_filter_fields", ["lookup_table_id"], :name => "index_reporting_filter_fields_on_lookup_table_id"

  create_table "reporting_filter_groups", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reporting_filter_types", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reporting_lookup_tables", force: true do |t|
    t.string   "name",                              null: false
    t.string   "display_field_name",                null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "id_field_name",      default: "id", null: false
    t.string   "data_access_type"
  end

  create_table "reporting_output_fields", force: true do |t|
    t.string   "name",                              null: false
    t.string   "title"
    t.integer  "report_id",                         null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "formatter"
    t.integer  "numeric_precision"
    t.integer  "sort_order"
    t.boolean  "group_by",          default: false
    t.string   "alias_name"
  end

  add_index "reporting_output_fields", ["report_id"], :name => "index_reporting_output_fields_on_report_id"

  create_table "reporting_reports", force: true do |t|
    t.string   "name",                       null: false
    t.string   "description"
    t.string   "data_source",                null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "primary_key", default: "id", null: false
  end

  create_table "reporting_specific_filter_groups", force: true do |t|
    t.integer  "report_id"
    t.integer  "filter_group_id"
    t.integer  "sort_order",      default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reporting_specific_filter_groups", ["filter_group_id"], :name => "index_of_filter_group_on_specific_filter_group"
  add_index "reporting_specific_filter_groups", ["report_id"], :name => "index_of_report_on_specific_filter_group"

  create_table "ridership_mobility_mappings", force: true do |t|
    t.integer  "ridership_id"
    t.integer  "mobility_id"
    t.integer  "capacity"
    t.string   "type"
    t.integer  "host_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ridership_mobility_mappings", ["mobility_id"], :name => "index_ridership_mobility_mappings_on_mobility_id"

  create_table "roles", force: true do |t|
    t.integer  "user_id"
    t.integer  "provider_id"
    t.integer  "level"
    t.datetime "deleted_at"
  end

  add_index "roles", ["deleted_at"], :name => "index_roles_on_deleted_at"
  add_index "roles", ["provider_id"], :name => "index_roles_on_provider_id"
  add_index "roles", ["user_id"], :name => "index_roles_on_user_id"

  create_table "run_distances", force: true do |t|
    t.float    "total_dist"
    t.float    "revenue_miles"
    t.float    "non_revenue_miles"
    t.float    "deadhead_from_garage"
    t.float    "deadhead_to_garage"
    t.integer  "run_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "runs", force: true do |t|
    t.string   "name"
    t.date     "date"
    t.integer  "start_odometer"
    t.integer  "end_odometer"
    t.datetime "scheduled_start_time"
    t.datetime "scheduled_end_time"
    t.integer  "unpaid_driver_break_time"
    t.integer  "vehicle_id"
    t.integer  "driver_id"
    t.boolean  "paid"
    t.boolean  "complete"
    t.integer  "provider_id"
    t.datetime "actual_start_time"
    t.datetime "actual_end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                default: 0
    t.integer  "repeating_run_id"
    t.datetime "deleted_at"
    t.text     "manifest_order"
    t.boolean  "cancelled"
    t.integer  "from_garage_address_id"
    t.integer  "to_garage_address_id"
    t.text     "uncomplete_reason"
    t.string   "scheduled_start_time_string"
    t.string   "scheduled_end_time_string"
  end

  add_index "runs", ["deleted_at"], :name => "index_runs_on_deleted_at"
  add_index "runs", ["driver_id"], :name => "index_runs_on_driver_id"
  add_index "runs", ["from_garage_address_id"], :name => "index_runs_on_from_garage_address_id"
  add_index "runs", ["provider_id", "date"], :name => "index_runs_on_provider_id_and_date"
  add_index "runs", ["provider_id", "scheduled_start_time"], :name => "index_runs_on_provider_id_and_scheduled_start_time"
  add_index "runs", ["repeating_run_id"], :name => "index_runs_on_repeating_run_id"
  add_index "runs", ["to_garage_address_id"], :name => "index_runs_on_to_garage_address_id"
  add_index "runs", ["vehicle_id"], :name => "index_runs_on_vehicle_id"

  create_table "service_levels", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "service_levels", ["deleted_at"], :name => "index_service_levels_on_deleted_at"

  create_table "settings", force: true do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], :name => "index_settings_on_thing_type_and_thing_id_and_var", :unique => true

  create_table "translation_keys", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", force: true do |t|
    t.integer  "locale_id"
    t.integer  "translation_key_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "travel_time_estimates", id: false, force: true do |t|
    t.integer "from_address_id"
    t.integer "to_address_id"
    t.integer "seconds"
  end

  create_table "travel_trainings", force: true do |t|
    t.integer  "customer_id"
    t.datetime "date"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "travel_trainings", ["customer_id"], :name => "index_travel_trainings_on_customer_id"

  create_table "trip_purposes", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "trip_purposes", ["deleted_at"], :name => "index_trip_purposes_on_deleted_at"

  create_table "trip_results", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "description"
  end

  add_index "trip_results", ["deleted_at"], :name => "index_trip_results_on_deleted_at"

  create_table "trips", force: true do |t|
    t.integer  "run_id"
    t.integer  "customer_id"
    t.datetime "pickup_time"
    t.datetime "appointment_time"
    t.integer  "guest_count",                                                     default: 0
    t.integer  "attendant_count",                                                 default: 0
    t.integer  "group_size",                                                      default: 0
    t.integer  "pickup_address_id"
    t.integer  "dropoff_address_id"
    t.integer  "mobility_id"
    t.integer  "funding_source_id"
    t.string   "trip_purpose_old"
    t.string   "trip_result_old",                                                 default: ""
    t.text     "notes"
    t.decimal  "donation_old",                           precision: 10, scale: 2, default: 0.0
    t.integer  "provider_id"
    t.datetime "called_back_at"
    t.boolean  "customer_informed",                                               default: false
    t.integer  "repeating_trip_id"
    t.boolean  "cab",                                                             default: false
    t.boolean  "cab_notified",                                                    default: false
    t.text     "guests"
    t.integer  "called_back_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                                                    default: 0
    t.boolean  "medicaid_eligible"
    t.integer  "mileage"
    t.string   "service_level_old"
    t.integer  "trip_purpose_id"
    t.integer  "trip_result_id"
    t.integer  "service_level_id"
    t.datetime "deleted_at"
    t.string   "direction",                                                       default: "outbound"
    t.text     "result_reason"
    t.integer  "linking_trip_id"
    t.float    "drive_distance"
    t.integer  "mobility_device_accommodations"
    t.integer  "number_of_senior_passengers_served"
    t.integer  "number_of_disabled_passengers_served"
    t.integer  "number_of_low_income_passengers_served"
    t.string   "pickup_address_notes"
    t.string   "dropoff_address_notes"
    t.boolean  "is_stand_by"
    t.boolean  "driver_notified"
    t.integer  "customer_space_count"
    t.integer  "service_animal_space_count"
  end

  add_index "trips", ["called_back_by_id"], :name => "index_trips_on_called_back_by_id"
  add_index "trips", ["customer_id"], :name => "index_trips_on_customer_id"
  add_index "trips", ["deleted_at"], :name => "index_trips_on_deleted_at"
  add_index "trips", ["dropoff_address_id"], :name => "index_trips_on_dropoff_address_id"
  add_index "trips", ["funding_source_id"], :name => "index_trips_on_funding_source_id"
  add_index "trips", ["linking_trip_id"], :name => "index_trips_on_linking_trip_id"
  add_index "trips", ["mobility_id"], :name => "index_trips_on_mobility_id"
  add_index "trips", ["pickup_address_id"], :name => "index_trips_on_pickup_address_id"
  add_index "trips", ["provider_id", "appointment_time"], :name => "index_trips_on_provider_id_and_appointment_time"
  add_index "trips", ["provider_id", "pickup_time"], :name => "index_trips_on_provider_id_and_pickup_time"
  add_index "trips", ["repeating_trip_id"], :name => "index_trips_on_repeating_trip_id"
  add_index "trips", ["run_id"], :name => "index_trips_on_run_id"
  add_index "trips", ["service_level_id"], :name => "index_trips_on_service_level_id"
  add_index "trips", ["trip_purpose_id"], :name => "index_trips_on_trip_purpose_id"
  add_index "trips", ["trip_result_id"], :name => "index_trips_on_trip_result_id"

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "password_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_provider_id"
    t.string   "unconfirmed_email"
    t.datetime "reset_password_sent_at"
    t.datetime "password_changed_at"
    t.datetime "expires_at"
    t.string   "inactivation_reason"
    t.datetime "deleted_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "username"
    t.string   "phone_number"
    t.integer  "address_id"
  end

  add_index "users", ["address_id"], :name => "index_users_on_address_id"
  add_index "users", ["current_provider_id"], :name => "index_users_on_current_provider_id"
  add_index "users", ["deleted_at"], :name => "index_users_on_deleted_at"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["password_changed_at"], :name => "index_users_on_password_changed_at"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "vehicle_capacity_configurations", force: true do |t|
    t.integer  "vehicle_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_capacity_configurations", ["vehicle_type_id"], :name => "index_vehicle_capacity_configurations_on_vehicle_type_id"

  create_table "vehicle_compliances", force: true do |t|
    t.integer  "vehicle_id"
    t.string   "event"
    t.text     "notes"
    t.date     "due_date"
    t.date     "compliance_date"
    t.integer  "vehicle_requirement_template_id"
    t.boolean  "legal"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_compliances", ["vehicle_id"], :name => "index_vehicle_compliances_on_vehicle_id"
  add_index "vehicle_compliances", ["vehicle_requirement_template_id"], :name => "index_vehicle_compliances_on_vehicle_requirement_template_id"

  create_table "vehicle_maintenance_compliance_due_types", force: true do |t|
    t.string "name", limit: 16
    t.string "note", limit: 16
  end

  create_table "vehicle_maintenance_compliances", force: true do |t|
    t.integer  "vehicle_id"
    t.string   "event"
    t.text     "notes"
    t.date     "due_date"
    t.integer  "due_mileage"
    t.string   "due_type"
    t.date     "compliance_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "recurring_vehicle_maintenance_compliance_id"
    t.integer  "compliance_mileage"
    t.integer  "vehicle_maintenance_schedule_id"
  end

  add_index "vehicle_maintenance_compliances", ["recurring_vehicle_maintenance_compliance_id"], :name => "index_vehicle_maintenance_compliances_on_recurring_vehicle_main"
  add_index "vehicle_maintenance_compliances", ["vehicle_id"], :name => "index_vehicle_maintenance_compliances_on_vehicle_id"
  add_index "vehicle_maintenance_compliances", ["vehicle_maintenance_schedule_id"], :name => "index_compl_veh_maint_sched_id"

  create_table "vehicle_maintenance_events", force: true do |t|
    t.integer  "vehicle_id"
    t.boolean  "reimbursable"
    t.date     "service_date"
    t.date     "invoice_date"
    t.text     "services_performed"
    t.decimal  "odometer",           precision: 10, scale: 1
    t.string   "vendor_name"
    t.string   "invoice_number"
    t.decimal  "invoice_amount",     precision: 10, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                                default: 0
  end

  add_index "vehicle_maintenance_events", ["vehicle_id"], :name => "index_vehicle_maintenance_events_on_vehicle_id"

  create_table "vehicle_maintenance_schedule_types", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "provider_id"
  end

  add_index "vehicle_maintenance_schedule_types", ["provider_id"], :name => "index_veh_maint_sched_type_provider_id"

  create_table "vehicle_maintenance_schedules", force: true do |t|
    t.string   "name"
    t.integer  "mileage"
    t.integer  "vehicle_maintenance_schedule_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_maintenance_schedules", ["vehicle_maintenance_schedule_type_id"], :name => "index_vehicle_maintenance_schedule_type_id"

  create_table "vehicle_requirement_templates", force: true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.boolean  "legal"
    t.boolean  "reoccuring"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_requirement_templates", ["provider_id"], :name => "index_vehicle_requirement_templates_on_provider_id"

  create_table "vehicle_types", force: true do |t|
    t.string   "name"
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_types", ["provider_id"], :name => "index_vehicle_types_on_provider_id"

  create_table "vehicle_warranties", force: true do |t|
    t.integer  "vehicle_id"
    t.string   "description"
    t.text     "notes"
    t.date     "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_warranties", ["vehicle_id"], :name => "index_vehicle_warranties_on_vehicle_id"

  create_table "vehicle_warranty_templates", force: true do |t|
    t.string   "name"
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_warranty_templates", ["provider_id"], :name => "index_vehicle_warranty_templates_on_provider_id"

  create_table "vehicles", force: true do |t|
    t.string   "name"
    t.integer  "year"
    t.string   "make"
    t.string   "model"
    t.string   "license_plate"
    t.string   "vin"
    t.string   "garaged_location"
    t.integer  "provider_id"
    t.boolean  "active",                               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                         default: 0
    t.integer  "default_driver_id"
    t.boolean  "reportable"
    t.text     "insurance_coverage_details"
    t.string   "ownership"
    t.string   "responsible_party"
    t.date     "registration_expiration_date"
    t.integer  "seating_capacity"
    t.text     "accessibility_equipment"
    t.datetime "deleted_at"
    t.integer  "mobility_device_accommodations"
    t.integer  "initial_mileage",                      default: 0
    t.integer  "garage_address_id"
    t.string   "garage_phone_number"
    t.text     "initial_mileage_change_reason"
    t.date     "inactivated_start_date"
    t.date     "inactivated_end_date"
    t.text     "active_status_changed_reason"
    t.integer  "vehicle_maintenance_schedule_type_id"
    t.integer  "vehicle_type_id"
  end

  add_index "vehicles", ["default_driver_id"], :name => "index_vehicles_on_default_driver_id"
  add_index "vehicles", ["deleted_at"], :name => "index_vehicles_on_deleted_at"
  add_index "vehicles", ["garage_address_id"], :name => "index_vehicles_on_garage_address_id"
  add_index "vehicles", ["provider_id"], :name => "index_vehicles_on_provider_id"
  add_index "vehicles", ["vehicle_maintenance_schedule_type_id"], :name => "index_veh_maint_sched_type_id"
  add_index "vehicles", ["vehicle_type_id"], :name => "index_vehicles_on_vehicle_type_id"

  create_table "verification_questions", force: true do |t|
    t.integer  "user_id"
    t.text     "question"
    t.text     "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "verification_questions", ["user_id"], :name => "index_verification_questions_on_user_id"

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "weekday_assignments", force: true do |t|
    t.integer  "repeating_trip_id"
    t.integer  "repeating_run_id"
    t.integer  "wday"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "weekday_assignments", ["repeating_run_id"], :name => "index_weekday_assignments_on_repeating_run_id"
  add_index "weekday_assignments", ["repeating_trip_id"], :name => "index_weekday_assignments_on_repeating_trip_id"

end
