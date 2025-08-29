class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    if user.admin?
      define_admin_abilities
    elsif user.supervisor?
      define_supervisor_abilities(user)
    end
  end

  private

  def define_admin_abilities
    can :manage, :all
    can :profile, User
    can :update_role, User
  end

  def define_supervisor_abilities user
    define_user_permissions(user)
    define_zone_and_device_permissions(user)
    define_alert_and_log_permissions(user)
  end

  def define_user_permissions user
    can :show, User, id: [user.id, user.admin_id].compact
    can :update, User, id: user.id
    can :profile, User, id: user.id
  end

  def define_zone_and_device_permissions user
    can :manage, Zone, user_id: user.id
    can :manage, Camera, zone: {user_id: user.id}
    can :manage, Sensor, zone: {user_id: user.id}
  end

  def define_alert_and_log_permissions user
    can :read, Alert, zone: {user_id: user.id}
    can :update_status, Alert, zone: {user_id: user.id}
    can :read, SensorLog, sensor: {zone: {user_id: user.id}}
    can [:chart, :stats], SensorLog
  end
end
