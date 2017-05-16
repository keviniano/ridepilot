class Run < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include RunCore

  acts_as_paranoid # soft delete

  has_paper_trail

  # Ignores:
  #   Already required:
  #     date
  #     driver_id
  #     provider_id
  #     vehicle_id
  #   Already checked by set_complete:
  #     start_odometer
  #     end_odometer 
  #   Meta
  #     created_at
  #     updated_at
  #     lock_version
  FIELDS_FOR_COMPLETION = [
    :name,
    :start_odometer,
    :end_odometer,
    :unpaid_driver_break_time,
    :paid,
  ].freeze

  has_many :trips, -> { order(:pickup_time) }, :dependent => :nullify
  belongs_to :repeating_run

  accepts_nested_attributes_for :trips

  before_validation :fix_dates, :set_complete

  validates                 :name, presence: true, uniqueness: { scope: :date, message: "should be unique per day" }
  validates_date            :date
  validates_datetime        :actual_start_time, allow_blank: true
  validates_datetime        :actual_end_time, after: :actual_start_time, allow_blank: true
  validates_numericality_of :start_odometer, allow_nil: true
  validates_numericality_of :end_odometer, allow_nil: true
  validates_numericality_of :end_odometer, greater_than: -> (run){ run.start_odometer }, less_than: -> (run){ run.start_odometer + 500 }, if: -> (run){ run.start_odometer.present? }, allow_nil: true
  validates_numericality_of :unpaid_driver_break_time, allow_nil: true
  validate                  :within_advance_day_scheduling
  validate                  :driver_availability
  validate                  :vehicle_availability

  scope :after,                  -> (date) { where('runs.date > ?', date) }
  scope :after_today,            -> { where('runs.date > ?', Date.today) }
  scope :prior_to,               -> (date) { where('runs.date < ?', date) }
  scope :today_and_prior,        -> { where('runs.date <= ?', Date.today) }
  scope :for_date,               -> (date) { where('runs.date = ?', date) }
  scope :for_date_range,         -> (start_date, end_date) { where("runs.date >= ? and runs.date < ?", start_date, end_date) }
  scope :overlapped,             -> (run) { where("date = ?", run.date).where.not("scheduled_end_time <= ? or scheduled_start_time >= ?", run.scheduled_start_time, run.scheduled_end_time) }

  scope :complete,               -> { where(complete: true) }
  scope :incomplete,             -> { where('complete is NULL or complete = ?', false) }
  scope :incomplete_on,          -> (date) { incomplete.for_date(date) }
  scope :with_odometer_readings, -> { where("start_odometer IS NOT NULL and end_odometer IS NOT NULL") }
  scope :repeating_based_on,     ->(scheduler) { where(repeating_run_id: scheduler.try(:id)) }
  scope :this_week,              -> {
    where(date: DateTime.now.in_time_zone.beginning_of_week.to_date..DateTime.now.in_time_zone.end_of_week.to_date)
  }

  CAB_RUN_ID = -1 # id for cab runs
  UNSCHEDULED_RUN_ID = -2 # id for unscheduled run (empty container)

  def as_calendar_json
    {
      id: id,
      start: scheduled_start_time ? scheduled_start_time.iso8601 : nil,
      end: scheduled_end_time ? scheduled_end_time.iso8601 : nil,
      title: label,
      resource: date.to_date.to_s(:js)
    }
  end

  def self.fake_cab_run
    Run.new name: TranslationEngine.translate_text(:cab), id: Run::CAB_RUN_ID
  end

  def self.fake_unscheduled_run
    Run.new name: TranslationEngine.translate_text(:unscheduled), id: Run::UNSCHEDULED_RUN_ID
  end

  def self.update_prior_run_complete_status!
    Run.prior_to(Date.today).incomplete.each do |r|
      completed = r.check_complete_status
      r.update(complete: true) if completed
    end
  end

  def check_complete_status
    start_odometer.present? && end_odometer.present? && start_odometer < end_odometer && trips.incomplete.empty? && check_provider_fields_required_for_run_completion
  end

  def self.other_overlapped_runs(run)
    overlapped_runs = Run.overlapped(run)
    overlapped_runs = overlapped_runs.where.not(id: run.id) unless run.new_record?

    overlapped_runs
  end

  # Returns sum of actual run hours across a collection
  def self.total_actual_hours
    total_hours(actual: true)
  end

  # Returns sum of scheduled run hours across a collection
  def self.total_scheduled_hours
    total_hours(actual: false)
  end

  # Returns the total hours of a collection of runs
  def self.total_hours(opts={actual: true})
    query_str = opts[:actual] ? 'actual_end_time - actual_start_time' : 'scheduled_end_time - scheduled_start_time'
    query_result = sum(query_str).to_s.to_time
    return query_result ? query_result.seconds_since_midnight / 3600.0 : 0
  end

  # Returns length in hours for an individual run. Use scheduled hours
  def hours_scheduled
    seconds = scheduled_end_time - scheduled_start_time
    seconds / 3600.0
  end


  private

  # A run is considered complete if:
  #  actual_end_time is valued (which requires that actual_start_time is also valued)
  #  actual_end_time is before "now"
  #  None of its trips are still considered pending
  #  Any fields that the run provider has listed as required are valued
  def set_complete
    self.complete = self.check_complete_status
    true
  end

  def fix_dates
    d = self.date
    unless d.nil?
      unless scheduled_start_time.nil?
        s = scheduled_start_time
        self.scheduled_start_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_start_time_will_change!
      end
      unless scheduled_end_time.nil?
        s = scheduled_end_time
        self.scheduled_end_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_end_time_will_change!
      end
      unless actual_start_time.nil?
        a = actual_start_time
        self.actual_start_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_start_time_will_change!
      end
      unless actual_end_time.nil?
        a = actual_end_time
        self.actual_end_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_end_time_will_change!
      end
    end
    true
  end

  def driver_availability
    #if date && scheduled_start_time && driver && !driver.available?(date.wday, scheduled_start_time.strftime('%H:%M'))
      #errors.add(:driver_id, TranslationEngine.translate_text(:unavailable_at_run_time))
    #end
    if self.driver && Run.other_overlapped_runs(self).pluck(:driver_id).include?(self.driver.id)
      errors.add(:driver_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end

  def vehicle_availability
    if self.vehicle && Run.other_overlapped_runs(self).pluck(:vehicle_id).include?(self.vehicle.id)
      errors.add(:vehicle_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end

  def check_provider_fields_required_for_run_completion
    provider.present? && provider.fields_required_for_run_completion.select{ |attr| self[attr].blank? }.empty?
  end

  def within_advance_day_scheduling
    advance_day_scheduling = provider.try(:get_advance_day_scheduling)
    if date && advance_day_scheduling.present? && (date - Date.current).to_i > advance_day_scheduling
      errors.add(:date, TranslationEngine.translate_text(:beyond_advance_day_scheduling) % {advance_day_scheduling: advance_day_scheduling})
    end
  end
end
