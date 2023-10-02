require "enum_ext/version"
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

puts <<~DEPRECATION
  ---------------------DEPRECATION WARNING---------------------------
  There are TWO MAJOR breaking changes coming into the next major version :
  First deprecation: all major DSL moving class methods to 
  enum, just for the sake of clarity:  

  Ex for enum named kinds it could look like this: 

    Class.ext_sets_to_kinds         --> Class.kinds.superset_to_basic
    Class.ext_kinds                 --> Class.kinds.supersets
    Class.all_kinds_defs            --> Class.kinds.all
   
    Class.t_kinds                   --> Class.kinds.t
    Class.t_kinds_options           --> Class.kinds.t_options
    Class.t_named_set_kinds_options --> Class.kinds.t_named_set_options

DEPRECATION

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
    extensions = options.delete(:ext)

    (ActiveRecord::VERSION::MAJOR >= 7 ? super : super(options)).tap do |multiple_enum_definitions|
      if single_enum_definition
        enum_ext(name, extensions)
      else
        multiple_enum_definitions.each { |enum_name,| enum_ext(enum_name, extensions) }
      end
    end
  end

  # its an extension helper, on the opposite to basic enum method could be called multiple times
  def enum_ext(enum_name, extensions)
    replace_enum_with_wrapper(enum_name)
      # [:enum_i, :enum_multi_scopes, enum_supersets: { valid: [:fresh, :cool], invalid: [:stale] }]
    #   --> [:enum_i, :enum_multi_scopes, [:enum_supersets, { valid: [:fresh, :cool], invalid: [:stale] }]
    [*extensions].map { _1.try(:to_a)&.flatten || _1 }
                 .each { |(ext_method, params)| send(*[ext_method, enum_name, params].compact) }
  end

  private
  def replace_enum_with_wrapper(enum_name)
    enum_name_plural = enum_name.to_s.pluralize
    return if send(enum_name_plural).is_a?(EnumWrapper)

    # enum will freeze values so there is no other way to move extended functionality,
    # than to use wrapper and delegate everything to enum_values
    enum_wrapper = EnumWrapper.new(send(enum_name_plural), self, enum_name)
    # "self" here is a base enum class, so we are replacing original enum definition, with a wrapper
    define_singleton_method(enum_name_plural) { enum_wrapper }
  end

end
