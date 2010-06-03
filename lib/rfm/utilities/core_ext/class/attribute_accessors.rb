require 'rfm/utilities/core_ext/array/extract_options'
# Extends the class object with class and instance accessors for class attributes,
# just like the native attr* accessors for instance attributes.
#
#  class Person
#    kattr_accessor :hair_colors
#  end
#
#  Person.hair_colors [:brown, :black, :blonde, :red] or Person.hair_colors = [:brown, :black, :blonde, :red]
class Class
  def kattr_reader(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}(obj=nil)
          return @@#{sym} if obj.nil?
          @@#{sym} = obj
        end
      EOS

      unless options[:instance_reader] == false
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{sym}
            @@#{sym}
          end
        EOS
      end
    end
  end

  def kattr_writer(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}=(obj)
          @@#{sym} = obj
        end
      EOS

      unless options[:instance_writer] == false
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{sym}=(obj)
            @@#{sym} = obj
          end
        EOS
      end
      self.send("#{sym}=", yield) if block_given?
    end
  end

  def kattr_accessor(*syms, &blk)
    kattr_reader(*syms)
    kattr_writer(*syms, &blk)
  end
end