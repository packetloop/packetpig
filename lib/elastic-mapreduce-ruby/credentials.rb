#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'json'

class Credentials
  def initialize(commands)
    @options = commands.global_options
  end

  def parse_credentials(credentials, options)
    conversions = [
                   # These first ones use an incorrect naming convenion, 
                   # but we keep them around for backwards compatibility
                   [:aws_access_id, "access_id"],
                   [:aws_secret_key, "private_key"],
                   [:key_pair, "keypair"], 
                   [:key_pair_file, "keypair-file"], 
                   [:log_uri, "log_uri"], 
                   
                   # Now the current ones
                   [:aws_access_id, "access-id"],
                   [:aws_secret_key, "private-key"],
                   [:key_pair, "key-pair"], 
                   [:key_pair_file, "key-pair-file"], 
                   [:log_uri, "log-uri"], 
                   [:endpoint, "endpoint"], 
                   [:region, "region"], 
                   [:enable_debugging, "enable-debugging"],
                   [:hadoop_version, "hadoop-version"],
                  ]
    
    env_options = [
                   ['ELASTIC_MAPREDUCE_ACCESS_ID',         :aws_access_id],
                   ['ELASTIC_MAPREDUCE_PRIVATE_KEY',       :aws_secret_key],
                   ['ELASTIC_MAPREDUCE_KEY_PAIR',          :key_pair],
                   ['ELASTIC_MAPREDUCE_KEY_PAIR_FILE',     :key_pair_file],
                   ['ELASTIC_MAPREDUCE_LOG_URI',           :log_uri],
                   ['ELASTIC_MAPREDUCE_APPS_PATH',         :apps_path],
                   ['ELASTIC_MAPREDUCE_BETA_PATH',         :beta_path],
                   ['ELASTIC_MAPREDUCE_ENDPOINT',          :endpoint],
                   ['ELASTIC_MAPREDUCE_REGION',            :region],
                   ['ELASTIC_MAPREDUCE_HADOOP_VERSION',    :hadoop_version],
                   ['ELASTIC_MAPREDUCE_ENABLE_DEBUGGING',  :enable_debugging]
                  ]
    
    for env_key, option_key in env_options do
      if ! options[option_key] && ENV[env_key] then
        options[option_key] = ENV[env_key]
      end
    end
    
    candidates = [
                  credentials, 
                  ENV['ELASTIC_MAPREDUCE_CREDENTIALS'], 
                  File.join(File.dirname(__FILE__), credentials),
                  File.join(ENV['HOME'],  "." + credentials), 
                  File.join(ENV['HOME'],  credentials)
                 ]

    filename = candidates.find { |fname| File.exist?(fname) if fname }
    if filename != nil then
      begin
        credentials_hash = JSON.parse(File.read(filename))
        for option_key, credentials_key in conversions do
          if credentials_hash[credentials_key] && !options[option_key] then
            options[option_key] = credentials_hash[credentials_key]
          end
        end
      rescue Exception => e
        raise RuntimeError, "Unable to parse #{filename}: #{e.message}"
      end
    end
    
    error_if_nil(options[:aws_access_id], "Missing key access-id")
    error_if_nil(options[:aws_secret_key], "Missing key private-key")
  end

  def error_if_nil(value, message)
    if value == nil then
      raise RuntimeError, message
    end
  end

end

