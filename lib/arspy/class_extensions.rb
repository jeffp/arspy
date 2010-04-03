module Arspy
  module ClassExtensions
    module ActiveRecord
      module Base
        def la; Arspy::Operators.la(self); end
        def lf; Arspy::Operators.lf(self); end
      end
    end
  end
end
