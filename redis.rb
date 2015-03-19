#!/usr/local/rvm/rubies/ruby-2.1.1/bin/ruby
require 'redis'
require 'yaml'
require_relative 'common.rb'

def load_config()
  return symbolize_keys(YAML.load_file('/etc/scollector/collectors/config.yml'))
end

def main()
  config = load_config()[:redis]
  redis_host = config[:host] || '127.0.0.1'
  redis_port = config[:port] || '6379'
  redis_conn = Redis.new(host: redis_host, port: redis_port)
  begin
    config[:metrics].each do |metric|
      taglist = ''
      metric[:tags].each do |tag,value|
        taglist += "#{tag}=#{value} "
      end if metric[:tags]
      puts "redis.#{metric[:name]}  #{Time.now.to_i} #{redis_conn.send(metric[:cmd],metric[:args])} #{taglist}"
    end
  rescue Redis::BaseConnectionError => error
    puts "#{error}, retrying in 1s"
    sleep 1
    retry
  end
end

main()
