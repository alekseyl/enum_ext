# This is an wrapper class for a basic enum.
# Since enum values will be freezed right after the definition, we can't enrich enum directly functionality
# We can only wrap it with our own object and delegate enum base base functionality internally
class EnumExt::EnumWrapper
  attr_reader :enum_values, :supersets, :t_options_raw, :localizations
  delegate_missing_to :enum_values

  def initialize(enum_values)
    @enum_values = enum_values
    @supersets = ActiveSupport::HashWithIndifferentAccess.new

    @t_options_raw = ActiveSupport::HashWithIndifferentAccess.new
    @localizations = ActiveSupport::HashWithIndifferentAccess.new
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

  def t_options_i
    evaluate_localizations_to_i(localizations)
  end

  def t_options
    evaluate_localizations(localizations)
  end

  alias_method :t, :localizations

  private

  def evaluate_localizations(t_enum_set)
    # { kind => kind_translation, kind2 => kind2_translation } --> [[kind_translation, kind], [kind2_translation, kind2]]
    t_enum_set.invert.to_a.map do | translator, name |
      # since all procs in t_enum are evaluated in context of a record than it's not always possible to create select options automatically
      translation = if translator.respond_to?(:call)
        if translator.arity < 1
          translator.call rescue "Cannot create option for #{name} ( proc fails to evaluate )"
        else
          "Cannot create option for #{name} because of a lambda"
        end
      end || translator
      [translation, name]
    end
  end

  def evaluate_localizations_to_i(t_enum_set)
    # { kind => kind_translation, kind2 => kind2_translation } --> [[kind_translation, kind_i], [kind2_translation, kind2_i]]
    evaluate_localizations(t_enum_set).map do | translation, name |
      [ translation, self[name] ]
    end
  end

end