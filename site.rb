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
  @list = BuildrootTest.all(:order => [ :date.desc ])
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
  @start_time = params['start'] ? Time.new(params['start']) : Time.now - (7*24*60*60) 
  @end_time = params['end'] ? Time.new(params['end']) : Time.now

  return "#{@end_time}" unless @start_time || @end_time

  packages_list = BuildrootPackage.all()
  @period_days = ((@end_time - @start_time) / (24*60*60)).to_i
  @tests = BuildrootTest.all(:date.gte => @start_time, :date.lte => @end_time, :order => [ :date.desc ])

  # Prepare package changed
  package_names = @tests.map { |a| a.related_packages }.flatten.map { |b| b.name }
  package_changes = BuildrootPackage.all(:name => package_names, :order => [ :name.asc ])
  package_changes = package_changes.map { |a| a.changed_in_period(@start_time, @end_time) }
  package_changes = package_changes.select { |a| a[:changed] == true }
  @package_changes = package_changes

  package_status = packages_list.map do |p|
    test = p.test_packages.first(:unknown_result => false, :limit => 1, :order => [ :date.desc ])

    ret = { passed: false, failed: false, never_tested: true, test_package: test, package: p }
    if(test != nil)
      ret = { passed: test.passed, failed: test.failed, never_tested: false, test_package: test, package: p }
    end
    ret
  end
  @failing_packages = package_status.select { |p| p[:failed] == true}.map { |p| p[:package] }

  @data = {
    num_packages: packages_list.count,
    successes: package_status.select { |p| p[:passed] == true }.count,
    failures: package_status.select { |p| p[:failed] == true }.count,
    never_tested: package_status.select { |p| p[:never_tested] == true }.count,
    new_failures: package_changes.select { |data| data[:nodes][0].failed == true }.count,
    new_successes: package_changes.select { |data| data[:nodes][0].passed == true }.count,
  }

#  email(to: "cmiranda@synospsys.com",
#	from: "cmiranda@synopsys.com",
#	subject: "Buildroot testing report",
#	body: haml(:report))

  haml :report
end

get "/send_email/" do
  email(to: "cmiranda@synospsys.com",
	from: "cmiranda@synopsys.com",
	subject: "Buildroot testing report",
	body: "TEST Email!")

end






get "/update_db" do

end
