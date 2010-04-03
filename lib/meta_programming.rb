require 'meta_programming/object'

module MetaProgramming
end

Object.send :include, MetaProgramming::Object

#class Object
#  def self.metaclass
#    class << self; self; end
#  end
#  def self.safe_alias_method_chain(method_name, ext)
#    class_eval do
#      method_name_with_ext = "#{method_name}_with_#{ext}".to_sym
#      if (method_defined?(method_name_with_ext) && !(metaclass.instance_variable_defined?("@#{method_name_with_ext}")))
#        if method_defined?(method_name.to_sym)
#          alias_method_chain(method_name.to_sym, ext.to_sym)
#        else
#          alias_method method_name.to_sym, method_name_with_ext
#          define_method("#{method_name}_without_#{ext}".to_sym) {|*args| }
#        end
#        metaclass.instance_variable_set("@#{method_name_with_ext}", true)
#      end
#    end
#  end
#
#  def self.define_chained_method(method_name, ext, &block)
#    define_method("#{method_name}_with_#{ext}".to_sym, block)
#    safe_alias_method_chain(method_name.to_sym, ext)
#  end
#end
