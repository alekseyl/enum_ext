module AnnotatedDefinitions

  def self.extended(other)
    other.instance_eval do
      @enum_ext_short_definition = {
        enum_i: false,
        mass_assign: false,
        multi_scopes: false,
        sets: {},
        translations: {},
        humanization: {}
      }
      def set_scope_added( options )

      end
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
end

