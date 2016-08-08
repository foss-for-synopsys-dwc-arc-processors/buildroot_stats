class DataFile
  include DataMapper::Resource
  include Comparable

  property :id,         Serial    # An auto-increment integer key
  property :filename,	String
  property :content_url, String
  property :local_copy_path, String

  belongs_to :buildroot_test

  def to_s
    "  #{filename} => #{content_url}"
  end
end

