require 'mcmire/ar_attr_lazy/base_ext'
require 'mcmire/ar_attr_lazy/association_preload_ext'
require 'mcmire/ar_attr_lazy/habtm_ext'

ActiveRecord::Base.class_eval do
  extend Mcmire::ArAttrLazy::BaseExt::MacroMethods
end

ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase.class_eval do
  # Unfortunately we can't override this using a module...
  def column_names_with_alias
    unless defined?(@column_names_with_alias)
      @column_names_with_alias = []
      # Use unlazy_column_names instead of just column_names
      column_names = active_record.respond_to?(:unlazy_column_names) ? active_record.unlazy_column_names : active_record.column_names
      ([active_record.primary_key] + (column_names - [active_record.primary_key])).each_with_index do |column_name, i|
        @column_names_with_alias << [column_name, "#{ aliased_prefix }_r#{ i }"]
      end
    end
    @column_names_with_alias
  end
end

ActiveRecord::Associations::BelongsToAssociation.class_eval do
  # Unfortunately we can't override this using a module...
  def find_target
    find_method = if @reflection.options[:primary_key]
                    "find_by_#{@reflection.options[:primary_key]}"
                  else
                    "find"
                  end
    # Select unlazy_column_list by default
    select = @reflection.klass.unlazy_column_list if @reflection.klass.respond_to?(:unlazy_column_list)
    @reflection.klass.send(find_method,
      @owner[@reflection.primary_key_name],
      :select     => select || @reflection.options[:select],
      :conditions => conditions,
      :include    => @reflection.options[:include],
      :readonly   => @reflection.options[:readonly]
    ) if @owner[@reflection.primary_key_name]
  end
end

ActiveRecord::Associations::HasAndBelongsToManyAssociation.class_eval do
  include Mcmire::ArAttrLazy::HabtmExt
end

ActiveRecord::Associations::HasManyThroughAssociation.class_eval do
  # Unfortunately we can't override this using a module...
  def construct_select(custom_select = nil)
    distinct = "DISTINCT " if @reflection.options[:uniq]
    default_select = @reflection.klass.unlazy_column_list if @reflection.klass.respond_to?(:unlazy_column_list)
    default_select ||= "#{@reflection.quoted_table_name}.*"
    selected = custom_select || @reflection.options[:select] || "#{distinct}#{default_select}"
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

#pp "ActiveRecord::Base.included_modules" => ActiveRecord::Base.included_modules,
#  "ActiveRecord::Base.metaclass.included_modules" => ActiveRecord::Base.metaclass.included_modules,
#  "ActiveRecord::AssociationPreload::ClassMethods.included_modules" => ActiveRecord::AssociationPreload::ClassMethods.included_modules