ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: ':memory:'
)

ActiveRecord::Base.connection.create_table :enum_ext_mocks do |t|
  t.integer :test_type
  t.integer :enum_ext_mock_id
end

I18n.available_locales = [:ru, :en]

I18n.load_path += I18n.available_locales.map { |locale| "#{File.dirname( __dir__)}/#{locale}.yml" }
