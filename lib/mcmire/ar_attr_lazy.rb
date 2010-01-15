module Mcmire
  module AttrLazy
    module JoinBaseExt
      # Override to use unlazy_column_names instead of just column_names
      def column_names_with_alias
        unless defined?(@column_names_with_alias)
          @column_names_with_alias = []
          ([active_record.primary_key] + (active_record.unlazy_column_names - [active_record.primary_key])).each_with_index do |column_name, i|
            @column_names_with_alias << [column_name, "#{ aliased_prefix }_r#{ i }"]
          end
        end
        @column_names_with_alias
      end
    end
    
    module ClassMethods
      def attr_lazy_columns
        @attr_lazy_columns ||= []
      end

      def attr_lazy(*args)
        args = [args].flatten.map(&:to_s)
        new_cols = args - (attr_lazy_columns & args)
        @attr_lazy_columns |= args
        new_cols.each do |col|
          class_eval("def #{col}; read_lazy_attribute :#{col}; end", __FILE__, __LINE__)
        end
      end

      def unlazy_column_names
        column_names - attr_lazy_columns
      end

      def read_lazy_attribute(record, attr)
        # we use with_exclusive_scope here to override any :includes that may have happened in a parent scope
        with_exclusive_scope(:find => { :select => [primary_key, attr].join(",") }) do
          find(record[primary_key])[attr]
        end
      end

    private
      def find(*args)
        with_scope(:find => { :select => unlazy_column_list }) do
          super
        end
      end

      def unlazy_column_list
        unlazy_column_names.map {|c| "#{quoted_table_name}.#{connection.quote_column_name(c)}" }.join(",")
      end
    end
    
    def self.included(klass)
      klass.extend(ClassMethods)
      ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase.class_eval { include JoinBaseExt }
    end

  private
    def read_lazy_attribute(attr)
      attr = attr.to_s
      unless attributes.include?(attr)
        attributes[attr] = self.class.read_lazy_attribute(self, attr)
      end
      attributes[attr]
    end
  end
end