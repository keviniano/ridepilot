module TrackerActionLogHelper
  def formulate_log_message(log)
    return nil unless log 

    case log.key
    when "trip.created"
      trip = log.trackable
      if trip.present?
        creator = trip.repeating_trip_id.present? ? "subscription on #{trip.created_at.try(:strftime, '%m/%d/%Y')}" : (log.owner ? log.owner.try(:name) : 'person')
        "Trip created by #{creator}.".html_safe
      end
    when "run.created"
      run = log.trackable
      if run.present?
        creator = run.repeating_run_id.present? ? "subscription on #{run.created_at.try(:strftime, '%m/%d/%Y')}" : (log.owner ? log.owner.try(:name) : 'person')
        "Run created by #{creator}.".html_safe
      end
    when "run.updated"
      run = log.trackable
      params = log.parameters || {}
      if run.present? && !params.blank?
        msg = "Run had following updates:"
        params.each do |k, v|
          if v.try(:size) == 2 # [old_val, new_val] array
            msg += "<div class='row'><div class='col-sm-4'><b>#{k}:</b></div><div class='col-sm-8'>#{v[1]} <br>(<b>was:</b> #{v[0]})</div></div>"
          end
        end

        msg.html_safe
      end
    when "run.completed"
      run = log.trackable
      if run.present?
        completer = (log.owner ? log.owner.try(:name) : 'the system')
        "Run completed by #{completer}.".html_safe
      end
    when "run.uncompleted"
      run = log.trackable
      if run.present?
        completer = (log.owner ? log.owner.try(:name) : 'the system')
        params = log.parameters || {}
        reason = params[:reason].blank? ? '(Not provided.)' : params[:reason]
        "Run marked as incomplete by #{completer}. <br>Reason: #{reason}".html_safe
      end
    when "trip.create_return"
      return_trip = log.trackable.try(:return_trip)
      if return_trip.present?
        creator = log.owner ? log.owner.try(:name) : 'person'
        "Return trip (#{link_to return_trip.id, return_trip}) created by #{creator}.".html_safe
      end
    when "trip.return_created"
      outbound_trip = log.trackable.try(:outbound_trip)
      if outbound_trip.present?
        "Return trip created for outbound trip (#{link_to outbound_trip.id, outbound_trip})".html_safe
      end
    when "trip.trip_cancelled"
      trip = log.trackable
      if trip.present?
        params = log.parameters || {}
        reason = params[:reason].blank? ? '(Not provided.)' : params[:reason]
        "Trip was cancelled (#{params[:trip_result]}). <br>Reason: #{reason}".html_safe
      end
    when "trip.trip_turned_down"
      trip = log.trackable
      if trip.present?
        params = log.parameters || {}
        reason = params[:reason].blank? ? '(Not provided.)' : params[:reason]
        "Trip was Turned Down. <br>Reason: #{reason}".html_safe
      end
    when "repeating_trip.subscription_created"
      trip = log.trackable
      if trip.present?
        "Subscription trip was created."
      end
    when "repeating_trip.subscription_updated"
      trip = log.trackable
      params = log.parameters || {}
      if trip.present? && !params.blank?
        msg = "Subscription trip had following updates:"
        params.each do |k, v|
          if v.try(:size) == 2 # [old_val, new_val] array
            msg += "<div class='row'><div class='col-sm-4'><b>#{k}:</b></div><div class='col-sm-8'>#{v[1]} <br>(<b>was:</b> #{v[0]})</div></div>"
          end
        end

        msg.html_safe
      end
    when "repeating_run.subscription_created"
      run = log.trackable
      if run.present?
        "Subscription run was created."
      end
    when "repeating_run.subscription_updated"
      run = log.trackable
      params = log.parameters || {}
      if run.present? && !params.blank?
        msg = "Subscription run had following updates:"
        params.each do |k, v|
          if v.try(:size) == 2 # [old_val, new_val] array
            msg += "<div class='row'><div class='col-sm-4'><b>#{k}:</b></div><div class='col-sm-8'>#{v[1]} <br>(<b>was:</b> #{v[0]})</div></div>"
          end
        end

        msg.html_safe
      end
    when "vehicle.initial_mileage_changed"
      vehicle = log.trackable
      params = log.parameters || {}
      mileage = params[:mileage]
      if vehicle.present? && mileage.try(:size) == 2 # [old_val, new_val]
        reason = params[:reason].blank? ? '(Not provided.)' : params[:reason]
        if mileage[1].blank?
          "Initial mileage was removed (<b>was:<> #{mileage[0]}). <br><b>Reason:</b> #{reason}".html_safe
        else
          "Initial mileage was changed to #{mileage[1]} (<b>was:</b> #{mileage[0]}). <br><b>Reason:</b> #{reason}".html_safe
        end
      end
    when "vehicle.active_status_changed"
      vehicle = log.trackable
      params = log.parameters || {}

      if vehicle.present? && !params.blank?
        msg = ""
        if params[:prev_active_status_text] != params[:active_status_text]
          msg += "Active status changed to:<div class='col-sm-12'>#{params[:active_status_text]}</div>" + 
                "<p style='margin: 0px;'><b>Was: </b></p><div class='col-sm-12'>#{params[:prev_active_status_text]}</div>"+ 
                "<p style='margin: 0px;'><b>Reason: </b></p><div class='col-sm-12'>#{params[:reason]}</div>"
        elsif params[:prev_reason] != params[:reason]
          msg = "Active status:<div class='col-sm-12'>#{params[:active_status_text]}</div>"  +
                "<p style='margin: 0px;'><b>Reason: </b></p><div class='col-sm-12'>#{params[:reason]}</div>"
        end

        msg.html_safe
      end
    when "driver.active_status_changed"
      driver = log.trackable
      params = log.parameters || {}

      if driver.present? && !params.blank?
        msg = ""
        if params[:prev_active_status_text] != params[:active_status_text]
          msg += "Active status changed to:<div class='col-sm-12'>#{params[:active_status_text]}</div>" + 
                "<p style='margin: 0px;'><b>Was: </b></p><div class='col-sm-12'>#{params[:prev_active_status_text]}</div>"+ 
                "<p style='margin: 0px;'><b>Reason: </b></p><div class='col-sm-12'>#{params[:reason]}</div>"
        elsif params[:prev_reason] != params[:reason]
          msg = "Active status:<div class='col-sm-12'>#{params[:active_status_text]}</div>"  +
                "<p style='margin: 0px;'><b>Reason: </b></p><div class='col-sm-12'>#{params[:reason]}</div>"
        end

        msg.html_safe
      end
    when "customer.active_status_changed"
      customer = log.trackable
      params = log.parameters || {}

      if customer.present? && !params.blank?
        msg = ""
        if params[:prev_active_status_text] != params[:active_status_text]
          msg += "Active status changed to:<div class='col-sm-12'>#{params[:active_status_text]}</div>" + 
                "<p style='margin: 0px;'><b>Was: </b></p><div class='col-sm-12'>#{params[:prev_active_status_text]}</div>"+ 
                "<p style='margin: 0px;'><b>Reason: </b></p><div class='col-sm-12'>#{params[:reason]}</div>"
        elsif params[:prev_reason] != params[:reason]
          msg = "Active status:<div class='col-sm-12'>#{params[:active_status_text]}</div>"  +
                "<p style='margin: 0px;'><b>Reason: </b></p><div class='col-sm-12'>#{params[:reason]}</div>"
        end

        msg.html_safe
      end
    when "customer.customer_comments_created"
      customer = log.trackable

      if customer.present?
        "Customer comments added."
      end
    when "customer.customer_comments_updated"
      customer = log.trackable

      if customer.present?
        "Customer comments updated."
      end
    when "provider.active_status_changed"
      provider = log.trackable
      params = log.parameters || {}

      if provider.present? && !params.blank?
        if params[:active]
          msg = "Reactivated."
        else
          msg = "Inactivated.<p style='margin: 0px;'><b>Reason: </b></p><div class='col-sm-12'>#{params[:reason]}</div>"
        end

        msg.html_safe
      end
    when "trip.trip_scheduled"
      trip = log.trackable
      params = log.parameters || {}

      if trip.present?
        "Trip scheduled to #{params[:to]} from #{params[:from]}"
      end
    when "run.trip_added", "repeating_run.trip_added"
      run = log.trackable
      params = log.parameters || {}

      if run.present?
        count = params[:count].try(:to_i)
        if count
          if count > 1
            (params[:day_of_week].blank? ? "" : "#{params[:day_of_week].titleize}: ") + "#{count} trips added."
          else
            (params[:day_of_week].blank? ? "" : "#{params[:day_of_week].titleize}: ") + "1 trip added."
          end
        end
      end
    when "run.trip_removed", "repeating_run.trip_removed"
      run = log.trackable
      params = log.parameters || {}

      if run.present?
        count = params[:count].try(:to_i)
        if count
          if count > 1
            (params[:day_of_week].blank? ? "" : "#{params[:day_of_week].titleize}: ") + "#{count} trips removed."
          else
            (params[:day_of_week].blank? ? "" : "#{params[:day_of_week].titleize}: ") + "1 trip removed."
          end
        end
      end
    when "run.itinerary_rearranged", "repeating_run.itinerary_rearranged"
      run = log.trackable
      params = log.parameters || {}
      if run.present?
        (params[:day_of_week].blank? ? "" : "#{params[:day_of_week].titleize}: ") + "Trip itineraries rearranged" 
      end
    when "run.run_cancelled", "repeating_run.run_cancelled"  
      run = log.trackable
      params = log.parameters || {}
      if run.present?
        (params[:day_of_week].blank? ? "" : "#{params[:day_of_week].titleize}: ") + "Run cancelled." 
      end
    end

  end
end
