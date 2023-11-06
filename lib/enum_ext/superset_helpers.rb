module EnumExt::SupersetHelpers
  # enum_supersets
  # **Use-case** whenever you need superset of enums to behave like a super enum.
  #
  #   You can do this with method **enum_supersets** it creates:
  #     - scopes for subsets,
  #     - instance methods with `?`
  #
  #   For example:
  #    enum status: [:in_cart, :waiting_for_payment, :paid, :packing, :ready_for_shipment, :on_delivery, :delivered],
  #         ext: [enum_supersets: {
  #                 around_delivery: [:ready_for_shipment, :on_delivery], # for shipping department for example
  #                 in_warehouse: [:packing, :ready_for_shipment],    # this scope is just for superposition example below
  #                 sold: [:paid, :around_delivery, :in_warehouse, :delivered] # also you can define any superposition of already defined supersets or enum values
  #               }]
  #
  #    # supersets will be stored inside enum wrapper object, and can be de-referenced to basic enum values
  #    # using wrapper defined methods: "superset_enum_plural", i.e. statuses.sold_statuses -> [:paid, :packing, :ready_for_shipment, :on_delivery, :delivered]
  #    # so new supersets could be defined using Array operations against newly defined methods
  #    enum_ext :status, enum_supersets: {
  #                   outside_warehouse: ( statuses.around_delivery - statuses.in_warehouse ) #... any other array operations like &, + and so can be used
  #                 }
  #
  #   it will generate:
  #
  # instance:
  #   - methods: around_delivery?, in_warehouse?
  #
  # class:
  #   - named scopes: around_delivery, in_warehouse
  #
  # enum methods:
  #   - Class.statuses.supersets -- will output superset definition hash
  #   - Class.statuses.supersets_raw -- will output superset decompositions to basic enum types hash
  #
  #   - Class.statuses.around_delivery (=[:ready_for_shipment, :on_delivery, :delivered] ), in_warehouse_statuses
  #   - around_delivery_statuses_i (= [3,4,5]), in_warehouse_statuses_i (=[3])
  #
  #   translation helpers grouped for superset ( started with t_... ):
  #   - Class.statuses.t_around_delivery_options (= [['translation or humanization', :ready_for_shipment] ...] ) for select inputs purposes
  #   - Class.statuses.t_around_delivery_options_i (= [['translation or humanization', 3] ...]) same as above but with integer as value ( for example to use in Active admin filters )
  #
  #   In console:
  #   request.on_delivery!
  #   request.around_delivery?                    # >> true
  #
  #   Request.around_delivery.exists?(request)    # >> true
  #   Request.in_warehouse.exists?(request)    # >> false
  #
  #   Request.statuses.around_delivery            # >> ["ready_for_shipment", "on_delivery", "delivered"]

  private
  def enum_supersets( enum_name, options = {} )
    enum_plural = enum_name.to_s.pluralize

    self.instance_eval do
      suffix = send(enum_plural).suffix
      prefix = send(enum_plural).prefix
      send(enum_plural).supersets.merge!( options.transform_values{ _1.try(:map, &:to_s) || _1.to_s } )

      options.each do |superset_name, enum_vals|
        raise "Can't define superset with name: #{superset_name}, #{enum_plural} already has such method!" if send(enum_plural).respond_to?(superset_name)

        send(enum_plural).supersets_raw[superset_name] = send(enum_plural).superset_to_enum(*enum_vals)

        # class.enum_wrapper.superset
        send(enum_plural).define_singleton_method(superset_name) { base_class.send(enum_plural).superset_to_enum(*enum_vals) }

        superset_method_name = send(enum_plural).transform_enum_label(label: superset_name)
        # superset_name scope
        scope superset_method_name, -> { where( enum_name => send(enum_plural).send(superset_name) ) } if respond_to?(:scope)

        # instance.superset_name?
        define_method "#{superset_method_name}?" do
          send(enum_name) && self.class.send(enum_plural).send(superset_name).include?( send(enum_name) )
        end

        EnumExt::HumanizeHelpers.define_superset_humanization_helpers( self, superset_name, enum_name )
      end

    end
  end
  alias_method :ext_enum_sets, :enum_supersets
end


