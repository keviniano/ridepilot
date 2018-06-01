namespace :deploy do
  desc 'Runs rails db:seed'
  task :seed => [:set_rails_env] do
    on primary fetch(:migration_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rails, "db:seed"
        end
      end
    end
  end
end