module Mcmire
  module ArAttrLazy
    module HabtmExt
      def self.included(includer)
        includer.alias_method_chain :construct_find_options!, :attr_lazy
      end
    
      def construct_find_options_with_attr_lazy!(options)
        # Select unlazy_column_list by default
        options[:select] ||= @reflection.options[:select]
        options[:select] ||= @reflection.klass.unlazy_column_list if @reflection.klass.respond_to?(:unlazy_column_list)
        options[:select] ||= '*'
        construct_find_options_without_attr_lazy!(options)
      end
    end
  end
end
