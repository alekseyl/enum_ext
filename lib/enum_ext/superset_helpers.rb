module EnumExt::SupersetHelpers
  # enum_supersets
  # This method intend for creating and using some sets of enum values
  #
  # it creates: scopes for subsets,
  #             instance method with ?,
  #             and some class methods helpers
  #
  # For this call:
  #   enum_supersets :status, {
  #                   delivery_set: [:ready_for_shipment, :on_delivery, :delivered] # for shipping department for example
  #                   in_warehouse: [:ready_for_shipment]            # this scope is just for superposition example below
  #                 }
  #Rem:
  #  enum_supersets can be called twice defining a superposition of already defined supersets
  #  based on array operations, with already defined array methods ( considering previous example ):
  #  enum_supersets :status, {
  #                  outside_warehouse: ( delivery_set_statuses - in_warehouse_statuses )... any other array operations like &, + and so can be used
  #                }
  #
  # so the enum_supersets will generate:
  #   instance:
  #     methods: delivery_set?, in_warehouse?
  #   class:
  #     named scopes: delivery_set, in_warehouse
  #     parametrized scopes: with_statuses, without_statuses
  #     class helpers:
  #       - delivery_set_statuses (=[:ready_for_shipment, :on_delivery, :delivered] ), in_warehouse_statuses
  #       - delivery_set_statuses_i (= [3,4,5]), in_warehouse_statuses_i (=[3])
  #     class translation helpers ( started with t_... )
  #       for select inputs purposes:
  #       - t_delivery_set_statuses_options (= [['translation or humanization', :ready_for_shipment] ...])
  #       same as above but with integer as value ( for example to use in Active admin filters )
  #       - t_delivery_set_statuses_options_i (= [['translation or humanization', 3] ...])

  # Console:
  #  request.on_delivery!
  #  request.delivery_set?                    # >> true

  #  Request.delivery_set.exists?(request)    # >> true
  #  Request.in_warehouse.exists?(request)    # >> false
  #
  #  Request.delivery_set_statuses            # >> [:ready_for_shipment, :on_delivery, :delivered]
  def enum_supersets( enum_name, options = {} )
    enum_plural = enum_name.to_s.pluralize

    self.instance_eval do
      puts(<<~DEPRECATION) unless respond_to?("with_#{enum_plural}")
        ----------------DEPRECATION ERROR----------------
        - with/without_#{enum_plural} are served now via multi_enum_scopes method, 
          and removed from the enum_supersets!
      DEPRECATION

      enum_obj = send(enum_plural)
      enum_obj.supersets.merge!( options.transform_values{ _1.map(&:to_s) } )

      options.each do |superset_name, enum_vals|
        # superset_statuses
        superset_enum_name = "#{superset_name}_#{enum_plural}"

        # class.superset_statuses
        define_singleton_method(superset_enum_name) { enum_obj.superset_to_enum(*enum_vals) }

        # superset_name scope
        scope superset_name, -> { where( enum_name => send(superset_enum_name) ) } if respond_to?(:scope)

        # instance.superset_name?
        define_method "#{superset_name}?" do
          send(enum_name) && self.class.send(superset_enum_name).include?( send(enum_name) )
        end

        EnumExt::HumanizeHelpers.define_superset_humanization_helpers( self, superset_name, enum_name )
      end
    end
  end
  alias_method :ext_enum_sets, :enum_supersets
end


