class BuildrootPackage
  include DataMapper::Resource
  include Comparable

  property :id,         Serial    # An auto-increment integer key
  property :name,	String, :unique => true

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
    tests = test_packages.all(unknown_result: false, :date.gte => Time.now-(period*24*60*60), :date.lte => Time.now, order: [:date.desc])
      
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

  def changed_in_period(start_time, end_time)
    #puts self
    ret = {
      package: self,
      changed: false,
      nodes: [],
    }
    
    last_node = false
    tests = test_packages.all(unknown_result: false, order: [:date.desc])
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
	puts "HERE => #{ret[:package].name}"
	ret[:changed] = true;
      end
    end

    return ret
  end

  def related_tests
    self.test_packages.map { |tp| tp.buildroot_test }
  end

end

