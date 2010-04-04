module GemVersions
  def self.get_version
    file = File.new('gem_version', 'r')
    version = file.gets.chomp
    file.close
    version
  end

  def self.increment_version
    version = self.get_version
    components = version.split('.')
    components.push((components.pop.to_i + 1).to_s)
    new_version = components.join('.')
    file = File.new('gem_version', 'w')
    file.puts new_version
    file.close
    version
  end
end
