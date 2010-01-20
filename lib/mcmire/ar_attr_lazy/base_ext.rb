module Mcmire
  module ArAttrLazy
    module BaseExt
      module ClassMethods
        def unlazy_column_names
          column_names - attr_lazy_columns
        end
      
        def unlazy_column_list
          unlazy_column_names.map {|c| "#{quoted_table_name}.#{connection.quote_column_name(c)}" }.join(",")
        end

        def find_with_attr_lazy(*args)
          # don't limit :select clause if there aren't any lazy attributes defined on this model
          # or we're inside a scope right now that has already defined :select
          if attr_lazy_columns.empty? or (scope = scope(:find) and scope[:select])
            find_without_attr_lazy(*args)
          else
            with_scope(:find => { :select => unlazy_column_list }) do
              find_without_attr_lazy(*args)
            end
          end
        end
        
        def read_lazy_attribute(record, attr)
          # we use with_exclusive_scope here to override any :includes that may have happened in a parent scope
          select = [primary_key, attr].map {|c| "#{quoted_table_name}.#{connection.quote_column_name(c)}" }.join(",")
          with_exclusive_scope(:find => { :select => select }) do
            find_without_attr_lazy(record[primary_key])[attr]
          end
        end
      end
      
      module InstanceMethods
      private
        def read_lazy_attribute(attr)
          attr = attr.to_s
          unless @attributes.include?(attr)
            @attributes[attr] = self.class.read_lazy_attribute(self, attr)
          end
          @attributes[attr]
        end
      end
    
      module MacroMethods
        def attr_lazy(*args)
          include InstanceMethods
          extend ClassMethods
          class_inheritable_accessor :attr_lazy_columns
          write_inheritable_attribute :attr_lazy_columns, []
          (class << self; self; end).class_eval do
            alias_method_chain :find, :attr_lazy
          end
          
          args = [args].flatten.map(&:to_s)
          new_cols = args - (attr_lazy_columns & args)
          write_inheritable_attribute(:attr_lazy_columns, attr_lazy_columns | args)
          new_cols.each do |col|
            class_eval("def #{col}; read_lazy_attribute :#{col}; end", __FILE__, __LINE__)
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend Mcmire::ArAttrLazy::BaseExt::MacroMethods
end