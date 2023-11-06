# This is an wrapper class for a basic enum.
# Since enum values will be freezed right after the definition, we can't enrich enum directly functionality
# We can only wrap it with our own object and delegate enum base base functionality internally
class EnumExt::EnumWrapper
  include EnumExt::Annotated

  # supersets is storing exact definitions, if you need a raw mapping use class.statuses.superset_statuses
  attr_reader :enum_values, :supersets, :supersets_raw, :t_options_raw, :localizations, :base_class, :enum_name, :suffix, :prefix

  delegate_missing_to :enum_values
  delegate :inspect, to: :enum_values

  def initialize(enum_values, base_class, enum_name, **options)
    @enum_values = enum_values
    @supersets = ActiveSupport::HashWithIndifferentAccess.new
    @supersets_raw = ActiveSupport::HashWithIndifferentAccess.new

    @t_options_raw = ActiveSupport::HashWithIndifferentAccess.new
    @localizations = ActiveSupport::HashWithIndifferentAccess.new

    @base_class = base_class
    @enum_name = enum_name
    @suffix = options[:suffix] || options[:_suffix]
    @prefix = options[:prefix] || options[:_prefix]
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
        **send(:supersets_raw)
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

  def transform_enum_label(label)
    _prefix = if prefix
      prefix == true ? "#{enum_name}_" : "#{prefix}_"
    end

    _suffix = if suffix
      suffix == true ? "_#{enum_name}" : "_#{suffix}"
    end

    "#{_prefix}#{label}#{_suffix}"
  end

  private

  def evaluate_localizations(t_enum_set)
    # { kind => kind_translator, kind2 => kind2_translator } --> [[kind_translator, kind], [kind2_translator, kind2]]
    t_enum_set.invert.to_a.map do | translator, enum_key |
      # since all procs in t_enum are evaluated in context of a record than it's not always possible to create select options automatically
      translation = if translator.respond_to?(:call)
        if translator.arity < 1
          translator.call rescue "Cannot create option for #{enum_key} ( proc fails to evaluate )"
        else
          "Cannot create option for #{enum_key} because of a lambda"
        end
      end || translator
      [translation, enum_key]
    end
  end

  def evaluate_localizations_to_i(t_enum_set)
    # { kind => kind_translation, kind2 => kind2_translation } --> [[kind_translation, kind_i], [kind2_translation, kind2_i]]
    evaluate_localizations(t_enum_set).map do | translation, name |
      [ translation, self[name] ]
    end
  end



end