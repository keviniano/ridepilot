if !Rails.env.test?
  ApplicationSetting['cad_avl.gps_interval_seconds'] = 10
  ApplicationSetting['cad_avl.cad_refresh_interval_seconds'] = 30
  ApplicationSetting['cad_avl.data_storage_months'] = 1
end