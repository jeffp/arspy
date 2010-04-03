module Arspy
  module Delegators
    module ArrayExtensions
      def self.included(base)
        base.define_chained_method(:method_missing, :arspy) do |symbol, *args|
          result = Arspy::Operators.interpret(self, symbol, *args)
          result = method_missing_without_arspy(symbol, *args) unless result
          result
        end
        base.define_chained_method(:id, :arspy) do
          return id_without_arspy if (self.empty? || !self.first.is_a?(ActiveRecord::Base))
          self.map(&:id)
        end
      end

      def la
        Arspy::Operators.la(self.first.class) unless (self.emtpy? || !(self.first.is_a?(ActiveRecord::Base)))
      end
      def lf
        Arspy::Operators.lf(self.first.class) unless (self.empty? || !(self.first.is_a?(ActiveRecord::Base)))
      end
      def pr(*args)
        Arspy::Operators.print_array(self, *args)
      end
      def wi(*args)
        Arspy::Operators.with(self, *args)
      end
      def wo(*args)
        Arspy::Operators.without(self, *args)
      end
    end
  end
end