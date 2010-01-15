class Ab
  include MongoMapper::Document

  key :testname,      String, :index => true
  key :version,       String, :index => true
  key :display_count, Integer
  key :click_count,   Integer
  key :stub,          String, :index => true
  timestamps!

  def self.click!(stub)
    #self.update_all("click_count = click_count + 1", ["stub = ?", stub])
    # Should use $inc, will get back to this
    self.find_all_by_stub(stub).each {|ab| ab.update_attributes :click_count => ab.click_count + 1 }
  end

  def self.displayed!(stub)
    #self.update_all("display_count = display_count + 1", ["stub = ?", stub])
    self.find_all_by_stub(stub).each {|ab| ab.update_attributes :display_count => ab.display_count + 1 }
  end

  def self.display!(testname, version)
    ab = self.find_test(testname, version)
    self.displayed!(ab.stub)
    ab
  end

  def self.for_testname(testname, version_count, mod_by)
    version_wanted = mod_by % version_count
    ab = self.display!(testname, version_wanted)
    ab
  end

  def before_create
    self.stub = random_string(10) if !self.stub?
  end

  def self.find_test(testname, version)
    key = "ab:#{testname}_v:#{version}"
    # future memcache tutorial
    # fb_user = memcache_me(key) {
      ab = self.find(:first,
                     :conditions => { :test_name => testname, :version => version })
      ab ||= self.create(:testname => testname, :version => version)
      ab
    # }
  end

  # future tutorials

  #   def self.for_click_count(testname, increment_display = true)
  #     ab = self.find_test(testname, 0)
  #     self.displayed!(ab.stub) if increment_display
  #     ab
  #   end

  #   def self.stub_for_test_or_create(testname, version)
  #     key = "ab_stub:#{testname}_v:#{version}"
  #     # fb_user = memcache_me(key) {
  #       ab = self.find(:first,
  #                      :select => "stub",
  #                      :conditions => ["testname = ? and version = ?",
  #                                       testname,
  #                                       version])
  #       ab ||= self.create(:testname => testname, :version => version)
  #       ab.stub
  #     # }
  #   end

  # future memcache tutorial
  #   def after_save
  #     # Cache.delete("ab:#{self.testname}_v:#{self.version}")
  #     # Cache.delete("ab_stub:#{self.testname}_v:#{self.version}")
  #   end

  def percent_clicked
    (self.click_count.to_f*10000000 / self.display_count).floor/100000
  end

protected

  def random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

end
