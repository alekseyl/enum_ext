# I wanted to add some quick live annotation to what's defined and how it could be used
# but have no idea how to do this in a super-neat way, so it a little bit chaotic and experimental
module EnumExt::Annotated

  # call it to see what's your enum current opitons
  def describe_basic
    puts yellow( "Basic #{enum_name} definition: \n" )
    print_hash(enum_values)
  end

  # call it to see all enum extensions defined.
  def describe_long
    puts yellow( "\nEnumExt extensions:" )

    puts [
      describe_enum_i(false),
      describe_mass_assign_enum(false),
      describe_multi_enum_scopes(false),
      describe_supersets(false),
      describe_translations(false),
      describe_humanizations(false)
    ].join( "\n" + "-" * 100 + "\n" )
  end

  def describe(short = true)
    describe_basic
    short ? describe_short : describe_long
  end

  def describe_short
    enabled, disabled = enabled_features.except(:key_sample).partition{!_2.blank?}.map{ |prt| prt.map(&:shift) }
    puts <<~SHORT
      #{yellow("EnumExt extensions:")}
      #{cyan("Enabled")}: #{enabled.join(", ")}
      #{red("Disabled")}: #{disabled.join(", ")}
    SHORT

    print_short(:supersets)
    print_short(:translations)
    print_short(:humanization)
  end

  # --------------------------------------------------------------------
  # ------------- per helpers describers -------------------------------
  # --------------------------------------------------------------------
  def describe_enum_i(output = true)
    description = basic_helpers_usage_header(:enum_i)
    description << <<~ENUM_I if enabled_features[:enum_i]
      #{black("instance")}.#{cyan( enabled_features[:enum_i] )} 
      # output will be same as #{base_class.to_s}.#{enum_name}[:#{enabled_features[:key_sample]}]
    ENUM_I

    output ? puts(description) : description
  end

  def describe_mass_assign_enum(output = true)
    description = basic_helpers_usage_header(:mass_assign_enum)
    description << <<~MASS_ASSIGN if enabled_features[:mass_assign_enum]
      # To assign #{enabled_features[:key_sample]} to all elements of any_scope or relation call:
      #{black(base_class.to_s)}.any_scope.#{cyan( enabled_features[:mass_assign_enum] )}
    MASS_ASSIGN

    output ? puts(description) : description
  end

  def describe_multi_enum_scopes(output = true)
    description = basic_helpers_usage_header(:multi_enum_scopes)
    description << <<~MULTI_SCOPES if enabled_features[:multi_enum_scopes]
      # Two scopes: with_#{enum_name} and without_#{enum_name} are defined
      # To get elements with a given enums or supersets values call:
      #{black(base_class.to_s)}.#{cyan("with_#{enum_name}")}(:#{keys.sample(2).join(", :")})
      \n# To get all elements except for the ones with enums or supersets values call:
      #{black(base_class.to_s)}.#{cyan("without_#{enum_name}")}(:#{keys.sample(2).join(", :")})
    MULTI_SCOPES

    output ? puts(description) : description
  end

  def describe_supersets(output = true)
    description = if enabled_features[:supersets].blank?
      red( "\nSupersets not used!\n" )
    else
      red( "\nSupersets definitions:\n" ) << inspect_hash(enabled_features[:supersets]) << <<~SUPERSETS
          # Instance methods added: #{enabled_features[:supersets].keys.join("?, ")}?
   
          # Class level methods added: #{enabled_features[:supersets].keys.join(", ")}
       SUPERSETS
    end

    output ? puts(description) : description
  end

  def describe_translations(output = true)
    description = if enabled_features[:translations].blank?
      red( "\nTranslations not used!\n" )
    else
      red( "\nTranslations definitions (will skip instance dependent translation)\n" ) <<
        inspect_hash(enabled_features[:translations])
    end

    output ? puts(description) : description
  end

  def describe_humanizations(output = true)
    description = if enabled_features[:humanization].blank?
      red( "\nHumanization not used!\n" )
    else
      red( "\nHumanization definitions (will skip instance dependent humanization)\n" ) <<
        inspect_hash(enabled_features[:humanization])
    end

    output ? puts(description) : description
  end

  private

  def enabled_features
    enum_sample = keys.first
    {
      key_sample: enum_sample,
      enum_i: base_class.instance_methods.include?("#{enum_name}_i".to_sym) && "#{enum_name}_i",
      mass_assign_enum: base_class.respond_to?("#{enum_sample}!") && "#{enum_sample}!",
      multi_enum_scopes: base_class.respond_to?("with_#{enum_name.to_s.pluralize}") && "with_#{enum_name.to_s.pluralize}",
      supersets: supersets_raw,
      translations: try(:t_options),
      humanization: try(:t_options)
    }
  end

  def basic_helpers_usage_header(helper_name)
    enabled_features[helper_name] ? "\n#{red(helper_name)} helpers enabled, usage:\n"
           : "\n#{helper_name} wasn't used\n"
  end

  def print_hash(hsh)
    defined?(ai) ? ap(hsh) : pp(hsh)
  end

  def inspect_hash(hsh)
    defined?(ai) ? hsh.ai : hsh.inspect
  end

  def print_short(feature)
    if enabled_features[feature].present?
      puts black("#{feature.to_s.humanize}:")
      print_hash(enabled_features[feature])
    end
  end

  def yellow(str)
    # yellow ANSI color
    "\e[0;33;49m#{str}\e[0m"
  end

  def cyan(str)
    # cyan ANSI color
    "\e[0;36;49m#{str}\e[0m"
  end

  def red(str)
    # red ANSI color
    "\e[0;31;49m#{str}\e[0m"
  end

  def black(comment)
    # bright black bold ANSI color
    "\e[0;90;1;49m#{comment}\e[0m"
  end

end


