module Arspy
  module Operators
    def self.list_associations(active_record_klass)
      counts = {}
      rows = active_record_klass.reflect_on_all_associations.map do |a|
        counts[a.macro] ||= 0
        counts[a.macro] += 1
        self.format_column_association(a)
      end
      rows.sort!{|a,b| a.first <=> b.first}
      self.print_matrix(rows)
      "Total: #{counts.inject(0){|sum, c| sum+c.last}} (" + counts.map{|c| "#{c.last} #{c.first}" }.join(', ') + ")"
    end

    def self.list_fields(active_record_klass)
      rows = active_record_klass.columns.map do |c|
        self.format_column_field(c)
      end
      rows.sort!{|a,b| a.first <=> b.first}
      self.print_matrix(rows)
      "Total #{active_record_klass.columns.size} field#{active_record_klass.columns.size == 1 ? '' : 's'}"
    end

    def self.format_column_association(a)
      select_options = a.options.select{|k,v| [:through, :as, :polymorphic].include?(k)}
      [a.name.to_s, a.macro.to_s, "(#{a.options[:class_name] || a.name.to_s.singularize.camelize})", select_options.empty? ? '' : Hash[*select_options.flatten].inspect]
    end
    def self.format_column_field(f)
      [f.name.to_s, ":#{f.type}", "(#{f.sql_type})"]
    end

    def self.print_array(array, *args)
      array.each{|element| puts element.is_a?(String) ? element : element.inspect } if args.empty?
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
      print_matrix([args.map{|a| object[a]}]) if args
      puts(object.inspect) unless args
      nil
    end
    def self.test_object(obj, args)
      args.any? do |arg|
        case arg
        when String then obj.instance_eval(arg) rescue false
        when Integer then obj.id == arg
        when Hash
          arg.any?{|k,v| self.test_attribute(obj, k, (v.is_a?(Array) ? v : [v]) ) }
        else
          false
        end
      end
    end
    def self.with(array, *args)
      return array if (args.empty? || array.nil? || array.empty?)
      array.select{|o| o && self.test_object(o, args)}
    end
    def self.without(array, *args)
      return array if (args.empty? || array.nil? || array.empty?)
      array.select{|o| o && !self.test_object(o, args)}
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
      object.class.instance_variable_set('@arspy_abbreviations', Hash[*all_descriptors.map{|d| [d[:abbr], d] }.flatten])
    end
    def self.remove_ambiguities(descriptors)
      list={}
      ambiguities = {}
      descriptors.each do |d|
        if list.include?(d[:abbr])
          if ambiguities[d[:abbr]]
            ambiguities[d[:abbr]][:methods] << d[:method_name]
          else            
           ambiguities[d[:abbr]] = {:abbr=>d[:abbr], :methods=>[d[:method_name]]}
           ambiguities[d[:abbr]][:methods] << list[d[:abbr]][:method_name]
          end
        else
          list[d[:abbr]] = d
        end
      end
      descriptors.reject!{|d| ambiguities.map{|h| h.first}.include?(d[:abbr])}
      ambiguities
    end
    def self.abbreviate_method_name(method_name)
      splits = method_name.to_s.split('_')
      abbr=[]
      if splits.first == ''
        abbr << '_'
      end
      splits.reject!{|s| s == ''}
      abbr += splits.map do |s| 
        chars = s.split(//)
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
      raise 'Hash not allowed as attribute conditionals' if args.any?{|a| a.is_a?(Hash)}
      array.select{|o| o && self.test_attribute(o, method_name, args)}
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
