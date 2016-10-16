require "enum_ext/version"

# Let's assume we have model Request with enum status, and we have model Order with requests like this:
# class Request
#   extend EnumExt
#   belongs_to :order
#   enum status: [ :in_cart, :waiting_for_payment, :payed, :ready_for_shipment, :on_delivery, :delivered ]
# end
#
# class Order
#   has_many :requests
# end
#
module EnumExt
  # Ex using localize_enum with Request
  # class Request
  #  ...
  #  localize_enum :status, {
  #
  #     #locale dependent example ( it dynamically use current locale ):
  #     in_cart: -> { I18n.t("request.status.in_cart") },

  #     #locale dependent example with pluralization and lambda:
  #     payed: -> (t_self) { I18n.t("request.status.payed", count: t_self.sum ) }

  #     #locale dependent example with pluralization and proc:
  #     payed: proc{ I18n.t("request.status.payed", count: self.sum ) }
  #
  #     #locale independent:
  #     ready_for_shipment: "Ready to go!"
  #
  #
  #   }
  # end

  # Console:
  #   request.sum = 3
  #   request.payed!
  #   request.status # >> payed
  #   request.t_status # >> "Payed 3 dollars"
  #   Request.t_statuses # >> { in_cart: -> { I18n.t("request.status.in_cart") }, ....  }

  #   if you need some substitution you can go like this
  #   localize_enum :status, {
  #         ..
  #    delivered: "Delivered at: %{date}"
  #   }
  #   request.delivered!
  #   request.t_status % {date: Time.now.to_s} # >> Delivered at: 05.02.2016
  #
  # Using in select:
  #   f.select :status, Request.t_statuses.invert.to_a
  #
  def localize_enum( enum_name, localizations )
    self.instance_eval do
      define_singleton_method( "t_#{enum_name.to_s.pluralize}" ) do
        localizations.try(:with_indifferent_access) || localizations
      end
      define_method "t_#{enum_name}" do
        t = localizations.try(:with_indifferent_access)[send(enum_name)]
        if t.try(:lambda?)
          t.try(:arity) == 1 && t.call( self ) || t.try(:call)
        elsif t.is_a?(Proc)
          instance_eval(&t)
        else
          t
        end.to_s
      end
    end
  end

  # Ex ext_enum_sets
  # This method intend for creating and using some sets of enum values with similar to original enum syntax
  # it creates: scopes for subsets like enum did, instance method with ? similar to enum methods, and methods like Request.statuses
  # Usually I supply comment near method call to remember what methods will be defined
  #  class Request
  #   ...
  #   #instance non_payed?, delivery_set?, in_warehouse?
  #   #class scopes: non_payed, delivery_set, in_warehouse
  #   #class scopes: with_statuses, without_statuses
  #   #class non_payed_statuses, delivery_set_statuses ( = [:in_cart, :waiting_for_payment], [:ready_for_shipment, :on_delivery, :delivered].. )
  #   ext_enum_sets :status, {
  #                   non_payed: [:in_cart, :waiting_for_payment],
  #                   delivery_set: [:ready_for_shipment, :on_delivery, :delivered] # for shipping department for example
  #                   in_warehouse: [:ready_for_shipment]                           # it's just for example below
  #                 }
  #  end

  # Console:
  #  request.waiting_for_payment!
  #  request.non_payed?                    # >> true

  #  Request.non_payed.exists?(request)    # >> true
  #  Request.delivery_set.exists?(request) # >> false

  #  Request.non_payed_statuses            # >> [:in_cart, :waiting_for_payment]
  #
  #  Request.with_statuses( :payed, :in_cart )      # >> scope for all in_cart and payed requests
  #  Request.without_statuses( :payed )             # >> scope for all requests with statuses not eq to payed
  #  Request.without_statuses( :payed, :non_payed ) # >> scope all requests with statuses not eq to payed and in_cart + waiting_for_payment
  #

  #Rem:
  #  ext_enum_sets can be called twice defining a superpositoin of already defined sets:
  #  class Request
  #    ...
  #    ext_enum_sets (... first time call )
  #    ext_enum_sets :status, {
  #                      already_payed: ( [:payed] | delivery_set_statuses ),
  #                      outside_wharehouse: ( delivery_set_statuses - in_warehouse_statuses )... any other array operations like &, + and so can be used
  #                   }
  def ext_enum_sets( enum_name, options )
    self.instance_eval do
      options.each do |set_name, enum_vals|
        scope set_name, -> { where( enum_name => self.send( enum_name.to_s.pluralize ).slice( *enum_vals.map(&:to_s) ).values ) }

        define_singleton_method( "#{set_name}_#{enum_name.to_s.pluralize}" ) do
          enum_vals
        end

        define_method "#{set_name}?" do
          self.send(enum_name) && ( enum_vals.include?( self.send(enum_name) ) || enum_vals.include?( self.send(enum_name).to_sym ))
        end

      end

      scope "with_#{enum_name.to_s.pluralize}", -> (sets_arr) {
        where( enum_name => self.send( enum_name.to_s.pluralize ).slice(
                   *sets_arr.map{|set_name| self.try( "#{set_name}_#{enum_name.to_s.pluralize}" ) || set_name }.flatten.uniq.map(&:to_s) ).values )
      } unless respond_to?("with_#{enum_name.to_s.pluralize}")

      scope "without_#{enum_name.to_s.pluralize}", -> (sets_arr) {
        where.not( id: self.send("with_#{enum_name.to_s.pluralize}", sets_arr) )
      } unless respond_to?("without_#{enum_name.to_s.pluralize}")
    end
  end

  # Ex mass_assign_enum
  # Used for mass assigning for collection, it creates dynamically nested module with methods similar to enum bang methods, and includes it to relation classes
  # Behind the scene it creates bang methods for collections using update_all.
  # it's often case when I need bulk update without callbacks, so it's gets frustrating to repeat: some_scope.update_all(status: Request.statuses[:new_status], update_at: Time.now)
  # If you need callbacks you can do like this: some_scope.each(&:new_stat!) but if you don't need callbacks and you has hundreds and thousands of records to change at once you need update_all
  #
  # class Request
  #   ...
  #   mass_assign_enum( :status )
  # end
  #
  # Console:
  # request1.in_cart!
  # request2.waiting_for_payment!
  # Request.non_payed.payed!
  # request1.payed?                         # >> true
  # request2.payed?                         # >> true
  # request1.updated_at                     # >> Time.now
  # defined?(Request::MassAssignEnum)      # >> true
  #
  # order.requests.already_payed.all?(&:already_payed?) # >> true
  # order.requests.already_payed.delivered!
  # order.requests.map(&:status).uniq                   #>> [:delivered]
  #
  #
  # Rem:
  # mass_assign_enum accepts additional options as last argument.
  # calling  mass_assign_enum( :status ) actually is equal to call: mass_assign_enum( :status, { relation: true, association_relation: true } )
  #
  # Meaning:

  # relation: true - Request.some_scope.payed! - works

  # association_relation: true - Order.first.requests.scope.new_stat! - works
  # but it wouldn't works without 'scope' part! If you want to use it without 'scope' you may do it this way:
  # class Request
  #   ...
  #   mass_assign_enum( :status, association_relation: false )
  # end
  # class Order
  #  has_many :requests, extend: Request::MassAssignEnum
  # end
  #
  # Order.first.requests.respond_to?(:in_cart!) # >> true
  #
  # Rem2:
  # you can mass-assign more than one enum ::MassAssignEnum module will contain mass assign for both. It will break nothing since all enum name must be uniq across model

  def mass_assign_enum( *options )
    relation_options = (options[-1].is_a?(Hash) && options.pop || {relation: true, association_relation: true} ).with_indifferent_access
    enums_names = options
    enums_names.each do |enum_name|
      enum_vals = self.send( enum_name.to_s.pluralize )

      mass_ass_module = ( defined?(self::MassAssignEnum) && self::MassAssignEnum || Module.new )

      mass_ass_module.instance_eval do
        enum_vals.keys.each do |enum_el|
          define_method( "#{enum_el}!" ) do
            self.update_all( {enum_name => enum_vals[enum_el]}.merge( self.column_names.include?('updated_at') ? {updated_at: Time.now} : {} ))
          end
        end
      end
      self.const_set( :MassAssignEnum, mass_ass_module ) unless defined?(self::MassAssignEnum)

      self::ActiveRecord_Relation.include( self::MassAssignEnum ) if relation_options[:relation]
      self::ActiveRecord_AssociationRelation.include( self::MassAssignEnum ) if relation_options[:association_relation]
    end
  end

end
