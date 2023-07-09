module AnnotatedDefinitions
  def describe
    enabled_features
  end

  def enabled_features
    enum_sample = keys.first
    {
      enum_i: base_class.instance_methods.include?( "#{enum_sample}_i") && enum_sample,
      mass_assign: base_class.respond_to?("#{enum_sample}!") && enum_sample,
      multi_scopes: base_class.respond_to?("with_#{enum_name}") && enum_name,
      supersets: supersets,
      translations: try(:t_options),
      humanization: try(:t_options)
    }
  end

    # other.instance_eval do
    #   annotations_method = "#{other.to_s.downcase}_annotations"
    #   def define_annotated_singleton_method(method, annotation, &block)
    #     annotate_class_method( method, annotation )
    #     define_singleton_method(method, &block)
    #   end
    #
    #   def define_annotated_method(method, annotation, &block)
    #     annotate_instance_method( method, annotation )
    #     define_method(method, &block)
    #   end
    #
    #   define_singleton_method( annotations_method ) do
    #     @annotations ||= {}
    #   end
    #
    #   define_singleton_method "annotate_instance_method" do | method, annotation|
    #     (send(annotations_method)[:instance] ||= {})[method] = annotation
    #   end
    #
    #   define_singleton_method "annotate_class_method" do | method, annotation |
    #     (send(annotations_method)[:class] ||= {})[method] = annotation
    #   end
    #
    #   define_singleton_method "describe_patching" do
    #     annotations = send( annotations_method )
    #     defined?(ap) ? ap( annotations ) : pp( annotations )
    #   end
    # end
end


