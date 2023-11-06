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

  test 'superset with suffix and prefix' do
    EnumSupersetsSuffixAndPrefix = build_mock_class_without_enum

    EnumSupersetsSuffixAndPrefix.enum :test_type, %i[unit_test spec view controller integration],
                                      suffix: true, prefix: :cool,
                                      ext: [:enum_i, enum_supersets: {fast: %i[unit_test spec], slow: :integration}]

    es = EnumSupersetsSuffixAndPrefix.create( test_type: :integration )

    assert(es.cool_slow_test_type?)
    assert_equal(EnumSupersetsSuffixAndPrefix.cool_slow_test_type.first, es)
  end

end if ActiveRecord::VERSION::MAJOR >= 7



