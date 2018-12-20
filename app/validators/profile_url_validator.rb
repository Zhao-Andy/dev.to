class ProfileUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true if value.blank?
    host_name = attribute.to_s.split("_url")[0]
    is_valid = case attribute
               when :stackoverflow_url
                 value.include?("stackoverflow") || value.include?("stackexchange")
               else
                 value.include?(host_name)
               end
    is_valid ? true : record.errors[attribute] << "uses an invalid host name"
  end
end
