require 'nokogiri'
Dir[File.dirname(__FILE__) + '/parsers/*.rb'].each {|file| require file }

module DoctorNinja
  class Parser
    class Noop < DoctorNinja::Parsers::Base
      def self.applicable_to?(node)
        return true
      end
    end

    def initialize(doc)
      @docx = doc
      @xmldoc = Nokogiri::XML @docx.read "word/document.xml"
      
      # This will remove "vanished" word runs.
      # Maybe this sould be treated separatly, but as
      # we use xslt for math transformation this is the only
      # way I can think to solve it. Preprocessing it...
      @xmldoc.xpath("//w:vanish/ancestor::m:r[1]").remove
      @xmldoc.xpath("//w:vanish/ancestor::w:r[1]").remove
    end

    def parse
      self.parse_node(@xmldoc.root, {})
    end

    def parse_node(node,context)
      parsers = parsers_for(node,context)

      if debug?(node,parsers)
        debug(node,binding)
      end

      parsers
        .first
        .parse
    end

    def parsers_for(node,context)
      parsers
        .select{|p| p.applicable_to? node}
        .map{|p| p.new(node, self.public_method(:parse_node), @docx, context)}
    end

    def parsers
      DoctorNinja::Parsers.constants.map{|c| DoctorNinja::Parsers.const_get(c)}+[Noop]
    end

    def debug?(node,parsers)
      ENV["DEBUG"] == "all" || 
      (ENV["DEBUG"] == "missing" && parsers.length == 1) || 
      ENV["DEBUG"] == node.name ||
      (node.namespace && ENV["DEBUG"] == "#{node.namespace.prefix}:#{node.name}")
    end

    def debug(node,b)
      if(ENV["DEBUG_MODE"]=="pry")
        require "pry"
        b.pry
      else
        puts "---BEGIN---\n#{node.to_xml}\n----END----"
      end
    end
  end
end
