class Person < ApplicationRecord
  after_commit -> { broadcast_refresh_later_to "people" }

  validates :first_name, :last_name, presence: true

  def full_name
    [first_name, last_name].select(&:present?).join(" ")
  end
end
