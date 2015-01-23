module Errapi::Utils

  def self.camelize string, uppercase_first_letter = false
    parts = string.split '_'
    return string if parts.length < 2
    parts[0] + parts[1, parts.length - 1].collect(&:capitalize).join
  end

  def self.underscore string
    string.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
end
