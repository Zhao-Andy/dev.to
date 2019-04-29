class OrganizationPolicy < ApplicationPolicy
  def create?
    !user.banned
  end

  def update?
    user.org_admin?(record)
  end

  def part_of_org?
    return false if record.blank?

    OrganizationMembership.exists?(user_id: user.id, organization_id: record.id)
  end

  def generate_new_secret?
    update?
  end

  def pro_org_user?
    user.has_role?(:pro) && OrganizationMembership.exists?(user_id: user.id, organization_id: record.id)
  end
end
