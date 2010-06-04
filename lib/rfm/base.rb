require 'nokogiri'
require 'rfm/utilities/core_ext/class'
require 'rfm/utilities/core_ext/module'
require 'rfm/result/record'

module Rfm  
  class Base < Record

    kattr_writer :host, :instance_writer => false
    @@host = 'localhost'
    
    kattr_accessor :port, :instance_writer => false
    @@port = 443
    
    kattr_accessor :account, :password, :instance_writer => false
    
    kattr_writer :ssl, :instance_writer => false
    @@ssl = true
    
    kattr_writer :pem, :instance_writer => false
    
    kattr_accessor :database, :instance_writer => false
    
    kattr_accessor :default_layout, :instance_writer => false
    
    kattr_accessor :log_actions
    
    kattr_accessor :log_responses
    
    kattr_accessor :warn_on_redirect
    @@warn_on_redirect = true
    
    kattr_accessor :raise_on_401
    kattr_accessor :include_portals
    
    class << self
      
      delegate :get_records, :to => :server
       
      def host(*host) 
        return @@host if host.empty?
        @@host = host[0]
        @@port = host[1] unless host.size <= 1
      end
    
      def auth(a, p)
        @@account = a
        @@password = p
      end
    
      def ssl(ssl=nil)
        return @@ssl if ssl.nil?
        @@ssl = ssl
        @@port = 80 if @@ssl == false && @@port == 443
      end

      def pem(file=nil)
        return @@pem if file.nil?
        raise Rfm::PemFileMissingError unless File.exists?(file)
        @@pem = file
      end
      
      def setup
        yield self if block_given?
      end
      
      def server
        @server ||= Rfm::Server.new(
          :host => @@host,
          :account_name => @@account,
          :password => @@password,
          :root_cert_name => @@pem,
          :port => @@port,
          :include_portals => @@include_portals,
          :log_actions => @@log_actions,
          :log_response => @@log_responses,
          :ssl => @@ssl,
          :root_cert => true,
          :warn_on_redirect => @@warn_on_redirect,
          :raise_on_401 => @@raise_on_401
        )
        @server.db = @@database
        @server.layout = @@default_layout
        @server
      end
      
    end
    
  end
  
  Base.class_eval do
    extend Layout
  end
end