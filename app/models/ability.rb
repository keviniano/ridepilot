class Ability
  include CanCan::Ability

  def initialize(user)
    can_manage_all = false

    can :read, Mobility
    can :read, TripPurpose
    can :read, TripResult
    can :read, ServiceLevel
    can :read, Ethnicity
    can :read, FundingSource
    can :read, Region
    can :read, DriverRequirementTemplate
    can :read, VehicleMaintenanceScheduleType
    can :read, VehicleMaintenanceSchedule

    for role in user.roles
      if role.system_admin?
        can_manage_all = true
        can :manage, :all
        break
      end
    end
    
    unless can_manage_all
      for role in user.roles
        if role.editor?
          action = :manage
        else
          action = :read
        end
        can action, Provider, :id => role.provider.id
        cannot :create, Provider
      end
    end

    provider = user.current_provider
    role = Role.where("provider_id = ? and user_id = ?", provider.id, user.id).first
    if not role
      return
    end
    if role.editor?
      action = :manage
    else
      action = [:read, :search]
    end

    can action,  Address, :provider_id => provider.id
    can action,  Customer, :provider_id => provider.id
    can action,  DevicePool, :provider_id => provider.id if provider.dispatch?
    can action,  DevicePoolDriver, :provider_id => provider.id
    can :manage, DevicePoolDriver, :driver_id => user.driver.id if user.driver.present?
    can action,  Document, :documentable => {:provider_id => provider.id}
    can action,  Driver, :provider_id => provider.id
    can action,  Monthly, :provider_id => provider.id
    can action,  RepeatingTrip, :provider_id => provider.id
    can action,  RepeatingRun, :provider_id => provider.id
    can action,  Run, :provider_id => provider.id if provider.scheduling?
    can action,  Trip, :provider_id => provider.id if provider.scheduling?
    can action,  Vehicle, :provider_id => provider.id
    
    if role.admin?
      can :manage, DriverCompliance, :driver => {:provider_id => provider.id}
      can :manage, DriverHistory, :driver => {:provider_id => provider.id}
      can :manage, LookupTable
      can :manage, ProviderLookupTable
      can :manage, User, :roles => {:provider_id => provider.id}
      can :manage, VehicleMaintenanceEvent, :vehicle => {:provider_id => provider.id}
      can :manage, VehicleMaintenanceCompliance, :vehicle => {:provider_id => provider.id}
      can :manage, VehicleWarranty, :vehicle => {:provider_id => provider.id}
      can :load,   Address
      can :manage, DriverRequirementTemplate, :provider_id => provider.id
      can :manage, VehicleMaintenanceScheduleType, :provider_id => provider.id
      can :manage, VehicleMaintenanceSchedule, :vehicle_maintenance_schedule_type => { :provider_id => provider.id}
    else
      can :read, User, :roles => {:provider_id => provider.id}
      can :edit, user
      cannot :delete, Vehicle
      cannot :delete, Driver
    end

    if role.editor?
      can :manage, RecurringDriverCompliance, :provider_id => provider.id
      can :manage, RecurringVehicleMaintenanceCompliance, :provider_id => provider.id
    end

    can :access, Reporting::Report
  end
end