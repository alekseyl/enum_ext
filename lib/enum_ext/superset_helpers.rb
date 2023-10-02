module EnumExt::SupersetHelpers
  # enum_supersets
  # This method intend for creating and using some sets of enum values,
  # you should
  #
  # it creates: scopes for subsets,
  #             instance method with ?
  #
  # For this call:
  #   enum status: [:in_cart, :waiting_for_payment, :paid, :packing, :ready_for_shipment, :on_delivery, :delivered],
  #      ext:[  , supersets: {
  #                   delivery_set: [:ready_for_shipment, :on_delivery] # for shipping department for example
  #                   in_warehouse: [:packing, :ready_for_shipment]            # this scope is just for superposition example below
  #                   sold: [:payd, :delivery_set, :in_warehouse, :delivered]
  #                 } ]
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
  #  Request.statuses.supersets[:delivery_set]           # >> [:ready_for_shipment, :on_delivery, :delivered]
  private
  def enum_supersets( enum_name, options = {} )
    enum_plural = enum_name.to_s.pluralize

    self.instance_eval do
      enum_obj = send(enum_plural)
      enum_obj.supersets.merge!( options.transform_values{ _1.try(:map, &:to_s) || _1.to_s } )

      options.each do |superset_name, enum_vals|
        raise "Can't define superset with name: #{superset_name}, #{enum_plural} already has such method!" if enum_obj.respond_to?(superset_name)

        enum_obj.supersets_raw[superset_name] = enum_obj.superset_to_enum(*enum_vals)

        # class.statuses.superset_statuses
        enum_obj.define_singleton_method(superset_name) { enum_obj.superset_to_enum(*enum_vals) }

        # superset_name scope
        scope superset_name, -> { where( enum_name => enum_obj.send(superset_name) ) } if respond_to?(:scope)

        # instance.superset_name?
        define_method "#{superset_name}?" do
          send(enum_name) && enum_obj.send(superset_name).include?( send(enum_name) )
        end

        EnumExt::HumanizeHelpers.define_superset_humanization_helpers( self, superset_name, enum_name )
      end

    end
  end
  alias_method :ext_enum_sets, :enum_supersets
end


