module EnumExt
  class EnumExtConfig
    attr_accessor :default_helpers, :application_record_class

    def initialize
      self.default_helpers = [:multi_enum_scopes, :mass_assign_enum]
    end
  end

  class << self
    def configure
      yield(config)
      config.application_record_class&.extend( EnumExt ) if config.application_record_class.is_a?(Class)
    end

    def config
      @config ||= EnumExtConfig.new
    end
  end
end