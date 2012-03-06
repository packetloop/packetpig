require 'rubygems'
require 'geoip'
require 'logger'

#log = Logger.new('log.txt')

STDIN.each_line do |line|
    packet = line.split(' ')
#   log.debug line.to_s
#    log.debug "The number of vars is #{packet.size}"
    country = GeoIP.new('../data/GeoIP.dat').country(packet[13])
    puts country[4].to_s
end
