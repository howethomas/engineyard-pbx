class Membership < ActiveRecord::Base
  belongs_to :employee
  belongs_to :group
end
