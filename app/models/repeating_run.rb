# This is a 'dumb' model. It is managed by a Run instance, which creates a 
# repeating instance of itself when instructed to. Validation is nonexistent 
# since all data should already have been vetted by the Run instance.
class RepeatingRun < ActiveRecord::Base
  include RunCore
  include RequiredFieldValidatorModule
  include RecurringRideCoordinator
  include RecurringRideCoordinatorScheduler

  has_paper_trail

  validates :comments, :length => { :maximum => 30 } 
  
  scope :active, -> { where("end_date is NULL or end_date >= ?", Date.today) }
  # a query to find repeating_runs that can be used to assign repeating_trips
  scope :during, -> (from_time, to_time) { where("NOT (scheduled_start_time::time <= ?) OR NOT(scheduled_end_time::time <= ?)", to_time.utc.to_s(:time), from_time.utc.to_s(:time)) }

  schedules_occurrences_with with_attributes: -> (run) {
      {
        repeat:        1,
        interval_unit: "week",
        start_date:    Date.today.to_s,
        interval:      run.repetition_interval, 
        monday:        run.repeats_mondays    ? 1 : 0,
        tuesday:       run.repeats_tuesdays   ? 1 : 0,
        wednesday:     run.repeats_wednesdays ? 1 : 0,
        thursday:      run.repeats_thursdays  ? 1 : 0,
        friday:        run.repeats_fridays    ? 1 : 0,
        saturday:      run.repeats_saturdays  ? 1 : 0,
        sunday:        run.repeats_sundays    ? 1 : 0
      }
    },
    destroy_future_occurrences_with: -> (run) {
      # Be sure not delete occurrences that have already been completed.
      runs = if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after_today.incomplete
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after(run.date).incomplete
      end

      schedule = run.repeating_run.schedule
      Run.transaction do
        runs.find_each do |r|
          r.destroy unless schedule.occurs_on?(r.date)
        end
      end
    },
    destroy_all_future_occurrences_with: -> (run) {
      # Be sure not delete occurrences that have already been completed.
      runs = if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after_today.incomplete
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after(run.date).incomplete
      end

      runs.destroy_all
    },
    unlink_past_occurrences_with: -> (run) {
      if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).today_and_prior.update_all "repeating_run_id = NULL"
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).prior_to(run.date).update_all "repeating_run_id = NULL"
      end
    }

  def instantiate!
    return unless active? 

    now = Date.today.in_time_zone + 1.day
    later = now.advance(days: (provider.try(:advance_day_scheduling) || Provider::DEFAULT_ADVANCE_DAY_SCHEDULING) - 1)
    RepeatingRun.transaction do
      for date in schedule.occurrences_between(now, later)
        date = date.to_date
        next if (start_date.present? && date < start_date) || (end_date.present? && date > end_date)
        unless Run.repeating_based_on(self).for_date(date).exists?
          attributes = self.attributes.select{ |k, v| RepeatingRun.ride_coordinator_attributes.include? k.to_s }
          attributes["date"] = date
          attributes["repeating_run_id"] = id
          run = Run.new attributes
          # no validation to allow creating individual instances despite some conflicts with other daily runs
          run.save(validate: false)
        end
      end
    end
  end

  def active?
    active = true

    today = Date.today
    active = false if end_date && today > end_date

    active
  end
end
