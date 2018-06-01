class TripResult < ApplicationRecord
  acts_as_paranoid # soft delete
  has_paper_trail

  SHOW_ALL_ID = -2
  UNSCHEDULED_ID = -1

  # Cancelled, Late Cancel, Same Day Cancel, Missed Trip, No Show
  CANCEL_CODES = ['CANC', 'LTCANC', 'SDCANC', 'MT', 'NS']
  CANCEL_CODES_BUT_KEEP_RUN = ['MT', 'NS'] # do not take trip off the run
  CLIENT_CODE_VERIFY_RESULT_CODES = ['CANC', 'LTCANC', 'SDCANC']
  NON_DISPATCHABLE_CODES = CANCEL_CODES + ['UNMET', 'TD']
  CODES_NEED_REASON = CANCEL_CODES + ['TD']

  validates :name, presence: true, uniqueness: {case_sensitive: false, conditions: -> { where(deleted_at: nil) } }
  validates :code, presence: true, uniqueness: {case_sensitive: false, conditions: -> { where(deleted_at: nil) } }

  scope :cancel_codes, -> { where(code: CANCEL_CODES) }

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids)
  end

  def full_description
    description || name
  end

  def self.is_reason_needed?(code)
    CODES_NEED_REASON.include? code
  end

  def self.is_cancel_code?(code)
    CANCEL_CODES.include? code
  end

  def turned_down?
    code == 'TD'
  end

  def cancelled?
    self.class.is_cancel_code?(code)
  end

  def self.non_dispatchable_result_ids
    @non_dispatchable_result_ids ||= where(code: NON_DISPATCHABLE_CODES).pluck(:id)
  end

  def self.cancel_result_ids
    @cancel_result_ids ||= where(code: CANCEL_CODES).pluck(:id)
  end

  def self.client_code_verify_result_ids
    @client_code_verify_result_ids ||= where(code: CLIENT_CODE_VERIFY_RESULT_CODES).pluck(:id)
  end

  def self.reason_needed_result_ids
    @reason_needed_result_ids ||= where(code: CODES_NEED_REASON).pluck(:id)
  end
end
