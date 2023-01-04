require 'active_record'
require 'minitest/autorun'
require 'enum_ext'
require 'byebug'
require 'stubberry'

class EnumExtMock < ActiveRecord::Base
  extend EnumExt
  enum test_type: { unit_test: 0, spec: 1, view: 2, controller: 3, integration: 4}

  has_many :enum_ext_mocks
  belongs_to :enum_ext_mock
end

class EnumExtMockClear < ActiveRecord::Base
  extend EnumExt

  has_many :enum_ext_mocks
  belongs_to :enum_ext_mock
end


ActiveRecord::Base.establish_connection(
    adapter:  'sqlite3',
    database: ':memory:'
)

ActiveRecord::Base.connection.create_table :enum_ext_mocks do |t|
  t.integer :test_type
  t.integer :enum_ext_mock_id
end

I18n.available_locales = [:ru, :en]

I18n.load_path += I18n.available_locales.map { |locale| "#{File.dirname( __dir__)}/test/#{locale}.yml" }

class ActiveSupport::TestCase

  def build_mock_class
    Class.new(EnumExtMock) { self.table_name = :enum_ext_mocks }
  end

  def build_mock_class_without_enum
    Class.new(EnumExtMockClear) { self.table_name = :enum_ext_mocks }
  end

end

Minitest.after_run {  ActiveRecord::Base.connection.drop_table :enum_ext_mocks }