class EnumExt::EnumWrapper
  attr_reader :enum_values, :supersets, :t_options_raw
  delegate_missing_to :enum_values

  def initialize(enum_values)
    @enum_values = enum_values
    @supersets = ActiveSupport::HashWithIndifferentAccess.new
    @t_options_raw = ActiveSupport::HashWithIndifferentAccess.new
  end

  #  ext_sets_to_kinds( :ready_for_shipment, :delivery_set ) -->
  #                   [:ready_for_shipment, :on_delivery, :delivered]
  def superset_to_enum( *enum_or_sets )
    return [] if enum_or_sets.blank?
    enum_or_sets_strs = enum_or_sets.map(&:to_s)

    next_level_deeper = supersets.slice( *enum_or_sets_strs ).values.flatten
    (enum_or_sets_strs & enum_values.keys | send(:superset_to_enum, *next_level_deeper)).uniq
  end

  def all
    {
      **enum_values,
      supersets: {
        **send(:supersets)
      }
    }
  end

end


# t_... - are translation dependent methods
# This one is a narrow case helpers just a quick subset of t_ enums options for a set
# # class.t_enums_options
# define_singleton_method( "t_#{superset_name}_#{enum_plural}_options" ) do
#   return [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2] unless respond_to?( "t_#{enum_plural}_options_raw" )
#
#   send("t_#{enum_plural}_options_raw", send("t_#{superset_name}_#{enum_plural}") )
# end
#
# # class.t_enums_options_i
# define_singleton_method( "t_#{superset_name}_#{enum_plural}_options_i" ) do
#   return [["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2] unless respond_to?( "t_#{enum_plural}_options_raw_i" )
#
#   send("t_#{enum_plural}_options_raw_i", send("t_#{superset_name}_#{enum_plural}") )
# end
#
# # protected?
# # class.t_set_name_enums ( translations or humanizations subset for a given set )
# define_singleton_method( "t_#{superset_name}_#{enum_plural}" ) do
#   return [(["Enum translations call missed. Did you forget to call translate #{enum_name}"]*2)].to_h unless respond_to?( "t_#{enum_plural}" )
#
#   send( "t_#{enum_plural}" ).slice( *send("#{superset_name}_#{enum_plural}") )
# end