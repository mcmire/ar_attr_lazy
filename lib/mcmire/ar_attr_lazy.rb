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
  #remove_method :find_target
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

ActiveRecord::AssociationPreload::ClassMethods.class_eval do
  include Mcmire::ArAttrLazy::AssociationPreloadExt
end