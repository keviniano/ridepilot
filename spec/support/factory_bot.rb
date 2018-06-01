RSpec.configure do |config|
  config.before(:suite) do
    begin
      FactoryBot.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end
