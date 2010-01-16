module Mcmire
  module ArAttrLazy
    module AssociationPreloadExt
      def self.included(includer)
        includer.alias_method_chain :find_associated_records, :attr_lazy
      end
      
      #def preload_one_association(records, association, preload_options={})
      #  class_to_reflection = {}
      #  records.group_by {|record| class_to_reflection[record.class] ||= record.class.reflections[association]}.each do |reflection, records|
      #    raise ConfigurationError, "Association named '#{ association }' was not found; perhaps you misspelled it?" unless reflection
      #    # Add the unlazy columns as the default :select option (overrideable with an explicit select)
      #    if record = records[0] and record.class.respond_to?(:unlazy_column_list)
      #      preload_options[:select] = record.class.unlazy_column_list
      #    end
      #    send("preload_#{reflection.macro}_association", records, reflection, preload_options)
      #  end
      #end
      
      def find_associated_records_with_attr_lazy(ids, reflection, preload_options)
        # Add the unlazy columns as the default :select option (overrideable with an explicit select)
        preload_options[:select] = reflection.klass.unlazy_column_list if reflection.klass.respond_to?(:unlazy_column_list)
        find_associated_records_without_attr_lazy(ids, reflection, preload_options)
      end
    end
  end
end