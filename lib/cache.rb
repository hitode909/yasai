gem 'dalli'
require 'dalli'
require 'digest/sha1'

module Cache
  def self.instance
    Dalli::Client.new(
      ENV['MEMCACHE_SERVERS'],
      :username => ENV['MEMCACHE_USERNAME'],
      :password => ENV['MEMCACHE_PASSWORD'],
      )
  end

  def self.get_or_set(key, expire = 3600 * 24 *rand)
    raise "block needed" unless block_given?
    key = Digest::SHA1.hexdigest(key.to_s)
    cache = self.instance.get(key)
    return cache if cache

    new_value = yield
    self.instance.set(key, new_value, expire)
    new_value
  rescue => error
    warn error
    new_value || yield
  end

  def self.force_set(key, value, expire = 3600 * 24 * rand)
    key = key.to_s
    cache = self.instance.get(key)
    self.instance.delete(key) if cache
    self.instance.set(key, value, expire)
    value
  end

  def self.delete(key)
    self.instance.delete(key)
  end
end
