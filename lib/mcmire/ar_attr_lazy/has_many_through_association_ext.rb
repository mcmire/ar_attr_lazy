ActiveRecord::Associations::HasManyThroughAssociation.class_eval do
  # Unfortunately we can't override this using a module...
  def construct_select(custom_select = nil)
    distinct = "DISTINCT " if @reflection.options[:uniq]
    default_select = @reflection.klass.unlazy_column_list if @reflection.klass.respond_to?(:unlazy_column_list)
    default_select ||= "#{@reflection.quoted_table_name}.*"
    selected = custom_select || @reflection.options[:select] || "#{distinct}#{default_select}"
  end
end