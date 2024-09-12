class User < ApplicationRecord
  validates :first_name, :last_name, :email, :phone, :subject, :email, :gender, :birthday, presence: true
  validate :must_be_at_least_18_year_old

  private

  def must_be_at_least_18_year_old
    return unless birthday.present? && birthday > 18.year.ago.to_date

    errors.add(:birthday, 'You must be at least 18 year old')
  end
end
