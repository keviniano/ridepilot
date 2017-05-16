require "rails_helper"

RSpec.describe Run, type: :model do

  describe "set_complete" do
    it "is called before validation" do
      run = build :run
      expect(run).to receive(:set_complete)
      run.valid?
    end

    it "checks for any pending trips" do
      run = create :run, start_odometer:100, end_odometer: 200
      trip = create :trip, run: run, trip_result: nil
      run.valid?
      expect(run.complete?).to be_falsey

      trip.update_attributes trip_result: create(:trip_result)
      run.valid?
      expect(run.complete?).to be_truthy
    end

    it "uses the Provider#fields_required_for_run_completion to decide if a run is considered complete" do
      run = create :run, start_odometer:100, end_odometer: 200
      run.provider.update_attributes fields_required_for_run_completion: %w(paid)
      run.valid?
      expect(run.complete?).to be_falsey

      run.paid = true
      run.valid?
      expect(run.complete?).to be_truthy
    end
  end
end
