module Arspy
  module Delegators
    module ActiveRecordExtensions
      def pr(*args); Arspy::Operators.print_object(self, *args); end
      def la; Arspy::Operators.la(self.class); end
      def lf; Arspy::Operators.lf(self.class); end
    end
  end
end