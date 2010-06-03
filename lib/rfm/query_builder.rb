module Rfm
  class QueryBuilder
    attr_reader :query
    
    def initialize(layout)
      @layout = layout
      @query = {}
    end
    
    def search_options(options={})
      options.each do |key, value|
        @query[key.to_s] = value
      end
    end
    
    def parse_method(method)
      '-' << method.to_s
    end
    
    def sort_field(*fields)
      raise Rfm::ParameterError, ":sort_field can have a max of 9 fields, you passed in #{fields.size}." if fields.size > 9
      
      fields.each_with_index { |field, i| @query["-sortfield.#{i+1}"] = field }
      @layout
    end
    
    def sort_order(*orders)
      raise Rfm::ParameterError, ":sort_order can have a max of 9 options, you passed in #{orders.size}." if orders.size > 9
      
      orders.each_with_index { |order, i| @query["-sortorder.#{i+1}"] = parse_sort_order(order) }
      @layout
    end
    
    def parse_sort_order(order)
      case order
      when 'asc' then 'ascend'
      when 'desc' then 'descend'
      else order
      end
    end
    
    def max(value)
      @query['-max'] = value
      @layout
    end
    
    def skip(value)
      @query['-skip'] = value
      @layout
    end
    
  end
end