module EnumExt::BasicHelpers

  # Defines instance method a shortcut for getting integer value of an enum.
  # for enum named 'status' will generate:
  #
  # instance.status_i
  def enum_i( enum_name )
    define_method "#{enum_name}_i" do
      self.class.send("#{enum_name.to_s.pluralize}")[send(enum_name)].to_i
    end
  end

  # Defines two scopes for one for an inclusion: `WHERE enum IN( enum1, enum2 )`,
  # and the second for an exclusion: `WHERE enum NOT IN( enum1, enum2 )`
  #
  # Ex:
  #  Request.with_statuses( :payed, :delivery_set )    # >> :payed and [:ready_for_shipment, :on_delivery, :delivered] requests
  #  Request.without_statuses( :payed )                # >> scope for all requests with statuses not eq to :payed
  #  Request.without_statuses( :payed, :in_warehouse ) # >> scope all requests with statuses not eq to :payed or :ready_for_shipment
  def multi_enum_scopes(enum_name)
    enum_plural = enum_name.to_s.pluralize
    enum_obj = send(enum_plural)

    self.instance_eval do
      # EnumExt.define_superset_to_enum_method(self, enum_plural)
      # EnumExt.define_summary_methods(self, enum_plural)

      # with_enums scope
      scope "with_#{enum_plural}", -> (*enum_list) {
        enum_list.blank? ? nil : where( enum_name => enum_obj.superset_to_enum(*enum_list) )
      } if !respond_to?("with_#{enum_plural}") && respond_to?(:scope)

      # without_enums scope
      scope "without_#{enum_plural}", -> (*enum_list) {
        enum_list.blank? ? nil : where.not( enum_name => enum_obj.superset_to_enum(*enum_list) )
      } if !respond_to?("without_#{enum_plural}") && respond_to?(:scope)
    end
  end

  # Ex mass_assign_enum
  #
  # Used for mass assigning for collection without callbacks it creates bang methods for collections using update_all.
  # it's often case when you need bulk update without callbacks, so it's gets frustrating to repeat:
  # some_scope.update_all(status: Request.statuses[:new_status], update_at: Time.now)
  #
  # If you need callbacks you can do like this: some_scope.each(&:new_stat!) but if you don't need callbacks
  # and you have lots of records to change at once you need update_all
  #
  #  mass_assign_enum( :status )
  #
  #  class methods:
  #    in_cart! paid! in_warehouse! and so
  #
  # Console:
  # request1.in_cart!
  # request2.waiting_for_payment!
  # Request.with_statuses( :in_cart, :waiting_for_payment ).payed!
  # request1.paid?                          # >> true
  # request2.paid?                          # >> true
  # request1.updated_at                     # >> Time.now
  #
  # order.requests.paid.all?(&:paid?)       # >> true
  # order.requests.paid.delivered!
  # order.requests.map(&:status).uniq       #>> [:delivered]

  def mass_assign_enum( *enums_names )
    enums_names.each do |enum_name|
      enum_vals = self.send( enum_name.to_s.pluralize )

      enum_vals.keys.each do |enum_el|
        define_singleton_method( "#{enum_el}!" ) do
          self.update_all( {enum_name => enum_vals[enum_el]}.merge( self.column_names.include?('updated_at') ? {updated_at: Time.now} : {} ))
        end
      end
    end
  end
  alias_method :enum_mass_assign, :mass_assign_enum
end