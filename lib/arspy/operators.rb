module Arspy
  module Operators

    def self.list_associations(klass_or_object)
      active_record_klass = klass_or_object.is_a?(Class) ? klass_or_object : klass_or_object.class
      return unless active_record_klass.ancestors.include?(ActiveRecord::Base)
      counts = {}
      rows = active_record_klass.reflect_on_all_associations.map do |assoc|
        counts[assoc.macro] ||= 0
        counts[assoc.macro] += 1
        self.format_column_association(assoc)
      end
      rows.sort!{|row1,row2| row1.first <=> row2.first}
      self.print_matrix(rows)
      "Total: #{counts.inject(0){|sum, count| sum+count.last}} (" + counts.map{|count| "#{count.last} #{count.first}" }.join(', ') + ")"
    end

    def self.list_fields(klass_or_object)
      active_record_klass = klass_or_object.is_a?(Class) ? klass_or_object : klass_or_object.class
      return unless active_record_klass.ancestors.include?(ActiveRecord::Base)
      rows = active_record_klass.columns.map do |column|
        self.format_column_field(column)
      end
      rows.sort!{|row1,row2| row1.first <=> row2.first}
      self.print_matrix(rows)
      "Total #{active_record_klass.columns.size} field#{active_record_klass.columns.size == 1 ? '' : 's'}"
    end

    def self.awesome_print(klass_object_or_array, options={})
      AwesomePrint.new(options).puts klass_object_or_array
      nil
    end

    def self.format_column_association(assoc)
      select_options = assoc.options.select{|k,v| [:through, :as, :polymorphic].include?(k)}
      [assoc.name.to_s, assoc.macro.to_s, "(#{assoc.options[:class_name] || assoc.name.to_s.singularize.camelize})", select_options.empty? ? '' : Hash[*select_options.flatten].inspect]
    end
    def self.format_column_field(field)
      [field.name.to_s, ":#{field.type}", "(#{field.sql_type})"]
    end

    def self.print_array(array, *args)
      if args.empty?
        case array.first
        when ActiveRecord::Base then AwesomePrint.new.puts(array)
        else
          array.each{|element| puts element}
        end
      end
      #array.each{|element| puts element.is_a?(String) ? element : element.inspect } if args.empty?
      self.print_matrix(
        array.map do |obj|
          args.map do |arg|
            case arg
            when Symbol then obj.__send__(arg)
            when String then obj.respond_to?(arg) ? obj.__send__(arg) : (obj.instance_eval(arg) rescue nil)
            else nil
            end
          end
        end
      ) unless args.empty?
      nil
    end

    def self.print_object(object, *args)
      print_matrix([args.map{|arg| object[arg]}]) unless args.empty?
      AwesomePrint.new.puts(object) if args.empty?
      nil
    end
    def self.test_object(obj, args)
      args.any? do |arg|
        case arg
        when String then obj.instance_eval(arg) rescue false
        when Integer then obj.id == arg
        when Hash
          arg.any?{|key,val| self.test_attribute(obj, key, (val.is_a?(Array) ? val : [val]) ) }
        else
          false
        end
      end
    end
    def self.with(array, *args)
      return array if (args.empty? || array.nil? || array.empty?)
      array.select{|obj| obj && self.test_object(obj, args)}
    end
    def self.without(array, *args)
      return array if (args.empty? || array.nil? || array.empty?)
      array.select{|obj| obj && !self.test_object(obj, args)}
    end
    def self.enable_abbreviations; @@abbreviations_enabled = true; end
    def self.disable_abbreviations; @@abbreviations_enabled = false; end
    @@abbreviations_enabled = true
    def self.interpret(array, method_name, *args)
      return nil unless (array && method_name)
      return nil unless (array.is_a?(Array) && !array.empty? && array.first.is_a?(ActiveRecord::Base))

      if array.first.class.reflect_on_all_associations.detect{|a| a.name == method_name}
        return interpret_association(array, method_name, *args)
      elsif (array.first.attribute_names.include?(method_name.to_s) || array.first.respond_to?(method_name))
        return interpret_attribute_or_method(array, method_name, *args)
      end
      return @@abbreviations_enabled ? interpret_abbreviation(array, method_name, *args) : nil
    end
    private
    def self.interpret_abbreviation(array, symbol, *args)
      if (descriptor = resolve_abbreviation_for_attributes_and_associations(array.first, symbol))
        if descriptor[:type] == :association
          return interpret_association(array, descriptor[:method_name], *args)
        else
          return interpret_attribute_or_method(array, descriptor[:method_name], *args)
        end
      end
      nil
    end
    def self.resolve_abbreviation_for_attributes_and_associations(object, method_name)
      klass = object.class
      setup_abbreviations(object) unless object.instance_variable_defined?('@arspy_abbreviations')
      if (ambiguity = klass.instance_variable_get('@arspy_ambiguous_abbreviations')[method_name])
        raise "Ambiguous abbreviation '#{ambiguity[:abbr]}' could be #{quote_and_join(ambiguity[:methods])}"
      end
      klass.instance_variable_get('@arspy_abbreviations')[method_name]
    end
    def self.setup_abbreviations(object)
      associations = object.class.reflect_on_all_associations.map(&:name).map(&:to_sym)
      attributes = object.attribute_names.map(&:to_sym)
      assoc_descriptors = associations.map{|method_name| {:method_name=>method_name, :type=>:association, :abbr=>abbreviate_method_name(method_name)}}
      attrib_descriptors = attributes.map{|method_name| {:method_name=>method_name, :type=>:attribute, :abbr=>abbreviate_method_name(method_name)}}
      all_descriptors = assoc_descriptors + attrib_descriptors
      object.class.instance_variable_set('@arspy_ambiguous_abbreviations', remove_ambiguities(all_descriptors))
      object.class.instance_variable_set('@arspy_abbreviations', Hash[*all_descriptors.map{|desc| [desc[:abbr], desc] }.flatten])
    end
    def self.remove_ambiguities(descriptors)
      list={}
      ambiguities = {}
      descriptors.each do |desc|
        if list.include?(desc[:abbr])
          if ambiguities[desc[:abbr]]
            ambiguities[desc[:abbr]][:methods] << desc[:method_name]
          else            
           ambiguities[desc[:abbr]] = {:abbr=>desc[:abbr], :methods=>[desc[:method_name]]}
           ambiguities[desc[:abbr]][:methods] << list[desc[:abbr]][:method_name]
          end
        else
          list[desc[:abbr]] = desc
        end
      end
      descriptors.reject!{|desc| ambiguities.map{|hash| hash.first}.include?(desc[:abbr])}
      ambiguities
    end
    def self.abbreviate_method_name(method_name)
      words = method_name.to_s.split('_')
      abbr=[]
      if words.first == ''
        abbr << '_'
      end
      words.reject!{|word| word == ''}
      abbr += words.map do |word|
        chars = word.split(//)
        first = chars.shift
        [first, chars.map{|ch| ch =~ /[0-9]/ ? ch : nil}].compact.flatten.join('')
      end
      
      abbr << '_' if (method_name.to_s =~ /_$/)
      abbr.join('').to_sym
    end
    def self.quote_and_join(array)
      return "'#{array.first}'" if array.size == 1
      last = array.pop
      "'#{array.join("', '")}' or '#{last}'"
    end
    def self.interpret_association(array, method_name, *args)
      array.map(&method_name).flatten
    end
    def self.interpret_attribute_or_method(array, method_name, *args)
      return array.map(&method_name) if args.empty?
      raise 'Hash not allowed as attribute conditionals' if args.any?{|arg| arg.is_a?(Hash)}
      array.select{|obj| obj && self.test_attribute(obj, method_name, args)}
    end
    public

    def self.test_attribute(obj, attr_sym, args)
      return false if (obj.nil? || attr_sym.nil? || args.empty?)
      value = obj.__send__(attr_sym)
      args.any? do |arg|
        case arg
        when String then (arg == value || (obj.instance_eval("#{attr_sym} #{arg}") rescue false))
        when Regexp then arg.match(value)
        when Range then arg.include?(value)
        when Integer then (value.is_a?(ActiveRecord::Base) ? arg == value.id : arg == value)  #TODO: what about value is association collection
        when Float then arg == value
        else
          false
        end
      end
    end

    @@column_padding = 2
    def self.print_matrix(matrix_array)
      return nil if matrix_array.empty?
      raise 'Cannot print a non-matrix array' unless matrix_array.all?{|ar| ar.is_a? Array }

      columns_per_row = matrix_array.map{|ar| ar.size }.max
      init_array = Array.new(columns_per_row, 0)
      max_widths = matrix_array.inject(init_array)do |mw, row|
        row.each_with_index do |string, index|
          mw[index] = [string.to_s.length, mw[index]].max
        end
        mw
      end
      matrix_array.each do |row|
        index = -1
        puts (row.map{|column| column.to_s + ' '*(max_widths[index += 1] - column.to_s.length) }.join(' '*@@column_padding))
      end
      nil
    end
  end
end
