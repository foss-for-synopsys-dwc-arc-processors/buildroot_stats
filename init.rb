require 'rubygems'

require_relative "dbSetup.rb"

project_root = File.dirname(File.absolute_path(__FILE__))
#Dir.glob(project_root + "/parsers/*.rb").each do |file| 
#  require file
#end

Dir.glob(project_root + "/model/*.rb").each do |file| 
  require file
end

# Generate bit replacements
#OperandType.all.each do |op_type|
#  op_type.replacement_masks.each do |mask|
#    BitReplacement.new(op_type, mask)
#  end
#end

