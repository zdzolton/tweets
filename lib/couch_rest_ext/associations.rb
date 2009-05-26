module CouchRestExt
  module Associations
    module ClassMethods
    
      def has_many *args
        options = extract_options!(args)
        children = args.first
        parent_name = ::Extlib::Inflection.underscore(self.name)
        define_method_for_children(parent_name, children, options, options[:class_name])
      end
    
      def belongs_to *args
        options = extract_options!(args)
        parent = args.first
        get_method = (options[:get_method] || 'get').to_sym
        parent_name = ::Extlib::Inflection.underscore((options[:class_name] || parent).to_s)
        class_name = ::Extlib::Inflection.camelize(parent_name)
        define_method parent do
          klass = ::Extlib::Inflection.constantize(class_name)
          parent_id = self["#{parent_name}_id"]
          if parent_id
            klass.send(get_method, self["#{parent_name}_id"])
          end
        end

        define_method "#{parent}=".to_sym do |parent_obj|
          self["#{parent_name}_id"] = parent_obj.id
        end
      end
    
    private
    
      def extract_options!(args)
        args.last.is_a?(Hash) ? args.pop : {}
      end
    
      def define_method_for_children(parent_name, children, options, name = nil)
        class_name = ::Extlib::Inflection.camelize(name || children.to_s.singular)
        define_method children do
          klass = ::Extlib::Inflection.constantize(class_name)
          if options[:view]
            view_name = options[:view]
          end
          if options[:query].is_a?(Proc)
             query = self.instance_eval(&options[:query])
          end
          view_name ||= "by_#{parent_name}_id"
          query ||= {:key => self.id}
          klass.send(view_name, query)
        end
      end
    end
  
    def self.included(receiver)
      receiver.extend ClassMethods
    end
  
  end
end