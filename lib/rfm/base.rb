require 'nokogiri'
require 'rfm/utilities/core_ext/class'

module Rfm  
  class Base

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
    
    class << self
      
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
      
    end
    
  end
end