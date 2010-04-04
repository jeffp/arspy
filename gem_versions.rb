require 'rubygems'
require 'git'
require 'logger'

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

  def self.commit_and_push
    g=Git.open(File.dirname(__FILE__), :log=>Logger.new(STDOUT))
    g.add('gem_version')
    g.commit('incremented gem version')
    g.push
  end
end
