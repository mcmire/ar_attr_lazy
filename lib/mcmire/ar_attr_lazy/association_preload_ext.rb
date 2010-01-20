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

ActiveRecord::AssociationPreload::ClassMethods.class_eval do
  include Mcmire::ArAttrLazy::AssociationPreloadExt
  
  # Unfortunately we can't override this using a module...
  def preload_has_and_belongs_to_many_association(records, reflection, preload_options={})
    table_name = reflection.klass.quoted_table_name
    id_to_record_map, ids = construct_id_map(records)
    records.each {|record| record.send(reflection.name).loaded}
    options = reflection.options

    conditions = "t0.#{reflection.primary_key_name} #{in_or_equals_for_ids(ids)}"
    conditions << append_conditions(reflection, preload_options)

    associated_records = reflection.klass.with_exclusive_scope do
      # Select unlazy_column_list by default
      select = options[:select]
      select ||= reflection.klass.unlazy_column_list if reflection.klass.respond_to?(:unlazy_column_list)
      select ||= table_name+'.*'
      reflection.klass.find(:all, :conditions => [conditions, ids],
        :include => options[:include],
        :joins => "INNER JOIN #{connection.quote_table_name options[:join_table]} t0 ON #{reflection.klass.quoted_table_name}.#{reflection.klass.primary_key} = t0.#{reflection.association_foreign_key}",
        :select => "#{select}, t0.#{reflection.primary_key_name} as the_parent_record_id",
        :order => options[:order])
    end
    set_association_collection_records(id_to_record_map, reflection.name, associated_records, 'the_parent_record_id')
  end
end