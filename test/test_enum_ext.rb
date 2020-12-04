require 'test_helper'

class EnumExtTest < ActiveSupport::TestCase

  test 'enum_i' do
    EnumI = build_mock_class
    EnumI.enum_i(:test_type)

    EnumI.test_types.each_value do |tt|
      ei = EnumI.create(test_type: tt)
      assert_equal( EnumExtMock.test_types[ei.test_type], ei.test_type_i  )
    end

  end

  test 'ext_enum_sets' do
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
    EnumSet.ext_enum_sets :test_type,
                        raw_level: [:unit_test, :spec],
                        high_level: [:view, :controller, :integration]

    EnumSet.instance_eval do
        ext_enum_sets :test_type,
                      fast: raw_level_test_types | [:controller],
                      minitest: ( raw_level_test_types | high_level_test_types )

    end
    es = EnumSet.create( test_type: :unit_test )

    assert( es.raw_level? )
    assert( !es.high_level? )
    assert( EnumSet.raw_level.exists?( es.id ) )

    assert_equal( EnumSet.test_types.slice(:unit_test, :spec).values, EnumSet.raw_level_test_types_i )
    assert_equal([:unit_test, :spec],  EnumSet.raw_level_test_types )

    # since translation wasn't defined
    assert_equal([["Enum translations call missed. Did you forget to call translate test_type"]*2].to_h, EnumSet.t_raw_level_test_types )
    assert_equal( [["Enum translations call missed. Did you forget to call translate test_type"]*2], EnumSet.t_raw_level_test_types_options )
    assert_equal( [["Enum translations call missed. Did you forget to call translate test_type"]*2], EnumSet.t_raw_level_test_types_options_i )

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

    assert( EnumH.respond_to?(:t_test_types) )
    assert_equal(  [["Unit::Test", "unit_test"],
                    ["Cannot create option for spec ( proc fails to evaluate )", "spec"],
                    ["Cannot create option for view ( proc fails to evaluate )", "view"],
                    ["Cannot create option for controller because of a lambda", "controller"],
                    ["Integration", "integration"]],
                   EnumH.t_test_types_options
    )
    assert_equal( [["Unit::Test", 0],
                   ["Cannot create option for spec ( proc fails to evaluate )", 1],
                   ["Cannot create option for view ( proc fails to evaluate )", 2],
                   ["Cannot create option for controller because of a lambda", 3],
                   ["Integration", 4]], EnumH.t_test_types_options_i )

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

    #locales must change correctly
    I18n.available_locales.each do |locale|
      I18n.locale = locale
      EnumHB.test_types.each_key do |key|
        ehb.send("#{key}!")
        assert_equal( I18n.t("activerecord.attributes.enum_ext_test/enum_t.test_types.#{ehb.test_type}"), ehb.t_test_type  )
      end
    end

    I18n.locale = :en
    assert_equal( EnumHB.t_test_types_options,
                  [["unittest", "unit_test"], ["spec tests", "spec"],
                   ["viewer tests", "view"], ["controller tests", "controller"],
                   ["integration tests", "integration"]] )

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

    assert( EnumT.respond_to?(:t_test_types) )
    assert_equal( [["unittest", "unit_test"], ["spec tests", "spec"],
                   ["viewer tests", "view"], ["controller tests", "controller"],
                   ["integration tests", "integration"]], EnumT.t_test_types_options )
    assert_equal( [["unittest", 0], ["spec tests", 1],
                   ["viewer tests", 2], ["controller tests", 3],
                   ["integration tests", 4]], EnumT.t_test_types_options_i )

    EnumT.ext_enum_sets :test_type, raw_level: [:unit_test, :spec]

    assert_equal( [["unittest", "unit_test"], ["spec tests", "spec"] ], EnumT.t_raw_level_test_types_options )
    assert_equal( [["unittest", 0], ["spec tests", 1]], EnumT.t_raw_level_test_types_options_i )

    # locales must be able change at runtime, not just initialization time
    I18n.locale = :ru
    assert_equal('Интеграционые тесты',  et.t_test_type )

    assert( EnumT.respond_to?(:t_test_types) )
    assert_equal( [["Юнит тест", "unit_test"], ["Спеки", "spec"],
                   ["Тесты вьюшек ( что конечно перебор )", "view"], ["Контроллер тест", "controller"],
                   ["Интеграционые тесты", "integration"]], EnumT.t_test_types_options )
    assert_equal( [["Юнит тест", 0], ["Спеки", 1],
                   ["Тесты вьюшек ( что конечно перебор )", 2], ["Контроллер тест", 3],
                   ["Интеграционые тесты", 4]], EnumT.t_test_types_options_i )

    EnumT.ext_enum_sets :test_type, raw_level: [:unit_test, :spec]

    assert_equal( [["Юнит тест", "unit_test"], ["Спеки", "spec"]],EnumT.t_raw_level_test_types_options )
    assert_equal( [["Юнит тест", 0], ["Спеки", 1]], EnumT.t_raw_level_test_types_options_i )
  end

  test 'mass assign' do
    EnumMA = EnumExtMock

    # adds class methods with bang: unit_test!, spec! e.t.c
    EnumMA.mass_assign_enum :test_type

    ema = EnumMA.create(test_type: :spec)

    assert( ema.spec? )

    EnumMA.spec.integration!
    assert( EnumMA.integration.exists?( ema.id ) )

    ema_child = ema.enum_ext_mocks.create(test_type: :view)
    assert( ema_child.view? )
    assert( !EnumMA.controller.exists?( ema_child.id ) )

    ema.enum_ext_mocks.controller!
    assert( EnumMA.controller.exists?( ema_child.id ) )
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

    et.update_attributes( t_test_type: :controller )

    assert( et.reload.controller? )
  end
end



