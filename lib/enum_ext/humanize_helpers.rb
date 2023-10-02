module EnumExt::HumanizeHelpers

  # if app doesn't need internationalization, it may use humanize_enum to make enum user friendly
  #
  # class Request
  #   humanize_enum :status, {
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
  # Could be called multiple times, all humanization definitions will be merged under the hood:
  #  humanize_enum :status, {
  #     payed: I18n.t("scope.#{status}")
  # }
  # humanize_enum :status, {
  #   billed: I18n.t("scope.#{status}")
  # }
  #
  #
  # Example with block:
  #
  # humanize_enum :status do
  #  I18n.t("scope.#{status}")
  # end
  #
  # in views select:
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
    localization_definitions = args.pop
    enum_plural = enum_name.to_s.pluralize
    enum_object = send( enum_plural )

    self.instance_eval do
      # instance.t_enum
      define_method "t_#{enum_name}" do
        t = block || enum_object.localizations[send(enum_name)]
        if t.try(:lambda?)
          t.try(:arity) == 1 && t.call( self ) || t.try(:call)
        elsif t.is_a?(Proc)
          instance_eval(&t)
        else
          t
        end.to_s
      end

      # if localization is absent than block must be given
      enum_object.localizations.merge!(
        localization_definitions.try(:with_indifferent_access) ||
          send(enum_plural).map do |k, _v|
            # little bit hackerish: instantiate object just with enum setup and then call its t_.. method which
            [k, Proc.new{ self.new({ enum_name => k }).send("t_#{enum_name}") }]
          end.to_h.with_indifferent_access
      )

      # hm.. lost myself here, why did I implement this method
      define_method "t_#{enum_name}=" do |new_val|
        send("#{enum_name}=", new_val)
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

  # human_attribute_name is redefined for automation like this:
  # p #{object.class.human_attribute_name( attr_name )}:
  # p object.send(attr_name)
  def human_attribute_name( name, options = {} )
    # if name starts from t_ and there is a column with the last part then ...
    name[0..1] == 't_' && column_names.include?(name[2..-1]) ? super( name[2..-1], options ) : super( name, options )
  end


  # t_... methods for supersets will just slice
  # original enum t_.. methods output and return only superset related values from it
  #
  def self.define_superset_humanization_helpers(base_class, superset_name, enum_name)
    enum_plural = enum_name.to_s.pluralize
    enum_object = base_class.send(enum_plural)

    enum_object.define_singleton_method( "t_#{superset_name}_options" ) do
      result = evaluate_localizations(send("t_#{superset_name}"))
      return result unless result.blank?

      [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2]
    end

    # enums.t_options_i
    enum_object.define_singleton_method( "t_#{superset_name}_options_i" ) do
      result = evaluate_localizations_to_i( send("t_#{superset_name}") )
      return result unless result.to_h.values.all?(&:blank?)

      [["Enum translations are missing. Did you forget to translate #{enum_name}"]*2]
    end


    # enums.t_superset ( translations or humanizations subset for a given set )
    enum_object.define_singleton_method( "t_#{superset_name}" ) do
      return [(["Enum translations are missing. Did you forget to translate #{enum_name}"]*2)].to_h if localizations.blank?

      enum_object.localizations.slice( *enum_object.send(superset_name) )
    end
  end
end


# # t_... - are translation dependent methods
# # This one is a narrow case helpers just a quick subset of t_ enums options for a set
# # class.t_enums_options
# enum_obj.define_singleton_method( "t_#{superset_name}_options" ) do
#   return [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2] unless respond_to?( "t_#{enum_plural}_options_raw" )
#
#   send("t_#{enum_plural}_options_raw", send("t_#{superset_name}_#{enum_plural}") )
# end
#
# # class.t_enums_options_i
# enum_obj.define_singleton_method( "t_#{superset_name}_options_i" ) do
#   return [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2] unless respond_to?( "t_#{enum_plural}_options_raw_i" )
#
#   send("t_#{enum_plural}_options_raw_i", send("t_#{superset_name}_#{enum_plural}") )
# end
#
# enum_obj.define_singleton_method( "t_#{superset_name}_options" ) do
#   return [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2] if t_options_raw.blank?
#
#   t_options_raw["t_#{superset_name}"]
# end