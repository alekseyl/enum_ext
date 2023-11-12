require 'test_helper'

class EnumExtConfigTest < ActiveSupport::TestCase

  def teardown
    EnumExt.configure { _1.default_helpers = [] }
  end

  class ApplicationRecord < ActiveRecord::Base
  end

  def define_class
    if ActiveRecord::VERSION::MAJOR >= 7
      Class.new(ApplicationRecord) do
        self.table_name = :enum_ext_mocks
        enum :test_type, { unit_test: 0, spec: 1, view: 2, controller: 3, integration: 4}
      end
    else
      Class.new(ApplicationRecord) do
        self.table_name = :enum_ext_mocks
        enum test_type: { unit_test: 0, spec: 1, view: 2, controller: 3, integration: 4}
      end
    end
  end

  test 'config will extend EnumExt to basic application record class if global set to true' do
    ApplicationRecord.stub_must(:extend, -> (_module) {
      assert_equal(_module, EnumExt)
    }) do
      EnumExt.configure { |config| config.application_record_class = ApplicationRecord }
    end
  end

  test 'default helpers will be added to enum definitions bb' do
    EnumExt.configure do |config|
      config.default_helpers = [:enum_i, :multi_enum_scopes, :mass_assign_enum]
      config.application_record_class = ApplicationRecord
    end

    klass = define_class
    assert_equal(klass.new(test_type: :unit_test).test_type_i, 0 )
    assert(klass.respond_to?(:with_test_types))
  end

end



