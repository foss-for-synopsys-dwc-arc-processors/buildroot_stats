class BuildrootTest
  include DataMapper::Resource
  include Comparable

  property :id,         Serial    # An auto-increment integer key
  property :date,	DateTime, :unique => true
  property :status,	String
  property :commit_id,	String
  property :submitter,	String
  property :arch,	String
  property :failure_reason,  String, :default => ""

  has n, :data_files
  has n, :test_packages

  def defconfig_url
    return data_files(:filename => "config").first.content_url
  end

  def failed?
    status == "NOK"
  end
  def passed?
    !failed
  end

  def related_packages
    self.test_packages.map { |tp| tp.buildroot_package }
  end
  def html_date
    date.strftime("%Y-%m-%d %H:%M")
  end
end
