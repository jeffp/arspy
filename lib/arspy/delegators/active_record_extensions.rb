module Arspy
  module Delegators
    module ActiveRecordExtensions
      def la; Arspy::Operators.list_associations(self.class); end
      def lf; Arspy::Operators.list_fields(self.class); end
      def pr(*args); Arspy::Operators.print_object(self, *args); end
      def ap(opts={}); Arspy::Operators.awesome_print(self, opts); end
    end
  end
end