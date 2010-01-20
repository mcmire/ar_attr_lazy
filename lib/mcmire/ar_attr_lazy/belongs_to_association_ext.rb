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