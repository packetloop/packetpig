require 'rubygems'
require 'aws'

s3 = AWS::S3.new
@bucket = s3.buckets['packetpig']

def upload(src, dst)
  print "#{src} -> s3://#{@bucket.name}/#{dst} (#{File.size(src)} bytes) ... "
  $stdout.flush
  remote = @bucket.objects[dst]
  remote.write(File.read(src))
  puts "done"
  $stdout.flush
end

task :default => :upload

task :upload => [:pig, :lib, :scripts, :bootstrap]

task :pig do
  Dir['pig/examples/*.pig'].each do |pig|
    upload(pig, pig)
  end

  ['pig/include-emr.pig'].each do |f|
    upload(f, f)
  end
end

task :bootstrap do
  upload('lib/bootstrap.sh', 'bootstrap.sh')
end

task :lib do
  libs = Dir['lib/*.jar'] - ['lib/packetpig-with-dependencies.jar']
  libs.each do |lib|
    dst = File.basename(lib)
    upload(lib, dst)
  end
end

task :scripts do
  `tar czf lib/scripts.tar.gz lib/scripts lib/tailer`
  upload('lib/scripts.tar.gz', 'scripts.tar.gz')
end

