require 'rubygems'
require 'aws'

task :default => :upload

task :upload do
  s3 = AWS::S3.new

  Dir['pig/examples/*.pig'].each do |pig|
    puts "s3://packetpig/#{pig}"
    remote = s3.buckets['packetpig'].objects[pig]
    remote.write(File.read(pig))
  end

  ['pig/include-emr.pig'].each do |f|
    puts "s3://packetpig/#{f}"
    remote = s3.buckets['packetpig'].objects[f]
    remote.write(File.read(f))
  end

  libs = Dir['lib/*.jar'] + ['lib/bootstrap.sh']
  libs -= ['lib/packetpig-with-dependencies.jar']
  libs.each do |lib|
    remote_lib = File.basename(lib)
    puts "s3://packetpig/#{remote_lib}"
    remote = s3.buckets['packetpig'].objects[remote_lib]
    remote.write(File.read(lib))
  end

  `tar czf lib/scripts.tar.gz lib/scripts lib/tailer`
  puts "s3://packetpig/scripts.tar.gz"
  remote = s3.buckets['packetpig'].objects['scripts.tar.gz']
  remote.write(File.read('lib/scripts.tar.gz'))
end

