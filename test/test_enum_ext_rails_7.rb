require 'test_helper'

class EnumExtTestRails7 < ActiveSupport::TestCase

  test 'new rails enum syntax' do
    EnumExtRails70 = build_mock_class_without_enum

    EnumExtRails70.stub_must_all(
      enum_i: :do_nothing,
      mass_assign_enum: :do_nothing,
      enum_supersets: ->(_enum_name, options) {
      assert_equal({fast: %i[unit_test spec], slow: :integration}, options)
    } ) do
      EnumExtRails70.enum :test_type, %i[unit_test spec view controller integration],
                          ext: [:enum_i, :mass_assign_enum, enum_supersets: {fast: %i[unit_test spec], slow: :integration}]
    end
  end

end if ActiveRecord::VERSION::MAJOR >= 7



