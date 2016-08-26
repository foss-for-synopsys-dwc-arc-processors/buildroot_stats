class BuildrootPackage
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :name,	String, :unique => true

  #has 1, :latest_test, 'TestPackage'
  belongs_to :latest_test, 'TestPackage', :required => false
  has n, :test_packages

  def might_name_be_for_this_package?(name_p)
    parts = name_p.split("-")
    parts = parts.select { |a| (a =~ /^[^0-9]/) }
    name_p = parts.join('_')
    name_p.upcase!

    #puts "#{name_p} == #{name} => #{name == name_p}"

    name == name_p
  end

  def last_executions(number)
    test_packages.all(unknown_result: false, limit: number, order: [:date.desc])

    #  builroot_test: [
    #  
    #  test_packages: [
    #    {
    #      buildroot_package: self
    #}
    #tests = test_packages(.builroot_test(:order => [:date.asc])[0..number]

    #test_packages = tests.map do |test| 
    #  test_packages(buildroot_package: self)
    #end

    #return test_packages
  end

  def last_period_executions(period)
    tests = test_packages.all(unknown_result: false, :date.gte => Time.now-(period*24*60*60), :date.lte => Time.now, order: [:date.desc]).to_a
    last_before = test_packages.all(unknown_result: false, :date.lt => Time.now-(period*24*60*60), order: [:date.desc], :limit => 1)
    tests.push(last_before.first) if last_before.count > 0
      
    last_time = Time.now
    now = Time.now
    tests = tests.map do |t|
      percentage_start = 1.0 - (((now - t.date.to_time) / (24*60*60)) / period)
      percentage_end = 1.0 - (((now - last_time) / (24*60*60)) / period)
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

  def latest_result
    test_packages.first(unknown_result: false, order: [:date.desc])
  end

  def self.packages_that_changed_result_in_period(start_time, end_time)
    ret = {}
    tests = TestPackage.all(unknown_result: false, :date.gte => start_time, :date.lte => end_time, order: [:date.desc])
    count = tests.count
    before_period = TestPackage.all(unknown_result: false, :date.lte => start_time, :limit => 1, order: [:date.desc])
    last_before_start = repository(:default).adapter.select(
      "SELECT MAX(date), tp1.id, name FROM test_packages AS tp1 \
	LEFT JOIN buildroot_packages AS b ON b.id = tp1.buildroot_package_id \
	WHERE unknown_result = 'f' AND date < '#{start_time.iso8601}' GROUP BY buildroot_package_id ORDER BY date DESC")


last_before_start.each do |a|
    puts a 
end
    tests.each do |tp|
      data = ret[tp.buildroot_package] || { nodes: [], changed: false, last_before: nil }
	
      last = last_before_start.select{|a| a.name == tp.buildroot_package.name }
      data[:last_before] = last.first.id if(last.count == 1)

      data[:nodes].push(tp)
      if(data[:changed] == false && data[:nodes].count >= 2)
        # If has different result
	puts "HERE #{tp.buildroot_package.name} #{data[:nodes][-2].passed} #{data[:nodes][-1].passed}"
        data[:changed] = true if(data[:nodes][-2].passed != data[:nodes][-1].passed)
      end
      ret[tp.buildroot_package] = data
    end
 
    # Change last_before to a dbmodel reference
    ret.map do |k, v|
      if(v[:last_before] != nil)
        v[:nodes].push(TestPackage.get(v[:last_before]))
        v[:changed] = true if(v[:nodes][-2].passed != v[:nodes][-1].passed)
      end
    end

    #ret.each do |k, v|
    #    puts "#{k}: changed: #{v[:changed]}"
    #    puts "  before: #{v[:last_before].date} #{v[:last_before].passed}"
    #    v[:nodes].each { |tp| puts "   #{tp.date}" }
    #end

    ret.select! { |k, a| a[:changed] == true }
    return ret
  end
  
  def changed_in_period(start_time, end_time)
    #puts self
    ret = {
      package: self,
      changed: false,
      nodes: [],
    }
    
    last_node = false
    tests = test_packages.all(unknown_result: false, :date.gte => start_time, :date.lte => end_time, order: [:date.desc])
    count = tests.count
    tests = test_packages.all(unknown_result: false, :date.lte => end_time, :limit => count+1, order: [:date.desc])
    tests.each do |test|
      if(test.date.to_time >= start_time && test.date.to_time <= end_time)
	if(test.unknown_result == false)
	  ret[:nodes] << test
	end
      else
	if(last_node == false && test.unknown_result == false)
	  ret[:nodes] << test
	  last_node = true
	end
      end
    end

    ret[:nodes].each_with_index do |n,i|
      if(i > 0 && ret[:nodes][i-1].passed != n.passed)
	#puts "HERE => #{ret[:package].name}"
	ret[:changed] = true;
      end
    end

    return ret
  end

  def related_tests
    self.test_packages.map { |tp| tp.buildroot_test }
  end

end

