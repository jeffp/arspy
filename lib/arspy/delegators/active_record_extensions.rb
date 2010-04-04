module Arspy
  module Delegators
    module ActiveRecordExtensions
      def pr(*args); Arspy::Operators.print_object(self, *args); end
      def la; Arspy::Operators.list_associations(self.class); end
      def lf; Arspy::Operators.list_fields(self.class); end
    end
  end
end