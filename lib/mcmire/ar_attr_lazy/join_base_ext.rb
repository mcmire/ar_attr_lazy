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