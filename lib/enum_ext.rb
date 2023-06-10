require "enum_ext/version"
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
  def enum(definitions)
    extensions = definitions.delete(:ext)

    super(definitions).tap do |_enum|
      _enum.each do |enum_name,|
        # enum will freeze values so there is no other way than to create wrapper and delegate everything to enum_values
        enum_wrapper = EnumWrapper.new(send(enum_name.to_s.pluralize))
        define_singleton_method(enum_name.to_s.pluralize) { enum_wrapper }

        # [:enum_i, :enum_multi_scopes, enum_supersets: { valid: [:fresh, :cool], invalid: [:stale] }]
        #   --> [:enum_i, :enum_multi_scopes, [:enum_supersets, { valid: [:fresh, :cool], invalid: [:stale] }]
        [*extensions].map{ _1.is_a?(Hash) ? _1.to_a : _1 }
                     .flatten(1)
                     .each do |(ext_method, params)|
                       send(*[ext_method, enum_name, params].compact)
                     end
      end
    end
  end

end
