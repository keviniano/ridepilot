class EtaUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(itin_id, new_eta_str)
    return unless itin_id && new_eta_str

    Rails.logger.info "EtaUpdateWorker#perform, itin_id=#{itin_id}, new_eta=#{new_eta_str}"
    
    itin = Itinerary.unscoped.find_by_id(itin_id)
    new_eta = Time.parse(new_eta_str)
    if itin && new_eta
      current_public_itin = itin.public_itinerary
      run = current_public_itin.run 
      old_eta = current_public_itin.eta
      eta_diff_seconds = (new_eta - old_eta).to_i if new_eta && old_eta
      current_public_itin.eta = new_eta 
      current_public_itin.save(validate: false)

      if eta_diff_seconds && eta_diff_seconds != 0
        itins = run.public_itineraries
        itin_index = itins.index(itin)
        if itin_index
          last_eta = current_public_itin.eta
          itins[itin_index+1..-1].each do |public_itin|
            internal_itin = public_itin.itinerary
            if last_eta && internal_itin.is_pickup? && !internal_itin.trip.early_pickup_allowed 
              # if early pickup not allowed, then need to check if ETA > scheduled_time
              if last_eta <= internal_itin.time
                break
              else
                # otherwise, re-calculate eta diff based on this leg
                eta_diff_seconds = (last_eta - internal_itin.time).to_i
              end
            end

            if public_itin.eta 
              public_itin.eta = public_itin.eta + (eta_diff_seconds).seconds 
              public_itin.save(validate: false)
              last_eta = public_itin.eta
            end
          end
        end
      end
    end 
  end
end
