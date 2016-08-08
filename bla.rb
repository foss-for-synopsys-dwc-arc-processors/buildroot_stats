require 'rubygems'
load 'dbSetup.rb'

def do_it
  TestPackage.all.each do |tp|
      puts "Doing #{tp.id}"

      tp.date = tp.buildroot_test.date
      tp.save!
    
    
  end
end

do_it()
