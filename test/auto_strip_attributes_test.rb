require "test/test_helper"
# bundle exec ruby test/auto_strip_attributes_test.rb -v --name /test_name/

#class AutoStripAttributesTest < Test::Unit::TestCase
#class AutoStripAttributesTest < MiniTest::Unit::TestCase
describe AutoStripAttributes do

  def setup
    @init_params = { :foo => "\tfoo  ", :bar => " bar  bar "}
  end

  it "should have defined AutoStripAttributes" do
    assert Object.const_defined?(:AutoStripAttributes)
  end

  describe "Basic attribute with default options" do
    class MockRecordBasic < ActiveRecord::Base
      column :foo, :string
      auto_strip_attributes :foo
    end
    before do
      @record = MockRecordBasic.new()
    end

    it "should be ok for normal strings" do
      @record.foo = " aaa \t"
      @record.valid?
      @record.foo.must_equal "aaa"
    end

    it "should set empty strings to nil" do
      @record.foo = " "
      @record.valid?
      @record.foo.must_be_nil
    end

    it "should call strip method to attribute if possible" do
      str_mock = MiniTest::Mock.new()
      str_mock.expect :'nil?', false
      str_mock.expect :strip, (@stripped_str="stripped_str_here")
      @record.foo = str_mock
      @record.valid?
      str_mock.verify
      @record.foo.must_be_same_as @stripped_str
    end

    it "should not call strip method for non strippable attributes" do
      str_mock = MiniTest::Mock.new() # answers false to str_mock.respond_to?(:strip)
      str_mock.expect :'nil?', false
      @record.foo = str_mock
      @record.valid?
      str_mock.verify
      assert @record.foo === str_mock
    end
  end

  describe "Attribute with nullify option" do
    class MockRecordWithNullify < ActiveRecord::Base
      column :foo, :string
      auto_strip_attributes :foo, :nullify => false
    end

    it "should not set blank strings to nil" do
      @record = MockRecordWithNullify.new
      @record.foo = "  "
      @record.valid?
      @record.foo.must_equal ""
    end
  end

  describe "Attribute with squish option" do
    class MockRecordWithSqueeze < ActiveRecord::Base
      column :foo, :string
      auto_strip_attributes :foo, :squeeze_spaces => true
    end

    it "should squish item" do
      @record = MockRecordWithSqueeze.new
      @record.foo = "  aaa\t\t     bbb"
      @record.valid?
      @record.foo.must_equal "aaa bbb"
    end
  end

  describe "Multible attributes with multiple options" do
    class MockRecordWithMultipleAttributes < ActiveRecord::Base
      column :foo, :string
      column :bar, :string
      column :biz, :string
      column :bang, :integer
      auto_strip_attributes :foo, :bar
      auto_strip_attributes :biz, {:nullify => false, :squeeze_spaces => true}
    end

    it "should handle everything ok" do
      @record = MockRecordWithMultipleAttributes.new
      @record.foo = "  foo\tfoo"
      @record.bar = "  "
      @record.biz = "  "
      @record.valid?
      @record.foo.must_equal "foo\tfoo"
      @record.bar.must_be_nil
      @record.biz.must_equal ""
    end
  end

  describe "Attribute with custom setter" do
    class MockRecordWithCustomSetter < ActiveRecord::Base
      column :foo, :string
      auto_strip_attributes :foo

      def foo=(val)
        self[:foo] = "#{val}-#{val}"
      end
    end

    it "should not call setter again in before_validation" do
      @record = MockRecordWithCustomSetter.new
      @record.foo = " foo "
      @record.foo.must_equal " foo - foo "
      @record.valid?
      @record.foo.must_equal "foo - foo"
    end
  end


end