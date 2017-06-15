namespace :ridepilot do

  desc 'Seed default lookup table configurations and each associated table data'
  task :seed_lookup_tables => :environment do
    puts 'trip purposes...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_trip_purposes.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding trip purposes'

    puts 'trip results...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_trip_results.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding trip results'

    puts 'service levels...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_service_levels.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding service levels'

    puts 'mobilities...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_mobilities.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding mobilities'

    puts 'ethnicities...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_ethnicities.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding ethnicities'

    puts 'customer address codes...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_customer_address_codes.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished customer address codes'

    puts 'lookup table configurations...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_lookup_table_configurations.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding lookup table configurations'

    puts 'provider lookup table configurations...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_provider_lookup_table_configurations.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding provider lookup table configurations'
  end

  desc 'Seed list of supporting custom reports'
  task :seed_custom_reports => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_custom_reports.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding supporting custom reports'
  end

  desc 'Seed list of eligibility factors'
  task :seed_eligibilities => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_eligibilities.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding eligibilities'
  end

  desc 'Update lookup configs for ethnicities'
  task :update_ethnicity_lookup_config => :environment do
    config = LookupTable.find_by_name('provider_ethnicities')
    config.update_attributes(name: 'ethnicities', caption: 'Ethnicity') if config
  end

  desc 'Seed some fake data for testing'
  task :seed_test_data => :environment do

    for index in 1..5
      customer = Customer.new
      customer.first_name = "Customer_first_name_#{index}"
      customer.last_name = "Customer_last_name_#{index}"
      customer.address = Address.first
      customer.provider = Provider.first
      puts customer.save!
    end
    for index in 1..5
      provider = Provider.find_or_create_by(:name => "provider_name_#{index}")
      puts provider.save!
    end
    for index in 1..5
      #assign to a random provider
      offset = rand(Provider.count)
      random_provider = Provider.offset(offset).first
      provider_id = 
      user = User.find_or_create_by(:email => "abromley#{index}@camsys.com")
      user.password = "welcome1!"
      user.current_provider_id = random_provider.id
      user.save!
      role = Role.new
      role.user_id = user.id
      role.provider_id = random_provider.id
      role.level = 100
      puts role.save!
    end
  end

  desc "Seed supported filter types in reporting engine "
  task seed_reporting_filter_types: :environment do

    %w(
      eq not_eq 
      matches does_not_match 
      lt gt 
      lteq gteq 
      in not_in 
      cont not_cont 
      cont_any not_cont_any 
      i_cont i_not_cont
      start not_start
      end not_end
      true not_true
      false not_false
      present blank
      null not_null
      range
      select
      multi_select
      ).each do |type|
      Reporting::FilterType.where(name: type).first_or_create
    end
    puts 'Finished seeding reporting filter types.'

  end # task

  desc "mark addresses if associated with a driver"
  task mark_address_if_driver_associated: :environment do
    Driver.includes(:address).each do |driver|
      driver.address.update_attributes(is_driver_associated: true) if driver.address
    end
  end

  desc "Generate customer token"    
  task generate_customer_token: :environment do    
    Customer.where(token: nil).each do |customer|    
      customer.update_attribute(:token, SecureRandom.hex(5))   
    end    
  end

  desc 'Seed lookup tables configurations'
  task :seed_lookup_table_configurations => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_lookup_table_configurations.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding lookup table configurations'
  end

  desc 'Add driver manifest report'
  task :add_driver_manifest_report => :environment do
    report = CustomReport.where(name: "driver_manifest").first_or_create 
    report.update(redirect_to_results: false, title: "Driver Manifest")
    puts 'Driver manifest report added'
  end

  desc 'Update trip results'
  task :update_trip_results => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_trip_results.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding trip results'
  end
  
   desc 'Update translation labels'
  task :update_translations => :environment do
    new_trans = {
      application_cabs_link_text: 'Cabs',
      application_admin_link_text: "System Admin",
      current_provider_settings_link_text: "Provider Settings",
      application_trips_runs_link_text: 'Dispatch',
      trips_runs: 'Dispatch',
      new_password_form_heading: 'Enter your Username',
      no_verification_questions_set: "You have not set up any security questions. Please contact your administrator to reset your password.",
      verification_question_incorrect_answer: "That answer is not correct. Please try again or contact your administrator to reset your password."
    }

    en_locale = Locale.find_by_name 'en'
    if en_locale.present?
      new_trans.each do |k, v|
        key = TranslationKey.find_by_name k 
        if key.present?
          t = Translation.where(locale: en_locale, translation_key: key).first
          t.update(value: v) if v.present?
        end
      end 
    end
  end

  desc 'Migrate addresses to specific sub categories'
  task :categorize_addresses => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'categorize_addresses.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished'
  end

  desc 'Migrate existing users to have username as login'
  task :migrate_usernames => :environment do
    User.transaction do 
      User.unscoped.each do |user|
        next if user.username.present?

        user.update_attribute(:username, user.email) # user email as default username
        user.update_attribute(:first_name, user.email.split('@').first) # default first name
        user.update_attribute(:last_name, 'User') # default last name
      end
    end
  end

  desc 'Seed provider lookup tables configurations'
  task :seed_provider_lookup_table_configurations => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_provider_lookup_table_configurations.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding provider lookup table configurations'
  end
end
