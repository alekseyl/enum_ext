require 'enum_ext/version'

# Let's assume we have model Request with enum status, and we have model Order with requests like this:
# class Request
#   extend EnumExt
#   belongs_to :order
#   enum status: { in_cart: 0, waiting_for_payment: 1, payed: 2, ready_for_shipment: 3, on_delivery: 4, delivered: 5 }
# end
#
# class Order
#   has_many :requests
# end
#
module EnumExt

  # defines shortcut for getting integer value of enum.
  # for enum named status will generate:
  # instance.status_i
  def enum_i( enum_name )
    define_method "#{enum_name}_i" do
      self.class.send("#{enum_name.to_s.pluralize}")[send(enum_name)].to_i
    end
  end


  # ext_enum_sets
  # This method intend for creating and using some sets of enum values
  # it creates: scopes for subsets,
  #             instance method with ?,
  #             and some class methods helpers
  #
  # For this call:
  #   ext_enum_sets :status, {
  #                   delivery_set: [:ready_for_shipment, :on_delivery, :delivered] # for shipping department for example
  #                   in_warehouse: [:ready_for_shipment]  # this just for superposition example  below
  #                 }
  #
  # it will generate:
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
  #
  #  Request.with_statuses( :payed, :delivery_set )    # >> :payed and [:ready_for_shipment, :on_delivery, :delivered] requests
  #  Request.without_statuses( :payed )                # >> scope for all requests with statuses not eq to :payed
  #  Request.without_statuses( :payed, :in_warehouse ) # >> scope all requests with statuses not eq to :payed or :ready_for_shipment
  #

  #Rem:
  #  ext_enum_sets can be called twice defining a superposition of already defined sets ( considering previous example ):
  #  ext_enum_sets :status, {
  #                  outside_wharehouse: ( delivery_set_statuses - in_warehouse_statuses )... any other array operations like &, + and so can be used
  #                }
  def ext_enum_sets( enum_name, options )
    enum_plural = enum_name.to_s.pluralize

    self.instance_eval do
      options.each do |set_name, enum_vals|
        # set_name scope
        scope set_name, -> { where( enum_name => self.send( enum_plural ).slice( *enum_vals.map(&:to_s) ).values ) }

        # with_enums scope
        scope "with_#{enum_plural}", -> (sets_arr) {
          where( enum_name => self.send( enum_plural ).slice(
                     *sets_arr.map{|set_name| self.try( "#{set_name}_#{enum_plural}" ) || set_name }.flatten.uniq.map(&:to_s) ).values )
        } unless respond_to?("with_#{enum_plural}")

        # without_enums scope
        scope "without_#{enum_plural}", -> (sets_arr) {
          where.not( id: self.send("with_#{enum_plural}", sets_arr) )
        } unless respond_to?("without_#{enum_plural}")


        # class.enum_set_values
        define_singleton_method( "#{set_name}_#{enum_plural}" ) do
          enum_vals
        end

        # class.enum_set_enums_i
        define_singleton_method( "#{set_name}_#{enum_plural}_i" ) do
          self.send( "#{enum_plural}" ).slice( *self.send("#{set_name}_#{enum_plural}") ).values
        end

        # t_... - are translation dependent methods
        # class.t_enums_options
        define_singleton_method( "t_#{set_name}_#{enum_plural}_options" ) do
          return [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2] unless respond_to?( "t_#{enum_plural}_options_raw" )

          send("t_#{enum_plural}_options_raw", send("t_#{set_name}_#{enum_plural}") )
        end

        # class.t_enums_options_i
        define_singleton_method( "t_#{set_name}_#{enum_plural}_options_i" ) do
          return [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2] unless respond_to?( "t_#{enum_plural}_options_raw_i" )

          send("t_#{enum_plural}_options_raw_i", send("t_#{set_name}_#{enum_plural}") )
        end

        # instance.set_name?
        define_method "#{set_name}?" do
          self.send(enum_name) && ( enum_vals.include?( self.send(enum_name) ) || enum_vals.include?( self.send(enum_name).to_sym ))
        end

        # protected?
        # class.t_setname_enums ( translations or humanizations subset for a given set )
        define_singleton_method( "t_#{set_name}_#{enum_plural}" ) do
          return [(["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2)].to_h unless respond_to?( "t_#{enum_plural}" )

          send( "t_#{enum_plural}" ).slice( *self.send("#{set_name}_#{enum_plural}") )
        end
      end
    end
  end

  # Ex mass_assign_enum
  # Used for mass assigning for collection without callbacks it creates bang methods for collections using update_all.
  # it's often case when you need bulk update without callbacks, so it's gets frustrating to repeat:
  # some_scope.update_all(status: Request.statuses[:new_status], update_at: Time.now)
  # If you need callbacks you can do like this: some_scope.each(&:new_stat!) but if you don't need callbacks and you have lots of records
  # to change at once you need update_all
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
  # request1.paid?                         # >> true
  # request2.paid?                         # >> true
  # request1.updated_at                     # >> Time.now
  # defined?(Request::MassAssignEnum)      # >> true
  #
  # order.requests.paid.all?(&:paid?) # >> true
  # order.requests.paid.delivered!
  # order.requests.map(&:status).uniq                   #>> [:delivered]

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

  # if app doesn't need internationalization, it may use humanize_enum to make enum user friendly
  # class Request
  # humanize_enum :status, {
  #     #locale dependent example with pluralization and lambda:
  #     payed: -> (t_self) { I18n.t("request.status.payed", count: t_self.sum ) }
  #
  #     #locale dependent example with pluralization and proc:
  #     payed: Proc.new{ I18n.t("request.status.payed", count: self.sum ) }
  #
  #     #locale independent:
  #     ready_for_shipment: "Ready to go!"
  #   }
  # end
  #
  # Example with block:
  #
  # humanize_enum :status do
  #  I18n.t("scope.#{status}")
  # end
  #
  # in select:
  #   f.select :status, Request.t_statuses_options
  #
  # in select in Active Admin filter
  #   collection: Request.t_statuses_options_i
  #
  # Rem: select options breaks when using lambda() with params
  #
  # Console:
  #   request.sum = 3
  #   request.payed!
  #   request.status     # >> payed
  #   request.t_status   # >> "Payed 3 dollars"
  #   Request.t_statuses # >> { in_cart: -> { I18n.t("request.status.in_cart") }, ....  }
  def humanize_enum( *args, &block )
    enum_name = args.shift
    localizations = args.pop
    enum_plural = enum_name.to_s.pluralize

    self.instance_eval do

      #t_enums
      define_singleton_method( "t_#{enum_plural}" ) do
        # if localization is abscent than block must be given
        localizations.try(:with_indifferent_access) || localizations ||
            send(enum_plural).keys.map {|en| [en, self.new( {enum_name => en} ).send("t_#{enum_name}")] }.to_h.with_indifferent_access
      end

      #t_enums_options
      define_singleton_method( "t_#{enum_plural}_options" ) do
        send("t_#{enum_plural}_options_raw", send("t_#{enum_plural}") )
      end

      #t_enums_options_i
      define_singleton_method( "t_#{enum_plural}_options_i" ) do
        send("t_#{enum_plural}_options_raw_i", send("t_#{enum_plural}") )
      end

      #t_enum
      define_method "t_#{enum_name}" do
        t = block || localizations.try(:with_indifferent_access)[send(enum_name)]
        if t.try(:lambda?)
          t.try(:arity) == 1 && t.call( self ) || t.try(:call)
        elsif t.is_a?(Proc)
          instance_eval(&t)
        else
          t
        end.to_s
      end

      #protected?
      define_singleton_method( "t_#{enum_plural}_options_raw_i" ) do |t_enum_set|
        send("t_#{enum_plural}_options_raw", t_enum_set ).map do | key_val |
          key_val[1] = send(enum_plural)[key_val[1]]
          key_val
        end
      end

      define_singleton_method( "t_#{enum_plural}_options_raw" ) do |t_enum_set|
        t_enum_set.invert.to_a.map do | key_val |
          # since all procs in t_enum are evaluated in context of a record than it's not always possible to create select options
          if key_val[0].respond_to?(:call)
            if key_val[0].try(:arity) < 1
              key_val[0] = key_val[0].try(:call) rescue "Cannot create option for #{key_val[1]} ( proc fails to evaluate )"
            else
              key_val[0] = "Cannot create option for #{key_val[1]} because of a lambda"
            end
          end
          key_val
        end
      end

    end
  end
  alias localize_enum humanize_enum

  # Simple way to translate enum.
  # It use either given scope as second argument, or generated activerecord.attributes.model_name_underscore.enum_name
  # If block is given than no scopes are taken in consider
  def translate_enum( *args, &block )
    enum_name = args.shift
    enum_plural = enum_name.to_s.pluralize
    t_scope = args.pop || "activerecord.attributes.#{self.name.underscore}.#{enum_plural}"

    if block_given?
      humanize_enum( enum_name, &block )
    else
      humanize_enum( enum_name, send(enum_plural).keys.map{|en| [ en, Proc.new{ I18n.t("#{t_scope}.#{en}") }] }.to_h )
    end
  end

  # human_attribute_name is redefined for automatization like this:
  # p #{object.class.human_attribute_name( attr_name )}:
  # p =object.send(attr_name)
  def human_attribute_name( name, options = {} )
    name[0..1] == 't_' && column_names.include?(name[2..-1]) ? super( name[2..-1], options ) : super( name, options )
  end


end
