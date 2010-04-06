module Arspy
  module ClassExtensions
    module ActiveRecord
      module Base
        def la; Arspy::Operators.list_associations(self); end
        def lf; Arspy::Operators.list_fields(self); end
        def pr; Arspy::Operators.awesome_print(self); end
        def ap(opts={}); Arspy::Operators.awesome_print(self, opts); end
      end
    end
  end
end
