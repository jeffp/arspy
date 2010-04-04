module Arspy
  module ClassExtensions
    module ActiveRecord
      module Base
        def la; Arspy::Operators.list_associations(self); end
        def lf; Arspy::Operators.list_fields(self); end
      end
    end
  end
end
