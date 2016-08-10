require 'rubygems'
require 'sinatra'
require 'haml'
require 'uri'
require 'sinatra_mailer'

load 'dbSetup.rb'

#set :public_folder, File.dirname(__FILE__) + '/public'
set :public_folder, 'public'

configure do 
Sinatra::Mailer.config = {
  :host   => 'mailhost',
  :port   => '25',
  :domain => "synopsys.com" # the HELO domain provided by the client to the server
}
end

helpers do 
  def datetime_to_s(date)
    date.strftime("%Y-%m-%d %H:%M")
  end

  def change_helper(data)
    "#{data[:nodes][-1].passed ? "PASS" : "FAIL"} => #{data[:nodes][0].passed ? "PASS" : "FAIL"}"
  end

  def prepare_for_display(tests, start_time, end_time)
    last_time = end_time
    period = (end_time - start_time)
    tests = tests.map do |t|
      percentage_start = 1.0 - (((end_time - t.date.to_time)) / period)
      percentage_end = 1.0 - (((end_time - last_time)) / period)
      percentage_start = percentage_start < 0 ? 0.0 : percentage_start
      percentage_end = percentage_end < 0 ? 0.0 : percentage_end

      percentage_width = percentage_end - percentage_start
      ret = { tp: t, start: percentage_start, width: percentage_width }
      last_time = t.date.to_time
      ret
    end
    tests = tests.select { |t| t[:width] > 0.0 }
    tests
  end
end

configure do
  enable :sessions
end

get '/' do
  @list = BuildrootTest.all(:limit => 100, :order => [ :date.desc ])
  haml :index
end

get "/test/:id" do
  @test = BuildrootTest.get(params['id'])
  haml :test
end

get "/packages/" do
  @packages = BuildrootPackage.all(:order => [ :name.asc ])
  haml :packages
end

get "/package/:id" do
  @package = BuildrootPackage.get(params[:id])
  haml :package
end

get "/report/" do
  puts "Here1"
  @start_time = params['start'] ? Time.at(params['start'].to_i) : Time.now - (7*24*60*60) 
  @end_time = params['end'] ? Time.at(params['end'].to_i) : Time.now
  puts "Here2"

  return "#{@end_time}" unless @start_time || @end_time

  puts "Here3"
  packages_list = BuildrootPackage.all()
  puts "Here4"
  @period_days = ((@end_time - @start_time) / (24*60*60)).to_i
  @tests = BuildrootTest.all(:date.gte => @start_time, :date.lte => @end_time, :order => [ :date.desc ])
  puts "Here5"

  # Prepare package changed
  #package_names = @tests.map { |a| a.related_packages }.flatten.map { |b| b.name }
  #package_changes = BuildrootPackage.all(:name => package_names, :order => [ :name.asc ])
  #package_changes = package_changes.map { |a| a.changed_in_period(@start_time, @end_time) }
  #package_changes = package_changes.select { |a| a[:changed] == true }
  #@package_changes = package_changes

  package_changes = BuildrootPackage.packages_that_changed_result_in_period(@start_time, @end_time)
  @package_changes = package_changes

  puts "Here6"
  
  packages = BuildrootPackage.all(:order => [:name.asc])
  #tps = TestPackage.all(:fields => [:buildroot_package_id, :passed, :failed, :date], :unique => true, :unknown_result => false, :order => [ :date.desc ])
  #package_status = {}
  #tps.each do |tp|
  #  if(package_status[tp.buildroot_package] == nil)
  #    package_status[tp.buildroot_package] = { passed: tp.passed, failed: tp.failed, never_tested: false, test_package: tp, package: tp.buildroot_package }
  #  end
  #end
  #packages_list.each do |p|
  #  if(package_status[p] == nil)
  #    ret = { passed: false, failed: false, never_tested: true, test_package: nil, package: p }
  #  end
  #end


  #package_status = packages_list.map do |p|
  #  test = tps.all(:buildroot_package => p).first
  #  #p.test_packages.first(:unknown_result => false, :limit => 1, :order => [ :date.desc ])

  #  ret = { passed: false, failed: false, never_tested: true, test_package: test, package: p }
  #  if(test != nil)
  #    ret = { passed: test.passed, failed: test.failed, never_tested: false, test_package: test, package: p }
  #  end
  #  ret
  #end
  puts "Here7"
  @failing_packages = packages.select { |p| p.latest_test && p.latest_test.failed == true }
  puts "Here8"

  successes = packages.select { |p| p.latest_test && p.latest_test.passed == true }.count
  failures = packages.select { |p| p.latest_test && p.latest_test.failed == true }.count
  never_built = packages.select { |p| p.latest_test == nil }.count

  @data = {
    num_packages: packages_list.count,
    successes: successes,
    failures: failures,
    never_tested: never_built, #package_status.select { |p| p[:never_tested] == true }.count,
    new_failures: package_changes.values.select { |data| data[:nodes][0].failed == true }.count,
    new_successes: package_changes.values.select { |data| data[:nodes][0].passed == true }.count,
  }

#  email(to: "cmiranda@synospsys.com",
#	from: "cmiranda@synopsys.com",
#	subject: "Buildroot testing report",
#	body: haml(:report))

  haml :report, :layout => :email_layout
end

get "/send_email/" do
  email(to: "cmiranda@synospsys.com",
	from: "cmiranda@synopsys.com",
	subject: "Buildroot testing report",
	body: "TEST Email!")

end






get "/update_db" do
  begin
    scrape_site()
  rescue
    return "FAIL"
  end
  return "OK"
end
