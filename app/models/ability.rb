class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    if user.admin?
      admin_abilities(user)
    elsif user.supervisor?
      supervisor_abilities(user)
    end
  end

  private

  def admin_abilities _user
    can :manage, :all
    can [:update_role, :read, :update], User
    can [:stats, :capture_and_upload_snapshot], Camera
    can [:stats, :chart], SensorLog
    can [:stats, :bulk], Sensor
    can :manage, Invitation
    can [:stats, :update_status], Alert
  end

  def supervisor_abilities user
    can [:read, :update], User, id: user.id
    can [:read, :create, :update, :destroy], Zone, user_id: user.id
    can [:read, :create, :update, :manage], Sensor, zone: {user_id: user.id}
    can [:stats, :bulk], Sensor
    can [:read, :create, :update, :destroy, :capture_and_upload_snapshot],
        Camera, zone: {user_id: user.id}
    can :read, Invitation, creator_id: user.id
    can :read, SensorLog, sensor: {zone: {user_id: user.id}}
    can [:stats, :chart], SensorLog
    can [:stats, :update_status], Alert
  end
end
