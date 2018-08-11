class FundingSourcesController < ApplicationController
  
  respond_to :html, :js

  def mark_ntd_reportable
    if params[:funding_source]
      source = FundingSource.find_by_id(params[:id])
      if source
        source.ntd_reportable = params[:funding_source][:ntd_reportable]
        source.save(validate: false)
      end
    end

    render json: {}
  end
end