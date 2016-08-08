class TestPackage
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :passed,	Boolean, :default => false
  property :failed,	Boolean, :default => false
  property :unknown_result, Boolean, :default => false
  property :date,	DateTime

  belongs_to :buildroot_test
  belongs_to :buildroot_package

  def html_date
    date.strftime("%Y-%m-%d %H:%M")
  end

end
