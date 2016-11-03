require 'rubygems'
require 'nokogiri'
require 'open-uri'
#require "restclient"

load 'dbSetup.rb'

MAIN_PAGE = "http://autobuild.buildroot.net/"
BASE_URL = "http://autobuild.buildroot.net/"


#DATA_TO_FIELDS = {
#  "Date": lambda do |db, node| 
#		    date = Date.new.(node.text);
#		    db.date = Date.new(node.text);
#		    if (BuildrootTest.get(:date => date))
#		      return false;
#		    else
#		      return true;
#  end
#  "Status":	    lambda { |db, node| db.status = node.text },
#  "Commit ID":	    lambda { |db, node| db.commit_id = node.text },
#  "Submitter":	    lambda { |db, node| db.submitter = node.text },
#  "Arch":	    lambda { |db, node| db.arch = node.text },
#  "Failure reason": lambda { |db, node| db.failure_reason = node.text },
#}
HEADER_TO_FIELD_NAME = {
  "Date" =>	      { field: "date"		, code: lambda { |node| node.text =~ /([^-]+)-([^-]+)-([^ ]+) ([^:]+):([^:]+):(.+)/; Time.new($1, $2, $3, $4, $5, $6) } },
  "Status" =>	      { field: "status"		, code: lambda { |node| node.text } },
  "Commit ID" =>      { field: "commit_id"	, code: lambda { |node| node.text } },
  "Submitter" =>      { field: "submitter"	, code: lambda { |node| node.text } },
  "Arch/Subarch" =>   { field: "arch"		, code: lambda { |node| node.text } },
  "Failure reason" => { field: "failure_reason"	, code: lambda { |node| node.text } },
  "Data" =>	      { field: nil		, 
			code: lambda do |db, node|
				files = node.css('a')
				files.map do |a|
				  data_file = DataFile.new()
				  data_file.filename = a.text
				  data_file.content_url = "#{BASE_URL}#{a['href']}"
				  data_file.local_copy_path = nil
				  #puts "    #{data_file.filename} => #{data_file.content_url}"
				  data_file
				end
			      end 
		      }   
}


def scrape_for_package_info(buildroot_test)
  text = open(buildroot_test.defconfig_url())
  text.each_line do |l|
    if(l =~ /^BR2_PACKAGE_([^=]+)=y/)
      name = $1
      package = BuildrootPackage.all(name: name).first 
      if(!package)
	package = BuildrootPackage.new
	package.name = name
	package.latest_test = nil
      end

      test_package = TestPackage.new()
      test_package.buildroot_test = buildroot_test
      test_package.buildroot_package = package
      test_package.date = buildroot_test.date

      if(buildroot_test.failed?)
	if(package.might_name_be_for_this_package?(buildroot_test.failure_reason))
	  test_package.failed = true
	else
	  test_package.unknown_result = true
	end
      else
	test_package.passed = true
      end

      package.save!
      test_package.save!

      # Don't set as latest_test if it got unknown result
      if(test_package.unknown_result == false && (package.latest_test == nil || test_package.date > package.latest_test.date))
	package.latest_test = test_package
	package.save!
      end
    end
  end
end

def scrape_test_information(page)
  added_entries = []
  puts "Parsing page #{page}"

  page = Nokogiri::HTML(open(page))
  
  header_name_to_index = {}
  header_name = []
  page.css('tr')[0..-2].each_with_index do |tr, i|
    if (i == 0)
      tr.css('td').each_with_index do |td, j|
        header_name_to_index[td.text] = j
        header_name[j] = td.text
      end
    else
      print "Row #{i}"
      to_save = []
      br_test = BuildrootTest.new()
      tr.css('td').each_with_index do |td, j|
        row_name = header_name[j]
        field_data = HEADER_TO_FIELD_NAME[row_name]
        if(field_data)
  	#puts HEADER_TO_FIELD_NAME
        	#puts "--#{row_name}--" if !field_data
        	#puts "--#{field_data}--"
        	#puts Time.new(td.text)
  	if(field_data[:field] != nil)
  	  br_test[field_data[:field]] = field_data[:code].call(td)
  	else
  	  #puts td
  	  to_save += field_data[:code].call(br_test, td)
  	  #puts to_save
  	end
        end
        #puts "  #{header_name[j]} => #{td.text}" 
      end
  
      #a = BuildrootTest.all(date: br_test.date)
      #puts a
      if(br_test.arch =~ /^arc/)
	print " (ARC)"
	begin
      	  br_test.save!
	  added_entries << br_test
	rescue(DataObjects::IntegrityError)
      	  puts "Row for date #{br_test.date} already exists!"
      	  return nil;
      	end

      	to_save.each do |elems|
      	  elems.buildroot_test = br_test
      	  elems.save!
      	end

	scrape_for_package_info (br_test)
      end
      puts ""
    end
  end
  return added_entries
end

def traverse_page()
  do_next = true
  start = 0;

  while(do_next)
    page = "#{MAIN_PAGE}?start=#{start}"
    ret = scrape_test_information(page)
    do_next = ret != nil
    start += 50
  end
end

def scrape_site() 
  traverse_page()
end
