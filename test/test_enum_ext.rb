require 'test_helper'

class EnumExtTest < ActiveSupport::TestCase

  def create_all_kids(klass)
    klass.test_types.keys.each { |tk| klass.create( test_type: tk ) }
  end

  test 'enum ext: translate_enum' do
    EnumExtTranslateDirect = build_mock_class_without_enum
    EnumExtTranslateDirect.stub_must( :translate_enum, ->(*args) { assert_equal(args, [:test_type]) } ) do
      EnumExtTranslateDirect.enum test_type: [:unit_test], ext: [:enum_i, :mass_assign_enum, :translate_enum]
    end
  end

  test 'enum ext: array' do
    EnumExtDirect = build_mock_class_without_enum
    EnumExtDirect.stub_must_all(
      enum_i: :do_nothing,
      mass_assign_enum: :do_nothing
    ) do
      EnumExtDirect.enum test_type: [:unit_test], ext: [:enum_i, :mass_assign_enum]
    end
  end

  test 'enum ext: single' do
    EnumExtDirect = build_mock_class_without_enum
    EnumExtDirect.stub_must(:enum_i, :do_nothing) do
      EnumExtDirect.enum test_type: [:unit_test], ext: :enum_i
    end
  end

  test 'enum ext: supersets' do
    EnumSupersets = build_mock_class_without_enum
    EnumSupersets.stub_must(:enum_supersets, ->(_enum_name, options) {
      assert_equal({fast: %i[unit_test spec], slow: :integration}, options)
    }) do
      EnumSupersets.enum test_type: %i[unit_test spec view controller integration],
                         ext: [enum_supersets: {fast: %i[unit_test spec], slow: :integration}]
    end
  end

  test 'enum ext: supersets with a "superset" of one kind (regression)' do
    EnumSupersetsRegress = build_mock_class_without_enum

    assert_nothing_raised do
      EnumSupersetsRegress.enum test_type: %i[unit_test spec view controller integration],
                         ext: [enum_supersets: {fast: %i[unit_test spec], slow: :integration}]
    end

    es = EnumSupersetsRegress.create( test_type: :integration )

    assert(es.integration?)
    assert(es.slow?)
  end

  test 'enum ext: supersets using nested supersets' do
    EnumSupersetsRecursive = build_mock_class_without_enum

    EnumSupersetsRecursive.enum test_type: %i[unit_test spec view controller integration],
                              ext: [ enum_supersets: {
                                        fast: %i[unit_test spec],
                                        slow: :integration,
                                        automatable: %i[fast slow],
                                      }]


    es = EnumSupersetsRecursive.create( test_type: :integration )

    assert(es.automatable?)
    assert(es.slow?)

    es.view!
    assert_not(es.automatable?)
  end

  # test 'enum ext prefixes' do
  #   EnumSupersetsPref = build_mock_class_without_enum
  #
  #   EnumSupersetsPref.enum test_type: %i[unit_test spec view controller integration],
  #                      _suffix: true,
  #                      ext: [:enum_i, enum_supersets: {fast: %i[unit_test spec], slow: :integration}]
  #
  #   es = EnumSupersetsPref.create( test_type: :integration )
  #
  #   assert(es.slow_test_type?)
  # end

  test 'enum_i' do
    EnumI = build_mock_class
    EnumI.enum_ext :test_type, :enum_i

    EnumI.test_types.each_value do |tt|
      ei = EnumI.new(test_type: tt)
      assert_equal( EnumI.test_types[ei.test_type], ei.test_type_i  )
    end
  end

  test 'enum_supersets without options' do
    EnumMultiScope = build_mock_class

    create_all_kids(EnumMultiScope)
    # class:
    #   - with_test_types, without_test_types also scopes but with params,
    #     allows to combine and negate defined sets and enum values
    EnumMultiScope.enum_ext :test_type, :multi_enum_scopes

    assert_equal( EnumMultiScope.without_test_types(:unit_test, :spec).map(&:test_type).uniq.sort,
                  ["integration", "controller", "view"].uniq.sort)

    assert_equal( EnumMultiScope.with_test_types(:unit_test, :spec).map(&:test_type).uniq.sort,
                  ["unit_test", "spec"].uniq.sort)

    assert_equal( EnumMultiScope.all.with_test_types.map(&:test_type).tally,
                  EnumMultiScope.all.map(&:test_type).tally)

    assert_equal( EnumMultiScope.all.without_test_types.map(&:test_type).tally,
                  EnumMultiScope.all.map(&:test_type).tally)
  end

  test 'enum_supersets instance methods working as expected' do
    EnumSetNestedDef = build_mock_class

    EnumSetNestedDef.enum_ext :test_type, enum_supersets: {
      raw_level: [:unit_test, :spec],
      high_level: [:view, :controller, :integration],
      fast: [:raw_level, :controller],
      minitest: [:raw_level, :high_level]
    }

    es = EnumSetNestedDef.create( test_type: :unit_test )

    # instance methods are defined and working as expected
    assert( es.raw_level? )
    assert( !es.high_level? )

    # superset also works
    assert( es.fast? )

    # scopes works well also
    assert( EnumSetNestedDef.raw_level.exists?( es.id ) )
    assert( EnumSetNestedDef.fast.exists?( es.id ) )
  end

  test 'enum_supersets' do
    EnumSet = build_mock_class

    # instance: raw_level?, high_level?
    # class:
    #   - high_level, raw_level ( as corresponding scopes )
    #   - with_test_types, without_test_types also scopes but with params, allows to combine and negate defined sets and enum values
    #   - raw_level_test_types (= [:unit_test, :spec]), high_level_test_types (=[:view, :controller, :integration])
    #   - raw_level_test_types_i (= [0,1]),  high_level_test_types_i (= [2,3,4])
    #
    # will work correctly only when translate or humanize called
    #   - t_raw_level_test_types, t_high_level_test_types - subset of translation or humanization rules
    #   - t_raw_level_test_types_options, t_high_level_test_types_options - translated options ready for form select inputs
    #   - t_raw_level_test_types_options_i, t_high_level_test_types_options_i - same as above but used integer in selects not strings, usefull in Active Admin
    EnumSet.enum_ext :test_type, enum_supersets: {
      raw_level: [:unit_test, :spec],
      high_level: [:view, :controller, :integration]
    }

    EnumSet.instance_eval do
      enum_ext :test_type, enum_supersets: {
        fast: test_types.raw_level_test_types | [:controller],
        minitest: ( test_types.raw_level_test_types | test_types.high_level_test_types )
      }
    end

    assert_equal(
      {:raw_level  => %w[unit_test spec],
       :high_level => %w[view controller integration],
       :fast       => %w[unit_test spec controller],
       :minitest   => %w[unit_test spec view controller integration]}.with_indifferent_access,
      EnumSet.test_types.supersets
    )
    es = EnumSet.create( test_type: :unit_test )

    assert( es.raw_level? )
    assert( !es.high_level? )
    assert( EnumSet.raw_level.exists?( es.id ) )

    assert_equal(%w[unit_test spec], EnumSet.test_types.raw_level_test_types )

    # since translation wasn't defined
    assert_equal([["Enum translations are missing. Did you forget to translate test_type"]*2].to_h, EnumSet.test_types.t_raw_level )
    assert_equal( [["Enum translations are missing. Did you forget to translate test_type"]*2], EnumSet.test_types.t_raw_level_options )
    assert_equal( [["Enum translations are missing. Did you forget to translate test_type"]*2], EnumSet.test_types.t_raw_level_options_i )

    # superset also works
    assert( es.fast? )
    assert( EnumSet.fast.exists?( es.id ) )
  end

  test 'humanize' do
    I18n.locale = :en
    EnumH = build_mock_class
    # adds to instance:
    #  - t_test_types
    #
    # adds to class:
    #  - t_test_types - as given or generated values
    #  - t_test_types_options - translated enum values options for select input
    #  - t_test_types_options_i - same as above but use int values with translations good for ActiveAdmin filter e.t.c.
    EnumH.instance_eval do
      humanize_enum :test_type,
                    unit_test: 'Unit::Test',
                    spec: Proc.new{ I18n.t("activerecord.attributes.enum_ext_test/enum_t.test_types.#{send(:test_type)}")},
                    view: Proc.new{ "View test id: %{id}" % {id: send(:id)} }

      humanize_enum :test_type,
                    controller: -> (t_self) { I18n.t("activerecord.attributes.enum_ext_test/enum_t.test_types.#{t_self.test_type}")},
                    integration: -> {'Integration'}
    end

    et = EnumH.create
    et.unit_test!
    assert_equal( 'Unit::Test', et.t_test_type )

    et.spec!
    assert_equal( 'spec tests', et.t_test_type )

    et.view!
    assert_equal( "View test id: #{et.id}", et.t_test_type )

    et.controller!
    assert_equal( 'controller tests', et.t_test_type )

    assert_equal(  [["Unit::Test", "unit_test"],
                    ["Cannot create option for spec ( proc fails to evaluate )", "spec"],
                    ["Cannot create option for view ( proc fails to evaluate )", "view"],
                    ["Cannot create option for controller because of a lambda", "controller"],
                    ["Integration", "integration"]],
                   EnumH.test_types.t_options
    )
    assert_equal( [["Unit::Test", 0],
                   ["Cannot create option for spec ( proc fails to evaluate )", 1],
                   ["Cannot create option for view ( proc fails to evaluate )", 2],
                   ["Cannot create option for controller because of a lambda", 3],
                   ["Integration", 4]], EnumH.test_types.t_options_i )

  end

  test 'humanize with block' do
    EnumHB = build_mock_class
    # adds to instance:
    #  - t_test_types
    #
    # adds to class:
    #  - t_test_types - as given or generated values
    #  - t_test_types_options - translated enum values options for select input
    #  - t_test_types_options_i - same as above but use int values with translations good for ActiveAdmin filter e.t.c.
    EnumHB.instance_eval do
      humanize_enum :test_type do
        I18n.t("activerecord.attributes.enum_ext_test/enum_t.test_types.#{test_type}")
      end
    end

    ehb = EnumHB.create

    assert_equal( I18n.available_locales, [:ru, :en] )
    #locales must change correctly
    I18n.available_locales.each do |locale|
      I18n.locale = locale
      EnumHB.test_types.each_key do |key|
        ehb.send("#{key}!")
        assert_equal( I18n.t("activerecord.attributes.enum_ext_test/enum_t.test_types.#{ehb.test_type}"), ehb.t_test_type  )
      end
    end

    I18n.locale = :en
    assert_equal( EnumHB.test_types.t_options,
                  [["unittest", "unit_test"], ["spec tests", "spec"],
                   ["viewer tests", "view"], ["controller tests", "controller"],
                   ["integration tests", "integration"]] )

  end

  test 't helper is defined' do
    assert( build_mock_class.test_types.respond_to?(:t) )
  end

  test 'translate' do
    I18n.locale = :en
    EnumT = build_mock_class
    # adds to instance:
    #  - t_test_types
    #
    # adds to class:
    #  - t_test_types - as given or generated values
    #  - t_test_types_options - translated enum values options for select input
    #  - t_test_types_options_i - same as above but use int values with translations good for ActiveAdmin filter e.t.c.
    EnumT.translate_enum(:test_type)
    et = EnumT.create(test_type: :integration)
    assert_equal( 'integration tests', et.t_test_type )

    assert_equal( [["unittest", "unit_test"], ["spec tests", "spec"],
                   ["viewer tests", "view"], ["controller tests", "controller"],
                   ["integration tests", "integration"]], EnumT.test_types.t_options )
    assert_equal( [["unittest", 0], ["spec tests", 1],
                   ["viewer tests", 2], ["controller tests", 3],
                   ["integration tests", 4]], EnumT.test_types.t_options_i )

    EnumT.enum_ext :test_type, enum_supersets: { raw_level: [:unit_test, :spec] }

    assert_equal( [["unittest", "unit_test"], ["spec tests", "spec"] ], EnumT.test_types.t_raw_level_options )
    assert_equal( [["unittest", 0], ["spec tests", 1]], EnumT.test_types.t_raw_level_options_i )

    # locales must be able change at runtime, not just initialization time
    I18n.locale = :ru
    assert_equal('Интеграционые тесты',  et.t_test_type )


    assert_equal( [["Юнит тест", "unit_test"], ["Спеки", "spec"],
                   ["Тесты вьюшек ( что конечно перебор )", "view"], ["Контроллер тест", "controller"],
                   ["Интеграционые тесты", "integration"]], EnumT.test_types.t_options )
    assert_equal( [["Юнит тест", 0], ["Спеки", 1],
                   ["Тесты вьюшек ( что конечно перебор )", 2], ["Контроллер тест", 3],
                   ["Интеграционые тесты", 4]], EnumT.test_types.t_options_i )

    EnumT.enum_ext :test_type, enum_supersets: { raw_level: [:unit_test, :spec] }

    assert_equal( [["Юнит тест", "unit_test"], ["Спеки", "spec"]],EnumT.test_types.t_raw_level_options )
    assert_equal( [["Юнит тест", 0], ["Спеки", 1]], EnumT.test_types.t_raw_level_options_i )
  end

  test 'mass assign' do
    # adds class methods with bang: unit_test!, spec! e.t.c
    MassAssignTestClass.enum_ext :test_type, :mass_assign_enum

    ema = MassAssignTestClass.create(test_type: :spec)

    assert( ema.spec? )

    MassAssignTestClass.spec.integration!
    assert( MassAssignTestClass.integration.exists?( ema.id ) )

    ema_child = ema.enum_ext_mocks.create!(test_type: "view")
    assert( ema_child.view? )
    assert( !MassAssignTestClass.controller.exists?( ema_child.id ) )

    ema.enum_ext_mocks.controller!
    assert( MassAssignTestClass.controller.exists?( ema_child.id ) )
  end

  test 'humanize_attr class method' do
    I18n.locale = :ru
    EnumTH = build_mock_class
    assert_equal( EnumTH.human_attribute_name( :t_test_type ),  EnumTH.human_attribute_name( :test_type ) )
    assert_equal( EnumTH.human_attribute_name( :t_test_type ),  'Тип теста' )
  end

  test 't_attr assign' do
    #translate assign
    EnumTA = build_mock_class
    EnumTA.translate_enum(:test_type)

    et = EnumTA.create
    et.unit_test!
    assert( et.unit_test? )

    et.t_test_type = :spec
    assert( et.spec? )

    et.update( t_test_type: :controller )
    assert( et.reload.controller? )
  end

  test 'no AR model is OK with enum_supersets. Regression test for store model issue' do
    NoARClass = build_mock_class

    class << NoARClass
      undef_method :scope
    end

    NoARClass.enum_ext :test_type,  enum_supersets: { raw_level: [:unit_test, :spec] }

    no_ar = NoARClass.new( test_type: :unit_test )
    assert( no_ar.raw_level? )
  end
end



