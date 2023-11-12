require "enum_ext/version"
require "enum_ext/config"
require "enum_ext/annotated"
require "enum_ext/enum_wrapper"
require "enum_ext/humanize_helpers"
require "enum_ext/basic_helpers"
require "enum_ext/superset_helpers"

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

module EnumExt
  include HumanizeHelpers   # translate and humanize
  include SupersetHelpers   # enum_supersets
  include BasicHelpers      # enum_i, mass_assign, multi_enum_scopes

  # extending enum with inplace settings
  # enum status: {}, ext: [:enum_i, :mass_assign_enum, :enum_multi_scopes, enum_supersets: {  }]
  # and wrapping and replacing original enum with a wrapper object
  #
  # I'm using signature of a ActiveRecord 7 here: enum(name = nil, values = nil, **options)
  # in earlier versions of ActiveRecord signature looks different: enum(definitions),
  # so calling super should be different based on ActiveRecord major version
  def enum(name = nil, values = nil, **options)
    single_enum_definition = name.present?
    extensions = [*EnumExt.config.default_helpers, *options.delete(:ext)]
    options_dup = options.dup

    (ActiveRecord::VERSION::MAJOR >= 7 ? super : super(options)).tap do |multiple_enum_definitions|
      if single_enum_definition
        replace_enum_with_wrapper(name, options_dup)
        enum_ext(name, [*extensions])
      else
        multiple_enum_definitions.each { |enum_name,|
          replace_enum_with_wrapper(enum_name, options_dup)
          enum_ext(enum_name, [*extensions])
        }
      end
    end
  end

  # its an extension helper, on the opposite to basic enum method could be called multiple times
  def enum_ext(enum_name, extensions)
    # [:enum_i, :enum_multi_scopes, enum_supersets: { valid: [:fresh, :cool], invalid: [:stale] }]
    #   --> [:enum_i, :enum_multi_scopes, [:enum_supersets, { valid: [:fresh, :cool], invalid: [:stale] }]
    [*extensions].map { _1.try(:to_a)&.flatten || _1 }
                 .each { |(ext_method, params)| send(*[ext_method, enum_name, params].compact) }
  end

  private

  def replace_enum_with_wrapper(enum_name, options_dup)
    enum_name_plural = enum_name.to_s.pluralize
    return if send(enum_name_plural).is_a?(EnumWrapper)

    # enum will freeze values so there is no other way to move extended functionality,
    # than to use wrapper and delegate everything to enum_values
    enum_wrapper = EnumWrapper.new(send(enum_name_plural), self, enum_name, **options_dup)
    # "self" here is a base enum class, so we are replacing original enum definition, with a wrapper
    define_singleton_method(enum_name_plural) { enum_wrapper }
  end

end
