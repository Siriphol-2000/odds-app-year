class User < ApplicationRecord
  validates :first_name, :last_name, :email, :phone, :subject,:email,:gender,:birthday, presence: true
end
