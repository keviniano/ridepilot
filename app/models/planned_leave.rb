class PlannedLeave < ActiveRecord::Base
  belongs_to :leavable, polymorphic: true

  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :compare_dates

  scope :leave_on_date, -> (date) { where("start_date <= ? and end_date >= ?", date, date) }
  scope :overlap,       -> (start_date, end_date) { where.not("start_date > ?", end_date).where.not("end_date < ?", start_date) }
  scope :current,       -> { where("end_date >= ?", Date.today) }
  scope :past,          -> { where("end_date < ?", Date.today) }

  default_scope -> { order(:start_date, :end_date) } 

  def compare_dates
    if start_date && end_date 
      if start_date > end_date
        errors.add(:base, "End Date should be later than Start Date") 
      elsif leavable
        errors.add(:base, "The date range overlaps with existing planned leaves") if leavable.planned_leaves.overlap(start_date, end_date).any?
      end
    end
  end
end
