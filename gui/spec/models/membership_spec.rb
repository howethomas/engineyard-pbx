File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe 'Membership' do
  describe '#redefine_membership_associations_with' do
    it "should run the specs right" do
      true.should == true
    end
  end
end
