# This module includes classes that represent FileMaker data. When you communicate with FileMaker
# using, ie, the Layout object, you typically get back ResultSet objects. These contain Records,
# which in turn contain Fields, Portals, and arrays of data.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details
require 'nokogiri'
require 'bigdecimal'
require 'rfm/resultset/field'
require 'rfm/resultset/record'

module Rfm

  # The ResultSet object represents a set of records in FileMaker. It is, in every way, a real Ruby
  # Array, so everything you expect to be able to do with an Array can be done with a ResultSet as well.
  # In this case, the elements in the array are Record objects.
  #
  # Here's a typical example, displaying the results of a Find:
  #
  #   myServer = Rfm::Server.new(...)
  #   results = myServer["Customers"]["Details"].find("First Name" => "Bill")
  #   results.each {|record|
  #     puts record["First Name"]
  #     puts record["Last Name"]
  #     puts record["Email Address"]
  #   }
  #
  # =Attributes
  #
  # The ResultSet object has several useful attributes:
  #
  # * *server* is the server object this ResultSet came from
  #
  # * *fields* is a hash with field names for keys and Field objects for values; it provides 
  #   metadata about the fields in the ResultSet
  #
  # * *portals* is a hash with table occurrence names for keys and arrays of Field objects for values;
  #   it provides metadata about the portals in the ResultSet and the Fields on those portals
  
  class Resultset < Array
    instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }
    
    attr_reader :include_portals, :field_meta, :portal_meta, :date_format, :time_format, :timestamp_format, :total_count, :foundset_count
    
    # Initializes a new ResultSet object. You will probably never do this your self (instead, use the Layout
    # object to get various ResultSet obejects).
    #
    # If you feel so inclined, though, pass a Server object, and some +fmpxmlresult+ compliant XML in a String.
    #
    # =Attributes
    #
    # The ResultSet object includes several useful attributes:
    #
    # * *fields* is a hash (with field names for keys and Field objects for values). It includes an entry for
    #   every field in the ResultSet. Note: You don't use Field objects to access _data_. If you're after 
    #   data, get a Record object (ResultSet is an array of records). Field objects tell you about the fields
    #   (their type, repetitions, and so forth) in case you find that information useful programmatically.
    #
    #   Note: keys in the +fields+ hash are downcased for convenience (and [] automatically downcases on 
    #   lookup, so it should be seamless). But if you +each+ a field hash and need to know a field's real
    #   name, with correct case, do +myField.name+ instead of relying on the key in the hash.
    #
    # * *portals* is a hash (with table occurrence names for keys and Field objects for values). If your
    #   layout contains portals, you can find out what fields they contain here. Again, if it's the data you're
    #   after, you want to look at the Record object.
    def initialize(server, xml_response, layout = nil)
      
      @field_meta = Rfm::Utility::CaseInsensitiveHash.new
      @portal_meta = Rfm::Utility::CaseInsensitiveHash.new
      @date_format = nil
      @time_format = nil
      @timestamp_format = nil
      @total_count = nil
      @foundset_count = nil
      @include_portals = server.state[:include_portals]
      
      doc = xml_response.gsub('xmlns="http://www.filemaker.com/xml/fmresultset" version="1.0"', '')
      doc = Nokogiri.XML(doc)
      
      #seperate content for less searching
      datasource  = doc.xpath('/fmresultset/datasource')
      
      # check for errors
      error = doc.xpath('/fmresultset/error').attribute('code').value.to_i
      if error != 0 && (error != 401 || server.state[:raise_on_401])
        raise Rfm::Error.getError(error) 
      end
      
      # ascertain date and time formats
      @date_format      = convert_format_string(datasource.attribute('date-format').value)
      @time_format      = convert_format_string(datasource.attribute('time-format').value)
      @timestamp_format = convert_format_string(datasource.attribute('timestamp-format').value)
      
      # retrieve count
      @foundset_count = doc.xpath('/fmresultset/resultset').attribute('count').value.to_i
      @total_count    = datasource.attribute('total-count').value.to_i
      
      # process field metadata
      metadata = doc.xpath('/fmresultset/metadata/field-definition')
      metadata.each do |field|
        @field_meta[field['name']] = Field.new(field)
      end
        
      if @include_portals
        related_metadata = doc.xpath('/fmresultset/metadata/relatedset-definition')
        # process relatedset metadata
        related_metadata.each do |relatedset|
          table, fields = relatedset.attribute('table').value, {}
          
          relatedset.xpath('field-definition').each do |field|
            name = field.attribute('name').value.gsub(Regexp.new(table + '::'), '')
            fields[name] = Field.new(field)
          end
          
          @portal_meta[table] = fields
        end
      end
      
      records = doc.xpath('/fmresultset/resultset/record')
      records.each do |record|
        self << Record.new(record, self, @field_meta)
      end
    end
    
    protected
      
      def method_missing(name, *args, &block)
        target.send(name, *args, &block)
      end
      
      def target
        @target ||= []
      end
    
    private
    
      def convert_format_string(fm_format)
        fm_format.gsub!('MM', '%m')
        fm_format.gsub!('dd', '%d')
        fm_format.gsub!('yyyy', '%Y')
        fm_format.gsub!('HH', '%H')
        fm_format.gsub!('mm', '%M')
        fm_format.gsub!('ss', '%S')
        fm_format
      end
    
  end
end