#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'set'
require 'credentials'
require 'optparse'
require 'client'
require 'ec2_client_wrapper'
require 'open3'

module Commands

  ELASTIC_MAPREDUCE_CLIENT_VERSION = "2012-07-31"

  class Commands
    attr_accessor :opts, :global_options, :commands, :logger, :executor

    def initialize(logger, executor)
      @commands = []
      @opts = nil
      @global_options = {
        :jobflow => []
      }
      @logger = logger
      @executor = executor
    end
    
    def last
      @commands.last
    end
    
    def <<(value)
      @commands << value
    end

    def size
      @commands.size
    end

    def validate
      @commands.each { |x| x.validate }
    end

    def enact(client)
      @commands.each { |x| x.enact(client) }
    end

    def each(&block)
      @commands.each(&block)
    end

    def parse_command(klass, name, description)
      @opts.on(name, description) do |arg|
        self << klass.new(name, description, arg, self)
      end      
    end

    def parse_option(klass, name, description, parent_commands, *args)
      @opts.on(name, description) do |arg|
        klass.new(name, description, arg, parent_commands, self, *args).attach(commands)
      end
    end

    def parse_options(parent_commands, options)
      for option in options do
        klass, name, description = option[0..2]
        args = option[3..-1]
        self.parse_option(klass, name, description, parent_commands, *args)
      end
    end

    def parse_jobflows(args)
      for arg in args do
        if arg =~ /^j-\w{5,20}$/  then
          @global_options[:jobflow] << arg
        end
      end
    end

    def have(field_symbol)
      return @global_options[field_symbol] != nil
    end

    def get_field(field_symbol, default_value=nil)
      value = @global_options[field_symbol]
      if ( value == nil ) then
        return default_value
      else
        return value
      end
    end

    def exec(cmd)
      @executor.exec(cmd)
    end
  end

  class Command
    attr_accessor :name, :description, :arg, :commands, :logger

    def initialize(name, description, arg, commands)
      @name = name
      @description = description
      @arg = arg
      @commands = commands
      @logger = commands.logger
    end

    # test any constraints that the command has
    def validate
    end

    # action the command
    def enact(client)
    end

    def option(argument_name, argument_symbol, value)
      var = self.send(argument_symbol)
      if var == nil then
        self.send((argument_symbol.to_s + "=").to_sym, value)
      elsif var.is_a?(Array) then
        var << value
      else
        raise RuntimeError, "Repeating #{argument_name} is not allowed, previous value was #{var.inspect}"
      end
    end
    
    def get_field(field_symbol, default_value=nil)
      value = nil
      if respond_to?(field_symbol) then
        value = self.send(field_symbol)
      end
      if value == nil then
        value = @commands.global_options[field_symbol]
      end
      default_field_symbol = ("default_" + field_symbol.to_s).to_sym
      if value == nil && respond_to?(default_field_symbol) then
        value = self.send(default_field_symbol)
      end
      if value == nil then
        value = default_value
      end
      return value
    end

    def require(field_symbol, error_msg)
      value = get_field(field_symbol)
      if value == nil then
        raise RuntimeError, error_msg
      end
      return value
    end

    def have(field_symbol)
      value = get_field(field_symbol)
      return value != nil 
    end

    def has_value(obj, *args)
      while obj != nil && args.size > 1 do
        obj = obj[args.shift]
      end
      return obj == args[0]
    end

    def resolve(obj, *args)
      while obj != nil && args.size > 0 do
        obj = obj[args.shift]
      end
      return obj
    end

    def require_single_jobflow
      jobflow_ids = get_field(:jobflow)
      if jobflow_ids.size == 0 then
        raise RuntimeError, "A jobflow is required to use option #{name}"
      elsif jobflow_ids.size > 1 then
        raise RuntimeError, "The option #{name} can only act on a single jobflow"
      end
      return jobflow_ids.first
    end

  end

  class CommandOption
    attr_accessor :name, :description, :arg, :parent_commands, :commands

    def initialize(name, description, arg, parent_commands, commands, field_symbol=nil, pattern=nil)
      @name = name
      @description = description
      @arg = arg
      @parent_commands = parent_commands
      @commands = commands
      @field_symbol = field_symbol
      @pattern = pattern
    end

    def attach(commands)
      for command in commands.reverse do
        command_name = command.name.split(/\s+/).first
        if @parent_commands.include?(command_name) || @parent_commands.include?(command.class) then
          return command
        end
      end
      raise RuntimeError, "Expected argument #{name} to follow one of #{parent_commands.join(", ")}"
    end
  end

  class StepCommand < Command
    attr_accessor :args, :step_name, :step_action, :apps_path, :beta_path
    attr_accessor :script_runner_path, :pig_path, :hive_path, :pig_cmd, :hive_cmd, :enable_debugging_path

    def initialize(*args)
      super(*args)
      @args = []
    end

    def default_script_runner_path
      File.join(get_field(:apps_path), "libs/script-runner/script-runner.jar")      
    end

    def default_pig_path
      File.join(get_field(:apps_path), "libs/pig/")      
    end

    def default_pig_cmd
      [ File.join(get_field(:pig_path), "pig-script"), "--base-path", 
        get_field(:pig_path) ]
    end

    def default_hive_path
      File.join(get_field(:apps_path), "libs/hive/")
    end

    def default_hive_cmd
      [ File.join(get_field(:hive_path), "hive-script"), "--base-path", 
        get_field(:hive_path) ]
    end

    def default_resize_jobflow_cmd
      File.join(get_field(:apps_path), "libs/resize-job-flow/0.1/resize-job-flow.jar")
    end

    def default_enable_debugging_path
      File.join(get_field(:apps_path), "libs/state-pusher/0.1")
    end

    def validate
      super
      require(:apps_path, "--apps-path path must be defined")
    end

    def script_args
      if @arg then
        [ @arg ] + @args
      else
        @args
      end
    end

    def extra_args
      if @args != nil && @args.size > 0 then
        return ["--args"] + @args
      else
        return []
      end
    end

    def ensure_install_cmd(jobflow, sc, install_step_class)
      has_install = false
      install_step = install_step_class.new_from_commands(commands, self)
      if install_step.jobflow_has_install_step(jobflow) then
        return sc
      else
        new_sc = []
        has_install_pi = false
        for sc_cmd in sc do
          if sc_cmd.is_a?(install_step_class) then
            if has_install_pi then
              next
            else
              has_install_pi = true
            end
          end
          if sc_cmd.is_a?(self.class) then
            if ! has_install_pi then
              has_install_pi = true
              new_sc << install_step
              install_step.validate
            end
          end
          new_sc << sc_cmd
        end
      end
      return new_sc
    end

    def reorder_steps(jobflow, sc)
      return sc
    end
  end

  class ResizeJobflowCommand < StepCommand
    def validate
      super
    end

    def steps
      step = {
        "Name"            => get_field(:step_name, "Resize Job Flow Command"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:resize_jobflow_cmd),
          "Args" => @args 
        }
      }
      return [ step ]
    end

  end

  class EnableDebuggingCommand < StepCommand
    def steps
      step = {
        "Name"            => get_field(:step_name, "Setup Hadoop Debugging"),
        "ActionOnFailure" => get_field(:step_action, "TERMINATE_JOB_FLOW"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:script_runner_path),
          "Args" => [ File.join(get_field(:enable_debugging_path), "fetch") ]
        }
      }
      return [ step ]
    end

    def reorder_steps(jobflow, sc)
      # remove enable debugging steps and add self at start
      new_sc = []
      for step_cmd in sc do
        if ! step_cmd.is_a?(EnableDebuggingCommand) then
          new_sc << step_cmd
        end
      end
      return [ self ] + new_sc
    end
  end

  class PigCommand < StepCommand
    attr_accessor :pig_versions

    def get_version_args(require_single_version)
      versions = get_field(:pig_versions, nil)
      if versions == nil then
        # Pass latest by default. 
        return ["--pig-versions", "latest"]
      end
      if require_single_version then
        if versions.split(",").size != 1 then
          raise RuntimeError, "Only one version my be specified for --pig-script"
        end
      end
      return ["--pig-versions", versions]
    end
  end
  
  class PigScriptCommand < PigCommand
    def steps
      mandatory_args = [ "--run-pig-script", "--args", "-f" ]
      if @arg then
        mandatory_args << @arg
      end
      step = {
        "Name"            => get_field(:step_name, "Run Pig Script"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:script_runner_path),
          "Args" => get_field(:pig_cmd) + get_version_args(true) + mandatory_args + @args
        }
      }
      return [ step ]
    end


    def reorder_steps(jobflow, sc)
      return ensure_install_cmd(jobflow, sc, PigInteractiveCommand)
    end
  end

  class PigInteractiveCommand < PigCommand
    def self.new_from_commands(commands, parent)
      sc = self.new("--pig-interactive", "Run a jobflow with Pig Installed", nil, commands)
      sc.step_action = parent.step_action
      return sc
    end

    def steps
      step = {
        "Name"            => get_field(:step_name, "Setup Pig"),
        "ActionOnFailure" => get_field(:step_action, "TERMINATE_JOB_FLOW"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:script_runner_path),
          "Args" => get_field(:pig_cmd) + ["--install-pig"] + extra_args +
          get_version_args(false)
        }
      }
      return [ step ]  
    end

    def jobflow_has_install_step(jobflow)
      install_steps = jobflow['Steps'].select do |step|
      step["ExecutionStatusDetail"]["State"] != "FAILED" &&
        has_value(step, 'StepConfig', 'HadoopJarStep', 'Jar', get_field(:script_runner_path)) &&
        has_value(step, 'StepConfig', 'HadoopJarStep', 'Args', 3, "--install-pig")
      end
      return install_steps.size > 0
    end
  end

  #
  # Script Command
  #

  class ScriptCommand < StepCommand

    attr_accessor :script
    
    def steps
      step = {
        "Name"            => get_field(:step_name, "Run Hive Script"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:script_runner_path),
          "Args" => [ get_field(:arg) ] + @args
        }
      }
      [ step ]
    end
  end

  #
  # HBase Commands
  #
  class HBaseCommand < Command
    attr_accessor :hbase_jar_path, :install_script, :backup_dir, :backup_version, :consistent
    attr_accessor :apps_path

    def initialize(*args)
      super(*args)
    end

    def hbase_jar_path
      "/home/hadoop/lib/hbase-0.92.0.jar"      
    end

    def install_script
      File.join(get_field(:apps_path), "bootstrap-actions/setup-hbase")
    end

    def get_step_args(cmd, cmd_arg=nil)
      args = [ "emr.hbase.backup.Main", cmd ] 
      if cmd_arg != nil then
        args << cmd_arg
      end
      if get_field(:backup_dir, nil) then
        args += [ "--backup-dir", get_field(:backup_dir) ]
      end
      if get_field(:backup_version, nil) then
        args += [ "--backup-version", get_field(:backup_version) ]
      end 
      if get_field(:consistent, nil) then
        args += [ "--consistent" ]
      end 
      return args
    end

    def reorder_steps(jobflow, sc)
      return sc
    end
  end

  class HBaseInstall < HBaseCommand

    INVALID_INSTANCE_TYPES = Set.new(%w(m1.small c1.medium))

    def modify_jobflow(jobflow)
      jobflow["Instances"]["TerminationProtected"] = "true"
      jobflow["Instances"]["KeepJobFlowAliveWhenNoSteps"] = "true"
      for group in jobflow["Instances"]["InstanceGroups"] do
        instance_type = group["InstanceType"]
        if ! is_valid_instance_type(instance_type) then
          raise "Instance type #{instance_type} is not compatible with HBase, try adding --instance-type m1.large"
        end
      end
      if ! is_valid_ami_version(jobflow["AmiVersion"]) then
        raise "Ami version #{jobflow["AmiVersion"]} is not compatible with HBase"
      end
    end

    def is_valid_ami_version(ami_version)
      ami_version == "latest" || ami_version >= "2.1"
    end

    def is_valid_instance_type(instance_type)
      return ! INVALID_INSTANCE_TYPES.member?(instance_type)
    end

    def bootstrap_actions(index)
      action = {
        "Name" => get_field(:bootstrap_name, "Install HBase"),
        "ScriptBootstrapAction" => {
          "Path" => get_field(:install_script),
          "Args" => []
        }
      }
      return [ action ]
    end

    def steps
      step = {
        "Name"            => get_field(:step_name, "Start HBase"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:hbase_jar_path),
          "Args" => [ "emr.hbase.backup.Main", "--start-master" ] 
        }
      }
      return [step]
    end

  end

  class HBaseBackup < HBaseCommand

    def initialize(*args)
      super(*args)
    end

    def steps
      step = {
        "Name"            => get_field(:step_name, "Backup HBase"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:hbase_jar_path),
          "Args" => get_step_args("--backup")
        }
      }
      return [step]
    end
  end

  class HBaseRestore < HBaseCommand

    def initialize(*args)
      super(*args)
    end

    def steps
      step = {
        "Name"            => get_field(:step_name, "Restore HBase"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:hbase_jar_path),
          "Args" => get_step_args("--restore")
        }
      }
      return [step]
    end

    def reorder_steps(jobflow, sc)
      new_sc = []
      for cmd in sc do
        if ! cmd.is_a?(HBaseRestore) then
          new_sc << cmd
        end
      end
      return [ self ] + new_sc
    end

  end

  class HBaseBackupSchedule < HBaseCommand

    attr_accessor :full_backup_time_interval, :full_backup_time_unit, :backup_dir
    attr_accessor :start_time, :disable_full_backups, :disable
    attr_accessor :incremental_time_interval, :incremental_time_unit
    attr_accessor :disable_incremental_backups
    
    def initialize(*args)
      super(*args)
    end

    def validate
      super
      unless get_field(:disable_full_backups, false) || get_field(:disable_incremental_backups, false) then
        require(:backup_dir,    "--backup-dir path must be defined")
      end
    end

    def isDisable
      disable = get_field(:disable_full_backups, false) || get_field(:disable_incremental_backups, false)
      return disable
    end
    
    def steps
      args = get_step_args("--set-scheduled-backup", isDisable ? "false" : "true")
      if get_field(:full_backup_time_interval, nil) then
        args += ["--full-backup-time-interval", get_field(:full_backup_time_interval, nil)]
      end
      if get_field(:full_backup_time_unit, nil) then
        args += ["--full-backup-time-unit", get_field(:full_backup_time_unit, nil)]
      end
      if get_field(:start_time, "now") then
        args += ["--start-time", get_field(:start_time, "now")]
        if get_field(:start_time, "now") == "now" then
          puts "Setting StartTime for periodic backups to now, since you did not specify start-time"
        end
      end
      if get_field(:incremental_time_interval, nil) then
        args += ["--incremental-backup-time-interval", get_field(:incremental_time_interval, nil)]
      end
      if get_field(:incremental_time_unit, nil) then
        args += ["--incremental-backup-time-unit", get_field(:incremental_time_unit, nil)]
      end
      if isDisable then
        if get_field(:disable_full_backups) then
          args += ["--disable-full-backups"]
        end
        if get_field(:disable_incremental_backups) then
          args += ["--disable-incremental-backups"]
        end
      end
      
      step = {
        "Name"            => get_field(:step_name, "Modify Backup Schedule"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:hbase_jar_path),
          "Args" => args
        }
      }
      return [step]
    end
  end

  #
  # Hive Commands
  #

  class HiveCommand < StepCommand
    attr_accessor :hive_versions
    
    def get_version_args(require_single_version)
      versions = get_field(:hive_versions, nil)
      if versions == nil then
        return ["--hive-versions", "latest"]
      end
      if require_single_version then
        if versions.split(",").size != 1 then
          raise RuntimeError, "Only one version my be specified for --hive-script"
        end
      end
      return ["--hive-versions", versions]
    end
    
  end
  
  class HiveSiteCommand < HiveCommand

    def steps
      step = {
        "Name"            => get_field(:step_name, "Install Hive Site Configuration"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:script_runner_path),
          "Args" => get_field(:hive_cmd) + [ "--install-hive-site", "--hive-site=#{@arg}" ] +
            extra_args + get_version_args(true)
        }
      }
      return [ step ]
    end

    def reorder_steps(jobflow, sc)
      return ensure_install_cmd(jobflow, sc, HiveInteractiveCommand)
    end
  end

  class HiveScriptCommand < HiveCommand
    
    def steps
      mandatory_args = [ "--run-hive-script", "--args", "-f" ]
      if @arg then
        mandatory_args << @arg
      end
      step = {
        "Name"            => get_field(:step_name, "Run Hive Script"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:script_runner_path),
          "Args" => get_field(:hive_cmd) + get_version_args(true) + mandatory_args + @args
        }
      }
      [ step ]
    end

    def reorder_steps(jobflow, sc)
      return ensure_install_cmd(jobflow, sc, HiveInteractiveCommand)
    end
  end

  class HiveInteractiveCommand < HiveCommand
    
    def steps
      step = {
        "Name"            => get_field(:step_name, "Setup Hive"),
        "ActionOnFailure" => get_field(:step_action, "TERMINATE_JOB_FLOW"),
        "HadoopJarStep"   => {
          "Jar" => get_field(:script_runner_path),
          "Args" => get_field(:hive_cmd) + [ "--install-hive" ] + 
            get_version_args(false) + extra_args
        }
      }
      [ step ]
    end

    def jobflow_has_install_step(jobflow)
      install_steps = jobflow['Steps'].select do |step|
        step["ExecutionStatusDetail"]["State"] != "FAILED" &&
        has_value(step, 'StepConfig', 'HadoopJarStep', 'Jar', get_field(:script_runner_path)) &&
        has_value(step, 'StepConfig', 'HadoopJarStep', 'Args', 3, "--install-hive") &&
        has_value(step, 'StepConfig', 'HadoopJarStep', 'Args', 5, get_version_args(true)[1])
      end
      return install_steps.size > 0
    end

    def self.new_from_commands(commands, parent)
      sc = self.new("--hive-interactive", "Run a jobflow with Hive Installed", nil, commands)
      sc.hive_versions = parent.hive_versions
      sc.step_action = parent.step_action
      return sc
    end
  end

  class JarStepCommand < StepCommand
    attr_accessor :main_class

    def steps
      step = {
        "Name"            => get_field(:step_name, "Example Jar Step"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar"  => get_field(:arg),
          "Args" => get_field(:args, [])
        }
      }
      if get_field(:main_class) then
        step["HadoopJarStep"]["MainClass"] = get_field(:main_class) 
      end
      return [ step ]
    end
  end

  class StreamStepCommand < StepCommand
    attr_accessor :input, :output, :mapper, :cache, :cache_archive, :jobconf, :reducer, :args

    GENERIC_OPTIONS = Set.new(%w(-conf -D -fs -jt -files -libjars -archives))

    def initialize(*args)
      super(*args)
      @jobconf = []
    end

    def steps    
      if get_field(:input) == nil ||
         get_field(:output) == nil ||
         get_field(:mapper) == nil ||
         get_field(:reducer) == nil then
        raise RuntimeError, "Missing arguments for --stream option"  
      end 
      
      timestr = Time.now.strftime("%Y-%m-%dT%H%M%S")
      stream_options = []
      for ca in get_field(:cache, []) do
        stream_options << "-cacheFile" << ca
      end
      
      for ca in get_field(:cache_archive, []) do
        stream_options << "-cacheArchive" << ca
      end
      
      for jc in get_field(:jobconf, []) do
        stream_options << "-jobconf" << jc
      end        
         
      # Note that the streaming options should go before command options for
      # Hadoop 0.20
      step = {
        "Name"            => get_field(:step_name, "Example Streaming Step"),
        "ActionOnFailure" => get_field(:step_action, "CANCEL_AND_WAIT"),
        "HadoopJarStep"   => {
          "Jar" => "/home/hadoop/contrib/streaming/hadoop-streaming.jar",
          "Args" => (sort_streaming_args(get_field(:args))) + (stream_options) + [
            "-input",     get_field(:input),
            "-output",    get_field(:output),
            "-mapper",    get_field(:mapper),
            "-reducer",   get_field(:reducer)
          ]
        }
      }
      return [ step ]
    end

    def sort_streaming_args(streaming_args)
      sorted_streaming_args = []
      i=0
      while streaming_args && i < streaming_args.length
        if GENERIC_OPTIONS.include?(streaming_args[i]) then
          if i+1 < streaming_args.length
            sorted_streaming_args.unshift(streaming_args[i+1])
            sorted_streaming_args.unshift(streaming_args[i])
            i=i+2
          else
            raise RuntimeError, "Missing value for argument #{streaming_args[i]}"
          end
        else
          sorted_streaming_args << streaming_args[i]
          i=i+1
        end
      end
      return sorted_streaming_args
    end
  end

  class AbstractSSHCommand < Command
    attr_accessor :no_wait, :dest, :hostname, :key_pair_file, :jobflow_id, :jobflow_detail
    attr_accessor :cmd, :ssh_opts, :scp_opts

    CLOSED_DOWN_STATES        = Set.new(%w(TERMINATED SHUTTING_DOWN COMPLETED FAILED))
    WAITING_OR_RUNNING_STATES = Set.new(%w(WAITING RUNNING))

    def initialize(*args)
      super(*args)
      @ssh_opts = ["-o ServerAliveInterval=10", "-o StrictHostKeyChecking=no"]
      @scp_opts = ["-r", "-o StrictHostKeyChecking=no"]
    end  

    def opts
      (get_field(:ssh_opts, []) + get_field(:scp_opts, [])).join(" ")
    end

    def get_ssh_opts
      get_field(:ssh_opts, []).join(" ")
    end

    def get_scp_opts
      get_field(:scp_opts, []).join(" ")
    end

    def exec(cmd)
      commands.exec(cmd)
    end

    def wait_for_jobflow(client)
      while true do
        state = resolve(self.jobflow_detail, "ExecutionStatusDetail", "State")
        if WAITING_OR_RUNNING_STATES.include?(state) then
          break
        elsif CLOSED_DOWN_STATES.include?(state) then
          raise RuntimeError, "Jobflow entered #{state} while waiting to ssh"
        else
          logger.info("Jobflow is in state #{state}, waiting....")
          sleep(30)
          self.jobflow_detail = client.describe_jobflow_with_id(jobflow_id)
        end
      end
    end

    def enact(client)
      self.jobflow_id = require_single_jobflow
      self.jobflow_detail = client.describe_jobflow_with_id(self.jobflow_id)
      if ! get_field(:no_wait) then
        wait_for_jobflow(client)
      end
      self.hostname = self.jobflow_detail['Instances']['MasterPublicDnsName']
      self.key_pair_file = require(:key_pair_file, "Missing required option --key-pair-file for #{name}")
    end
  end

  class SSHCommand < AbstractSSHCommand
    attr_accessor :cmd, :ssh_opts, :scp_opts
    
    def initialize(*args)
      super(*args)
      if @arg =~ /j-[A-Z0-9]{8,20}/ then
        commands.global_options[:jobflow] << @arg
      else
        self.cmd = @arg
      end
    end

    def enact(client)
      super(client)
      exec "ssh #{get_ssh_opts} -i #{key_pair_file} hadoop@#{hostname} #{get_field(:cmd, "")}"
    end
  end

  class PutCommand < AbstractSSHCommand
    attr_accessor :scp_opts
    
    def initialize(*args)
      super(*args)
    end
    
    def enact(client)
      super(client)
      if get_field(:dest) then
        exec "scp #{get_scp_opts} -i #{key_pair_file} #{@arg} hadoop@#{hostname}:#{get_field(:dest)}"
      else
        exec "scp #{get_scp_opts} -i #{key_pair_file} #{@arg} hadoop@#{hostname}:#{File.basename(@arg)}"
      end
    end
  end

  class GetCommand < AbstractSSHCommand
    attr_accessor :scp_opts
    
    def initialize(*args)
      super(*args)
    end
    
    def enact(client)
      super(client)
      if get_field(:dest) then
        exec "scp #{self.get_scp_opts} -i #{key_pair_file} hadoop@#{hostname}:#{@arg} #{get_field(:dest)}"
      else
        exec "scp #{self.get_scp_opts} -i #{key_pair_file} hadoop@#{hostname}:#{@arg} #{File.basename(@arg)}"
      end
    end
  end

  class SocksCommand < AbstractSSHCommand
    def enact(client)
      super(client)
      exec "ssh #{self.get_ssh_opts} -i #{key_pair_file} -ND 8157 hadoop@#{hostname}"
    end
  end

  class PrintHiveVersionCommand < AbstractSSHCommand
    def enact(client)
      super(client)
      stdin, stdout, stderr = Open3.popen3("ssh -i #{key_pair_file} hadoop@#{hostname} '/home/hadoop/bin/hive -version'")
      version = stdout.readlines.join
      err = stderr.readlines.join
      if version.length > 0
        puts version
      elsif err =~ /Unrecognised option/ or err =~ /Error while determing Hive version/
        stdin, stdout, stderr = Open3.popen3("ssh -i #{key_pair_file} hadoop@#{hostname} 'ls -l /home/hadoop/bin/hive'")
        version = stdout.readlines.join
        version =~ /hive-(.*)\/bin\/hive/
        puts "Hive version " + $1
      else
        puts "Unable to determine Hive version"
      end
    end
  end
  
  class LogsCommand < AbstractSSHCommand
    attr_accessor :step_index

    INTERESTING_STEP_STATES = ['RUNNING', 'COMPLETED', 'FAILED']

    def enact(client)
      super(client)

      # find the last interesting step if that exists
      if get_field(:step_index) == nil then
        steps = resolve(jobflow_detail, "Steps")
        self.step_index = (0 ... steps.size).select { |index| 
          INTERESTING_STEP_STATES.include?(resolve(steps, index, 'ExecutionStatusDetail', 'State'))
        }.last + 1
      end

      if get_field(:step_index) then
        logger.puts "Listing steps for step #{get_field(:step_index)}"
        exec "ssh -i #{key_pair_file} hadoop@#{hostname} cat /mnt/var/log/hadoop/steps/#{get_field(:step_index)}/{syslog,stderr,stdout}"
      else
        raise RuntimeError, "No steps that could have logs found in jobflow"
      end
    end
  end

  class GlobalOption < CommandOption
    def attach(commands)
      global_options = @commands.global_options
      value = global_options[@field_symbol]
      if value.is_a?(Array) then
        value << @arg
      elsif value == nil then
        global_options[@field_symbol] = @arg
      else
        raise RuntimeError, "You may not specify #{@name} twice"
      end
      return nil
    end
  end

  class GlobalFlagOption < CommandOption
    def attach(command)
      global_options = @commands.global_options
      value = global_options[@field_symbol]
      if value == nil then
        global_options[@field_symbol] = @arg
      else
        raise RuntimeError, "You may not specify #{@name} twice"
      end
    end
  end
  
  class WaitForStepsCommand < Command
    attr_accessor :jobflow_id, :jobflow_detail
    
    def all_steps_terminated(client)
      self.jobflow_detail = client.describe_jobflow_with_id(self.jobflow_id)
      steps = resolve(self.jobflow_detail, "Steps")
      
      if steps.empty? != true && ["PENDING", "RUNNING"].include?(steps.last["ExecutionStatusDetail"]["State"])
        logger.info("Last step #{steps.last["StepConfig"]["Name"]} is in state #{steps.last["ExecutionStatusDetail"]["State"]}, waiting....")
        return false
      end
      
      return true
    end
  
    def enact(client)
      self.jobflow_id = require_single_jobflow
      
      while ! all_steps_terminated(client) do
        sleep(30)
      end
    end
  end

  class StepProcessingCommand < Command
    attr_accessor :step_commands

    def initialize(*args)
      super(*args)
      @step_commands = []
    end

    def reorder_steps(jobflow, sc)
      new_step_commands = sc.dup
      for step_command in sc do
        new_step_commands = step_command.reorder_steps(jobflow, new_step_commands)
      end

      return new_step_commands
    end
  end

  class AddJobFlowStepsCommand < StepProcessingCommand

    def add_step_command(step)
      @step_commands << step
    end

    def validate
      for cmd in step_commands do
        cmd.validate
      end
    end

    def enact(client)
      jobflow_id = require_single_jobflow
      jobflow = client.describe_jobflow_with_id(jobflow_id)
      self.step_commands = reorder_steps(jobflow, self.step_commands)
      jobflow_steps = step_commands.map { |x| x.steps }.flatten
      client.add_steps(jobflow_id, jobflow_steps)
      logger.puts("Added jobflow steps")
    end
  end

  class CreateJobFlowCommand < StepProcessingCommand
    attr_accessor :jobflow_name, :alive, :with_termination_protection, :instance_count, :slave_instance_type, 
      :master_instance_type, :key_pair, :key_pair_file, :log_uri, :az, :ainfo, :ami_version, :with_supported_products,
      :hadoop_version, :plain_output, :instance_type,
      :instance_group_commands, :bootstrap_commands, :subnet_id


    OLD_OPTIONS = [:instance_count, :slave_instance_type, :master_instance_type]
    # FIXME: add code to setup collapse instance group commands

    def default_hadoop_version
      if get_field(:ami_version) == "1.0" then
        "0.20"     
      end
    end

    def initialize(*args)
      super(*args)
      @instance_group_commands = []
      @bootstrap_commands = []
    end

    def add_step_command(step)
      @step_commands << step
    end

    def add_bootstrap_command(bootstrap_command)
      @bootstrap_commands << bootstrap_command
    end

    def add_instance_group_command(instance_group_command)
      @instance_group_commands << instance_group_command
    end

    def validate
      for step in step_commands do
        if step.is_a?(EnableDebuggingCommand) then
          require(:log_uri, "You must supply a logUri if you enable debugging when creating a job flow")
        end
      end

      for cmd in step_commands + instance_group_commands + bootstrap_commands do
        cmd.validate
      end

    end

    def enact(client)
      @jobflow = create_jobflow

      apply_jobflow_option(:ainfo, "AdditionalInfo")
      apply_jobflow_option(:key_pair, "Instances", "Ec2KeyName")
      apply_jobflow_option(:hadoop_version, "Instances", "HadoopVersion")
      apply_jobflow_option(:az, "Instances", "Placement", "AvailabilityZone")
      apply_jobflow_option(:log_uri, "LogUri")
      apply_jobflow_option(:ami_version, "AmiVersion")
      apply_jobflow_option(:subnet_id, "Instances", "Ec2SubnetId")
 
      @jobflow["AmiVersion"] ||= "latest"

      self.step_commands = reorder_steps(@jobflow, self.step_commands)
      @jobflow["Steps"] = step_commands.map { |x| x.steps }.flatten

      setup_instance_groups
      @jobflow["Instances"]["InstanceGroups"] = instance_group_commands.map { |x| x.instance_group }
      bootstrap_action_index = 1
      if @jobflow["SupportedProducts"] then
        for product in @jobflow["SupportedProducts"] do
          if product[0..4] == 'mapr-' then
            action = {
              "Name" => "Install " + product,
              "ScriptBootstrapAction" => {
                "Path" => File.join(get_field(:apps_path), "thirdparty/mapr/scripts/mapr_emr_install.sh"),
                "Args" => ["--base-path", File.join(get_field(:apps_path), "thirdparty/mapr")]
              }
            }
            @jobflow["BootstrapActions"] << action
            bootstrap_action_index += 1
            break
          end
        end
      end

      for bootstrap_action_command in bootstrap_commands do
        if bootstrap_action_command.respond_to?(:modify_jobflow) then
          bootstrap_action_command.modify_jobflow(@jobflow)
        end
        actions = bootstrap_action_command.bootstrap_actions(bootstrap_action_index)
        for action in actions do
          @jobflow["BootstrapActions"] << action
          bootstrap_action_index += 1
        end
      end

      run_result = client.run_jobflow(@jobflow)
      jobflow_id = run_result['JobFlowId']
      commands.global_options[:jobflow] << jobflow_id 

      if have(:plain_output) then
        logger.puts jobflow_id
      else
        logger.puts "Created job flow " + jobflow_id
      end
    end

    def apply_jobflow_option(field_symbol, *keys)
      value = get_field(field_symbol)
      if value != nil then 
        map = @jobflow
        for key in keys[0..-2] do
          nmap = map[key]
          if nmap == nil then
            map[key] = {}
            nmap = map[key]
          end
          map = nmap
        end
        map[keys.last] = value
      end
    end

    def new_instance_group_command(role, instance_count, instance_type)
      igc = CreateInstanceGroupCommand.new(
        "--instance-group ROLE", "Specify an instance group", role, commands
      )
      igc.instance_count = instance_count
      igc.instance_type = instance_type
      return igc
    end

    def have_role(instance_group_commands, role)
      instance_group_commands.select { |x| 
        x.instance_role.upcase == role 
      }.size > 0
    end

    def setup_instance_groups
      instance_groups = []
      if ! have_role(instance_group_commands, "MASTER") then
        mit = get_field(:master_instance_type, get_field(:instance_type, "m1.small"))
        master_instance_group = new_instance_group_command("MASTER", 1, mit)
        instance_group_commands << master_instance_group
      end
      if ! have_role(instance_group_commands, "CORE") then
        ni = get_field(:instance_count, 1).to_i
        if ni > 1 then
          sit = get_field(:slave_instance_type, get_field(:instance_type, "m1.small"))
          slave_instance_group = new_instance_group_command("CORE", ni-1, sit)
          slave_instance_group.instance_role = "CORE"
          instance_group_commands << slave_instance_group
        end
      else
        # Verify that user has not specified both --instance-group core and --num-instances
        if get_field(:instance_count) != nil then
          raise RuntimeError, "option --num-instances cannot be used when a core instance group is specified."
        end
      end
    end

    def create_jobflow
      @jobflow = {
        "Name"   => get_field(:jobflow_name, default_job_flow_name),
        "Instances" => {
          "KeepJobFlowAliveWhenNoSteps" => (get_field(:alive) ? "true" : "false"),
          "TerminationProtected"        => (get_field(:with_termination_protection) ? "true" : "false"),
          "InstanceGroups" => []
        },
        "Steps" => [],
        "BootstrapActions" => []
      }
      products_string = get_field(:with_supported_products)
      if products_string then
        products = products_string.split(/,/).map { |s| s.strip }
        @jobflow["SupportedProducts"] = products
      end
      @jobflow
    end

    def default_job_flow_name
      name = "Development Job Flow"
      if get_field(:alive) then
        name += " (requires manual termination)"
      end
      return name
    end
  end

  class BootstrapActionCommand < Command
    attr_accessor :bootstrap_name, :args

    def initialize(*args)
      super(*args)
      @args = []
    end

    def bootstrap_actions(index)
      action = {
        "Name" => get_field(:bootstrap_name, "Bootstrap Action #{index}"),
        "ScriptBootstrapAction" => {
          "Path" => @arg,
          "Args" => @args
        }
      }
      return [ action ]
    end
  end

  class AbstractListCommand < Command
    attr_accessor :state, :max_results, :active, :all, :no_steps, :created_after, :created_before

    def enact(client)
      options = {}
      states = []
      if get_field(:jobflow, []).size > 0 then
        options = { 'JobFlowIds' => get_field(:jobflow) }
      else 
        if get_field(:active) then
          states = %w(RUNNING SHUTTING_DOWN STARTING WAITING BOOTSTRAPPING)
        end
        if get_field(:state) then
          states << get_field(:state)
        end

        if get_field(:all) then
          options = { 'CreatedAfter' => (Time.now - (58 * 24 * 3600)).xmlschema }
        else
          options = {}
          options['CreatedAfter']  = get_field(:created_after) if get_field(:created_after)
          options['CreatedBefore'] = get_field(:created_before) if get_field(:created_before)
          options['JobFlowStates'] = states if states.size > 0
        end
      end
      result = client.describe_jobflow(options)
      # add the described jobflow to the supplied jobflows
      commands.global_options[:jobflow] += result['JobFlows'].map { |x| x['JobFlowId'] }
      commands.global_options[:jobflow].uniq!

      return result
    end
  end

  class ListActionCommand < AbstractListCommand

    def format(map, *fields)
      result = []
      for field in fields do
        key = field[0].split(".")
        value = map
        while key.size > 0 do
          value = value[key.first]
          key.shift
        end
        result << sprintf("%-#{field[1]}s", value)
      end
      result.join("")
    end

    def enact(client)
      result = super(client)
      job_flows = result['JobFlows']
      count = 0
      for job_flow in job_flows do 
        if get_field(:max_results) && (count += 1) > get_field(:max_results) then
          break
        end
        logger.puts format(job_flow, ['JobFlowId', 20], ['ExecutionStatusDetail.State', 15], 
                    ['Instances.MasterPublicDnsName', 50]) + job_flow['Name']
        if ! get_field(:no_steps) then
          for step in job_flow['Steps'] do
            logger.puts "   " + format(step, ['ExecutionStatusDetail.State', 15], ['StepConfig.Name', 30])
          end
        end
      end
    end
  end

  class DescribeActionCommand < AbstractListCommand
    def enact(client)
      result = super(client)
      logger.puts(JSON.pretty_generate(result))
    end
  end

  class SetTerminationProtection < Command
    def enact(client)
      job_flow = get_field(:jobflow)
      termination_protected = @arg == 'true'
      client.set_termination_protection(job_flow, termination_protected)
      logger.puts "#{termination_protected ? "Disabled":"Enabled"} job flow termination " +  job_flow.join(" ")
    end
  end
  
  class TerminateActionCommand < Command
    def enact(client)
      job_flow = get_field(:jobflow)
      client.terminate_jobflows(job_flow)
      logger.puts "Terminated job flow " +  job_flow.join(" ")
    end
  end

  class VersionCommand < Command
    def enact(client)
      logger.puts "Version #{ELASTIC_MAPREDUCE_CLIENT_VERSION}"
    end
  end

  class HelpCommand < Command
    def enact(client)
      logger.puts commands.opts
    end
  end

  class ArgsOption < CommandOption
    def attach(commands)
      command = super(commands)
      command.args += @arg.split(",")
      return command
    end
  end

  class ArgOption < CommandOption
    def attach(commands)
      command = super(commands)
      command.args << @arg
      return command
    end
  end

  class AbstractInstanceGroupCommand < Command
    attr_accessor :instance_group_id, :instance_type, :instance_role, 
      :instance_count, :instance_group_name, :bid_price

    def initialize(*args)
      super(*args)
      if @arg =~ /^ig-/ then
        @instance_group_id = @arg
      else
        @instance_role = @arg.upcase
      end
    end

    def default_instance_group_name
      get_field(:instance_role).downcase.capitalize + " Instance Group"
    end

    def instance_group
      ig =  {
        "Name" => get_field(:instance_group_name),
        "InstanceRole" => get_field(:instance_role),
        "InstanceCount" => get_field(:instance_count),
        "InstanceType"  => get_field(:instance_type)
      }
      if get_field(:bid_price, nil) != nil
        ig["BidPrice"] = get_field(:bid_price)
        ig["Market"] = "SPOT"
      else
        ig["Market"] = "ON_DEMAND"
      end
      return ig
    end

    def require_singleton_array(arr, msg)
      if arr.size != 1 then
        raise RuntimeError, "Expected to find one " + msg + " but found #{arr.size}."
      end
    end

  end

  class AddInstanceGroupCommand < AbstractInstanceGroupCommand
    def validate
      if ! ["TASK"].include?(get_field(:instance_role)) then
        raise RuntimeError, "Invalid argument to #{name}, expected 'task'"
      end
      require(:instance_type, "Option #{name} is missing --instance-type")
      require(:instance_count, "Option #{name} is missing --instance-count")
    end

    def enact(client)
      client.add_instance_groups(
        'JobFlowId' => require_single_jobflow, 'InstanceGroups' => [instance_group]
      )
      logger.puts("Added instance group " + get_field(:instance_role))
    end
  end

  class CreateInstanceGroupCommand < AbstractInstanceGroupCommand
    def validate
      if ! ["MASTER", "CORE", "TASK"].include?(get_field(:instance_role)) then
        raise RuntimeError, "Invalid argument to #{name}, expected master, core or task"
      end
      require(:instance_type, "Option #{name} is missing --instance-type")
      require(:instance_count, "Option #{name} is missing --instance-count")
    end
  end

  class ModifyInstanceGroupCommand < AbstractInstanceGroupCommand
    attr_accessor :jobflow_detail, :jobflow_id

    def validate
      if get_field(:instance_group_id) == nil then
        if ! ["CORE", "TASK"].include?(get_field(:instance_role)) then
          raise RuntimeError, "Invalid argument to #{name}, #{@arg} is not valid"
        end
        if get_field(:jobflow, []).size == 0 then
          raise RuntimeError, "You must specify a jobflow when using #{name} and specifying a role #{instance_role}"
        end          
      end
      require(:instance_count, "Option #{name} is missing --instance-count")
    end

    def enact(client)
      if get_field(:instance_group_id) == nil then
        self.jobflow_id = require_single_jobflow
        self.jobflow_detail = client.describe_jobflow_with_id(self.jobflow_id)
        matching_instance_groups = 
          jobflow_detail['Instances']['InstanceGroups'].select { |x| x['InstanceRole'] == instance_role }
        require_singleton_array(matching_instance_groups, "instance group with role #{instance_role}")
        self.instance_group_id = matching_instance_groups.first['InstanceGroupId']
      end
      options = {
        'InstanceGroups' => [{ 
          'InstanceGroupId' => get_field(:instance_group_id), 
          'InstanceCount' => get_field(:instance_count) 
        }]
      }
      client.modify_instance_groups(options)
      ig_modified = nil
      if get_field(:instance_role) != nil then
        ig_modified = get_field(:instance_role)
      else
        ig_modified = get_field(:instance_group_id)
      end
      logger.puts("Modified instance group " + ig_modified)
    end
  end

  class UnarrestInstanceGroupCommand < AbstractInstanceGroupCommand

    attr_accessor :jobflow_id, :jobflow_detail

    def validate
      require_single_jobflow
      if get_field(:instance_group_id) == nil then
        if ! ["CORE", "TASK"].include?(get_field(:instance_role)) then
          raise RuntimeError, "Invalid argument to #{name}, #{@arg} is not valid"
        end
      end
    end

    def enact(client)
      self.jobflow_id = require_single_jobflow
      self.jobflow_detail = client.describe_jobflow_with_id(self.jobflow_id)

      matching_instance_groups = nil
      if get_field(:instance_group_id) == nil then
        matching_instance_groups = 
          jobflow_detail['Instances']['InstanceGroups'].select { |x| x['InstanceRole'] == instance_role }
      else
        matching_instance_groups = 
          jobflow_detail['Instances']['InstanceGroups'].select { |x| x['InstanceGroupId'] == get_field(:instance_group_id) }
      end

      require_singleton_array(matching_instance_groups, "instance group with role #{instance_role}")
      instance_group_detail = matching_instance_groups.first
        self.instance_group_id = instance_group_detail['InstanceGroupId']
        self.instance_count = instance_group_detail['InstanceRequestCount']
      
      options = {
        'InstanceGroups' => [{ 
          'InstanceGroupId' => get_field(:instance_group_id), 
          'InstanceCount' => get_field(:instance_count) 
        }]
      }
      client.modify_instance_groups(options)
      logger.puts "Unarrested instance group #{get_field(:instance_group_id)}."
    end
  end

  class InstanceCountOption < CommandOption
    def attach(commands)
      command = super(commands)
      command.instance_count = @arg.to_i
      return command
    end
  end

  class InstanceTypeOption < CommandOption
    def attach(commands)
      command = super(commands)
      command.instance_type = @arg
      return command
    end
  end

  class OptionWithArg < CommandOption
    def attach(commands)
      command = super(commands)
      if @pattern && ! @arg.match(@pattern) then
        raise RuntimeError, "Expected argument to #{@name} to match #{@pattern.inspect}, but it didn't"
      end
      command.option(@name, @field_symbol, @arg)
      return command
    end
  end

  class FlagOption < CommandOption
    
    def initialize(name, description, arg, parent_commands, commands, field_symbol)
      super(name, description, arg, parent_commands, commands)
      @field_symbol = field_symbol
    end

    def attach(commands)
      command = super(commands)
      command.option(@name, @field_symbol, true)
    end
  end

  class JsonStepCommand < StepCommand
    attr_accessor :variables

    def initialize(*args)
      super(*args)
      @variables = []
    end

    def steps
      content = steps = nil
      filename = get_field(:arg)
      begin
        content = File.read(filename)
      rescue Exception => e
        raise RuntimeError, "Couldn't read json file #{filename}"
      end
      for var in get_field(:variables, []) do
        content.gsub!(var[:key], var[:value])
      end
      begin
        steps = JSON.parse(content)
      rescue Exception => e
        raise RuntimeError, "Error parsing json from file #{filename}"
      end
      if steps.is_a?(Array) then
        return steps
      else
        return [ steps ]
      end      
    end
  end

  class ParamOption < CommandOption
    def initialize(*args)
      super(*args)
      @params = []
    end

    def attach(commands)
      command = super(commands)
      if match = @arg.match(/([^=]+)=(.*)/) then
        command.option(@name, @field_symbol, { :key => match[1], :value => match[2] })
      else
        raise RuntimeError, "Expected '#{@arg}' to be in the form VARIABLE=VALUE"
      end
      return command
    end
  end

  class EipCommand < Command
    attr_accessor :no_wait, :instance_id, :key_pair_file, :jobflow_id, :jobflow_detail

    CLOSED_DOWN_STATES        = Set.new(%w(TERMINATED SHUTTING_DOWN COMPLETED FAILED))
    WAITING_OR_RUNNING_STATES = Set.new(%w(WAITING RUNNING))

    def initialize(*args)
      super(*args)
    end

    def exec(cmd)
      commands.exec(cmd)
    end

    def wait_for_jobflow(client)
      while true do
        state = resolve(self.jobflow_detail, "ExecutionStatusDetail", "State")
        if WAITING_OR_RUNNING_STATES.include?(state) then
          break
        elsif CLOSED_DOWN_STATES.include?(state) then
          raise RuntimeError, "Jobflow entered #{state} while waiting to assign Elastic IP"
        else
          logger.info("Jobflow is in state #{state}, waiting....")
          sleep(30)
          self.jobflow_detail = client.describe_jobflow_with_id(jobflow_id)
        end
      end
    end

    def region_from_az(az)
      md = az.match(/((\w+-)+\d+)\w+/)
      if md then
        md[1]
      else
        raise "Unable to convert Availability Zone '#{az}' to region"
      end
    end

    def ec2_endpoint_from_az(az)
      return "https://ec2.#{region_from_az(az)}.amazonaws.com"      
    end

    def enact(client)
      self.jobflow_id = require_single_jobflow
      self.jobflow_detail = client.describe_jobflow_with_id(self.jobflow_id)
      if ! get_field(:no_wait) then
        wait_for_jobflow(client)
      end
      self.instance_id = self.jobflow_detail['Instances']['MasterInstanceId']
      if ! self.instance_id then
        logger.error("The master instance is not available yet for jobflow #{self.jobflow_id}. It might still be starting.")
        exit(-1)
      end

      az = self.jobflow_detail['Instances']['Placement']['AvailabilityZone']

      commands.global_options[:ec2_endpoint] = ec2_endpoint_from_az(az)
      
      self.key_pair_file = require(:key_pair_file, "Missing required option --key-pair-file for #{name}")
      eip = get_field(:arg)

      ec2_client = Ec2ClientWrapper.new(commands, logger)

      if ! eip then
        begin
          response = ec2_client.allocate_address()
        rescue Exception => e
          logger.error("Error during AllocateAddres: " + e.message)
          if get_field(:trace) then
            logger.puts(e.backtrace.join("\n"))
          end
          exit(-1)
        end

        eip = response['publicIp']
        logger.info("Allocated Public IP: #{eip}...")
      end

      begin
        response = ec2_client.associate_address(self.instance_id, eip)
        logger.info("Public IP: #{eip} was assigned to jobflow #{self.jobflow_id}")
      rescue Exception => e
        logger.error("Error during AssociateAddres: " + e.to_s)
        if get_field(:trace) then
          logger.puts(e.backtrace.join("\n"))
        end
        exit(-1)
      end

    end
  end

  def self.add_commands(commands, opts)

    commands.opts = opts

    step_commands = ["--jar", "--resize-jobflow", "--enable-debugging", "--hive-interactive", "--pig-interactive", "--hive-script", "--pig-script", "--hive-site", "--script"]

    opts.separator "\n  Creating Job Flows\n"

    commands.parse_command(CreateJobFlowCommand, "--create", "Create a new job flow")
    commands.parse_options(["--create"], [
      [ OptionWithArg, "--name NAME",                 "The name of the job flow being created", :jobflow_name ],
      [ FlagOption,    "--alive",                     "Create a job flow that stays running even though it has executed all its steps", :alive ],
      [ OptionWithArg, "--with-termination-protection",   "Create a job with termination protection (default is no termination protection)", :with_termination_protection ],
      [ OptionWithArg, "--with-supported-products PRODUCTS",   "Add supported products", :with_supported_products ],
      [ OptionWithArg, "--num-instances NUM",         "Number of instances in the job flow", :instance_count ],
      [ OptionWithArg, "--slave-instance-type TYPE",  "The type of the slave instances to launch", :slave_instance_type ],
      [ OptionWithArg, "--master-instance-type TYPE", "The type of the master instance to launch", :master_instance_type ],
      [ OptionWithArg, "--ami-version VERSION",       "The version of ami to launch the job flow with", :ami_version ],
      [ OptionWithArg, "--key-pair KEY_PAIR",         "The name of your Amazon EC2 Keypair", :key_pair ], 
      [ OptionWithArg, "--availability-zone A_Z",     "Specify the Availability Zone in which to launch the job flow", :az ],
      [ OptionWithArg, "--info INFO",                 "Specify additional info to job flow creation", :ainfo ],
      [ OptionWithArg, "--hadoop-version VERSION",    "Specify the Hadoop Version to install", :hadoop_version ],
      [ FlagOption,    "--plain-output",              "Return the job flow id from create step as simple text", :plain_output ],
      [ OptionWithArg, "--subnet EC2-SUBNET_ID",      "Specify the VPC subnet that you want to run in", :subnet_id ],
    ])
    commands.parse_command(CreateInstanceGroupCommand, "--instance-group ROLE", "Specify an instance group while creating a jobflow")
    commands.parse_options(["--instance-group", "--add-instance-group"], [
      [OptionWithArg, "--bid-price PRICE",        "The bid price for this instance group", :bid_price]
    ])

    opts.separator "\n  Passing arguments to steps\n"
    
    commands.parse_options(step_commands + ["--bootstrap-action", "--stream"], [
      [ ArgsOption,    "--args ARGS",                 "A command separated list of arguments to pass to the step" ],
      [ ArgOption,     "--arg ARG",                   "An argument to pass to the step" ],
      [ OptionWithArg, "--step-name STEP_NAME",       "Set name for the step", :step_name ],
      [ OptionWithArg, "--step-action STEP_ACTION",   "Action to take when step finishes. One of CANCEL_AND_WAIT, TERMINATE_JOB_FLOW or CONTINUE", :step_action ], 
    ])

    opts.separator "\n  Specific Steps\n"

    commands.parse_command(ResizeJobflowCommand, "--resize-jobflow",     "Add a step to resize the job flow")
    commands.parse_command(EnableDebuggingCommand, "--enable-debugging", "Enable job flow debugging (you must be signed up to SimpleDB for this to work)")
    commands.parse_command(WaitForStepsCommand, "--wait-for-steps",     "Wait for all steps to reach a terminal state")
    commands.parse_command(ScriptCommand, "--script SCRIPT_PATH",      "Add a step that runs a script in S3")

    opts.separator "\n  Adding Steps from a Json File to Job Flows\n"

    commands.parse_command(JsonStepCommand, "--json FILE", "Add a sequence of steps stored in the json file FILE")
    commands.parse_options(["--json"], [
      [ ParamOption, "--param VARIABLE=VALUE ARGS", "Substitute the string VARIABLE with the string VALUE in the json file", :variables ],
    ])

    opts.separator "\n  Pig Steps\n"

    commands.parse_command(PigScriptCommand,      "--pig-script [SCRIPT]",
                           "Add a step that runs a Pig script")
    commands.parse_command(PigInteractiveCommand, "--pig-interactive",
                           "Add a step that sets up the job flow for an interactive (via SSH) pig session")
    commands.parse_options(["--pig-script", "--pig-interactive"], [
      [ OptionWithArg, "--pig-versions VERSIONS",
        "A comma separated list of Pig versions", :pig_versions ],
    ])


    opts.separator "\n  Hive Steps\n"

    commands.parse_command(HiveScriptCommand, "--hive-script [SCRIPT]",      "Add a step that runs a Hive script")
    commands.parse_command(HiveInteractiveCommand, "--hive-interactive", "Add a step that sets up the job flow for an interactive (via SSH) hive session")
    commands.parse_command(HiveSiteCommand, "--hive-site HIVE_SITE", "Override Hive configuration with configuration from HIVE_SITE")
    commands.parse_options(["--hive-script", "--hive-interactive", "--hive-site"], [
      [ OptionWithArg,     "--hive-versions VERSIONS", "A comma separated list of Hive versions", :hive_versions]
    ])
    
    opts.separator "\n  HBase Options\n"

    commands.parse_command(HBaseInstall,         "--hbase",                      "Install HBase on the cluster")
    commands.parse_command(HBaseBackup,          "--hbase-backup",               "Backup HBase to S3")
    commands.parse_command(HBaseRestore,         "--hbase-restore",              "Restore HBase from S3")
    commands.parse_command(HBaseBackupSchedule,  "--hbase-schedule-backup",      "Schedule regular backups to S3")

    commands.parse_options(["--hbase-backup", "--hbase-restore", "--hbase-schedule-backup"], [
      [ OptionWithArg, "--backup-dir DIRECTORY", "Location where backup is stored", :backup_dir]
    ])

    commands.parse_options(["--hbase-backup", "--hbase-schedule-backup"], [
      [ FlagOption, "--consistent", "Perform a consistent backup (inconsistent is default)", :consistent]
    ])
    
    commands.parse_options(["--hbase-backup", "--hbase-restore"], [
      [ OptionWithArg, "--backup-version VERSION", "Backup version to restore", :backup_version ]
    ])
    
    commands.parse_options(["--hbase-schedule-backup"], [
      [ OptionWithArg, "--full-backup-time-interval  TIME_INTERVAL", "The time between full backups",                :full_backup_time_interval],
      [ OptionWithArg, "--full-backup-time-unit      TIME_UNIT",         
                "time units for full backup's time-interval either minutes, hours or days",                          :full_backup_time_unit],
      [ OptionWithArg, "--start-time START_TIME",       "The time of the first backup",                              :start_time],
      [ FlagOption, "--disable-full-backups",                     "Stop scheduled full backups from running",     :disable_full_backups],
      [ OptionWithArg, "--incremental-backup-time-interval TIME_INTERVAL", "The time between incremental backups",   :incremental_time_interval],
      [ OptionWithArg, "--incremental-backup-time-unit TIME_UNIT", 
                "time units for incremental backup's time-interval either minutes, hours or days",                   :incremental_time_unit],
      [ FlagOption, "--disable-incremental-backups",       "Stop scheduled incremental backups from running",     :disable_incremental_backups],
    ])
    
    opts.separator "\n  Adding Jar Steps to Job Flows\n"

    commands.parse_command(JarStepCommand, "--jar JAR", "Run a Hadoop Jar in a step")
    commands.parse_options(["--jar"], [
      [ OptionWithArg, "--main-class MAIN_CLASS",  "The main class of the jar", :main_class ]
    ])

    opts.separator "\n  Adding Streaming Steps to Job Flows\n"

    commands.parse_command(StreamStepCommand, "--stream", "Add a step that performs hadoop streaming")
    commands.parse_options(["--stream"], [
      [ OptionWithArg, "--input INPUT",               "Input to the steps, e.g. s3n://mybucket/input", :input],
      [ OptionWithArg, "--output OUTPUT",             "The output to the steps, e.g. s3n://mybucket/output", :output],
      [ OptionWithArg, "--mapper MAPPER",             "The mapper program or class", :mapper],
      [ OptionWithArg, "--cache CACHE_FILE",          "A file to load into the cache, e.g. s3n://mybucket/sample.py#sample.py", :cache ],
      [ OptionWithArg, "--cache-archive CACHE_FILE",  "A file to unpack into the cache, e.g. s3n://mybucket/sample.jar", :cache_archive, ],
      [ OptionWithArg, "--jobconf KEY=VALUE",         "Specify jobconf arguments to pass to streaming, e.g. mapred.task.timeout=800000", :jobconf],
      [ OptionWithArg, "--reducer REDUCER",           "The reducer program or class", :reducer],
    ])

    opts.separator "\n  Adding and Modifying Instance Groups\n"

    commands.parse_command(ModifyInstanceGroupCommand, "--modify-instance-group INSTANCE_GROUP", "Modify an existing instance group")
    commands.parse_command(AddInstanceGroupCommand,    "--add-instance-group ROLE", "Add an instance group to an existing jobflow")
    commands.parse_command(UnarrestInstanceGroupCommand, "--unarrest-instance-group ROLE", "Unarrest an instance group of the supplied jobflow")
    commands.parse_options(["--instance-group", "--modify-instance-group", "--add-instance-group", "--create"], [
     [ InstanceCountOption, "--instance-count INSTANCE_COUNT", "Set the instance count of an instance group", :instance_count ]
    ])
    commands.parse_options(["--instance-group", "--add-instance-group", "--create"], [
     [ InstanceTypeOption,  "--instance-type INSTANCE_TYPE", "Set the instance type of an instance group", :instance_type ],
    ])
         
    opts.separator "\n  Contacting the Master Node\n"

    commands.parse_command(SSHCommand, "--ssh [COMMAND]", "SSH to the master node and optionally run a command")
    commands.parse_command(PutCommand, "--put SRC", "Copy a file to the job flow using scp")
    commands.parse_command(GetCommand, "--get SRC", "Copy a file from the job flow using scp")
    commands.parse_command(PutCommand, "--scp SRC", "Copy a file to the job flow using scp")
    commands.parse_options(["--get", "--put", "--scp"], [
      [ OptionWithArg, "--to DEST",    "Destination location when copying files", :dest ],
    ])
    commands.parse_command(SocksCommand, "--socks", "Start a socks proxy tunnel to the master node")

    commands.parse_command(LogsCommand, "--logs", "Display the step logs for the last executed step")

    opts.separator "\n  Assigning Elastic IP to Master Node\n"

    commands.parse_command(EipCommand, "--eip [ElasticIP]", "Associate ElasticIP to master node. If no ElasticIP is specified, allocate and associate a new one.")

    opts.separator "\n  Settings common to all step types\n"

    commands.parse_options(["--ssh", "--scp", "--eip"], [
      [ FlagOption,   "--no-wait",    "Don't wait for the Master node to start before executing scp or ssh or assigning EIP", :no_wait ],
      [ GlobalOption, "--key-pair-file FILE_PATH",   "Path to your local pem file for your EC2 key pair", :key_pair_file ], 
    ])

    opts.separator "\n  Specifying Bootstrap Actions\n"

    commands.parse_command(BootstrapActionCommand, "--bootstrap-action SCRIPT", "Run a bootstrap action script on all instances")
    commands.parse_options(["--bootstrap-action"], [
      [ OptionWithArg, "--bootstrap-name NAME",    "Set the name of the bootstrap action", :bootstrap_name ],
    ])
   

    opts.separator "\n  Listing and Describing Job flows\n"

    commands.parse_command(ListActionCommand, "--list", "List all job flows created in the last 2 days")
    commands.parse_command(DescribeActionCommand, "--describe", "Dump a JSON description of the supplied job flows")
    commands.parse_command(PrintHiveVersionCommand, "--print-hive-version", "Prints the version of Hive that's currently active on the job flow")
    commands.parse_options(["--list", "--describe"], [
      [ OptionWithArg, "--state NAME",   "Set the name of the bootstrap action", :state ],
      [ FlagOption,    "--active",       "List running, starting or shutting down job flows", :active ],
      [ FlagOption,    "--all",          "List all job flows in the last 2 weeks", :all ],
      [ OptionWithArg,    "--created-after=DATETIME", "List all jobflows created after DATETIME (xml date time format)", :created_after],
      [ OptionWithArg,    "--created-before=DATETIME", "List all jobflows created before DATETIME (xml date time format)", :created_before],
      [ FlagOption,    "--no-steps",     "Do not list steps when listing jobs", :no_steps ],
    ])
    
    opts.separator "\n  Terminating Job Flows\n"
            
    commands.parse_command(SetTerminationProtection, "--set-termination-protection BOOL", "Enable or disable job flow termination protection. Either true or false")

    commands.parse_command(TerminateActionCommand, "--terminate", "Terminate job flows")

    opts.separator "\n  Common Options\n"
    
    commands.parse_options(["--jobflow", "--describe"], [
      [ GlobalOption, "--jobflow JOB_FLOW_ID",  "The job flow to act on", :jobflow, /^j-[A-Z0-9]+$/],
    ])

    commands.parse_options(:global, [
      [ GlobalFlagOption, "--verbose",  "Turn on verbose logging of program interaction", :verbose ],
      [ GlobalFlagOption, "--trace",    "Trace commands made to the webservice", :trace ],
      [ GlobalOption, "--credentials CRED_FILE",  "File containing access-id and private-key", :credentials],
      [ GlobalOption, "--access-id ACCESS_ID",  "AWS Access Id", :aws_access_id],
      [ GlobalOption, "--private-key PRIVATE_KEY",  "AWS Private Key", :aws_secret_key],
      [ GlobalOption, "--log-uri LOG_URI",  "Location in S3 to store logs from the job flow, e.g. s3n://mybucket/logs", :log_uri ],
    ])
    commands.parse_command(VersionCommand, "--version", "Print version string")
    commands.parse_command(HelpCommand, "--help", "Show help message")

    opts.separator "\n  Uncommon Options\n"

    commands.parse_options(:global, [
      [ GlobalFlagOption, "--debug",  "Print stack traces when exceptions occur", :debug],
      [ GlobalOption,     "--endpoint ENDPOINT",  "EMR web service host to connect to", :endpoint],
      [ GlobalOption,     "--region REGION",  "The region to use for the endpoint", :region],
      [ GlobalOption,     "--apps-path APPS_PATH",  "Specify s3:// path to the base of the emr public bucket to use. e.g s3://us-east-1.elasticmapreduce", :apps_path],
      [ GlobalOption,     "--beta-path BETA_PATH",  "Specify s3:// path to the base of the emr public bucket to use for beta apps. e.g s3://beta.elasticmapreduce", :beta_path],
    ])
 
    opts.separator "\n  Short Options\n"
    commands.parse_command(HelpCommand, "-h", "Show help message")
    commands.parse_options(:global, [
      [ GlobalFlagOption, "-v", "Turn on verbose logging of program interaction", :verbose ],
      [ GlobalOption, "-c CRED_FILE",  "File containing access-id and private-key", :credentials ],
      [ GlobalOption, "-a ACCESS_ID",  "AWS Access Id", :aws_access_id],
      [ GlobalOption, "-p PRIVATE_KEY",  "AWS Private Key", :aws_secret_key],
      [ GlobalOption, "-j JOB_FLOW_ID",  "The job flow to act on", :jobflow, /^j-[A-Z0-9]+$/],
    ])

  end

  def self.is_step_command(cmd)
    return cmd.respond_to?(:steps)
  end

  def self.is_ba_command(cmd)
    return cmd.respond_to?(:bootstrap_actions)
  end

  def self.is_create_child_command(cmd)
    return is_step_command(cmd) || 
      is_ba_command(cmd) ||
      cmd.is_a?(AddInstanceGroupCommand) ||
      cmd.is_a?(CreateInstanceGroupCommand)
  end

  # this function pull out steps if there is a create command that preceeds them
  def self.fold_commands(commands)
    last_create_command = nil
    new_commands = []
    for cmd in commands do
      if cmd.is_a?(CreateJobFlowCommand) then
        last_create_command = cmd
      elsif is_create_child_command(cmd) then
        if last_create_command == nil then
          if is_step_command(cmd) then
            last_create_command = AddJobFlowStepsCommand.new(
              "--add-steps", "Add job flow steps", nil, commands
            )
            new_commands << last_create_command
          elsif is_ba_command(cmd) then
            raise RuntimeError, "the option #{cmd.name} must come after the --create option"
          elsif cmd.is_a?(CreateInstanceGroupCommand) then
            raise RuntimeError, "the option #{cmd.name} must come after the --create option"
          elsif cmd.is_a?(AddInstanceGroupCommand) then
            new_commands << cmd
            next
          else
            next
          end
        end

        actioned = false
        if is_step_command(cmd) then
          if ! last_create_command.respond_to?(:add_step_command) then
            last_create_command = AddJobFlowStepsCommand.new(
              "--add-steps", "Add job flow steps", nil, commands
            )
          end
          last_create_command.add_step_command(cmd)
          actioned = true
        end
        if is_ba_command(cmd) then 
          if ! last_create_command.respond_to?(:add_bootstrap_command) then
            raise RuntimeError, "Bootstrap actions must follow a --create command"
          end
          last_create_command.add_bootstrap_command(cmd)
          actioned = true
        end
        if cmd.is_a?(CreateInstanceGroupCommand) || cmd.is_a?(AddInstanceGroupCommand) then
          if last_create_command.respond_to?(:add_instance_group_command) then
            last_create_command.add_instance_group_command(cmd)
          else
            new_commands << cmd
          end
          actioned = true
        end

        if ! actioned then 
          raise RuntimeError, "Unknown child command #{cmd.name} following #{last_create_command.name}"
        end
        next 
      end
      new_commands << cmd
    end

    commands.commands = new_commands
  end

  def self.create_and_execute_commands(args, client_class, logger, executor, exit_on_error=true)
    commands = Commands.new(logger, executor)
    
    begin
      opts = OptionParser.new do |opts|
        add_commands(commands, opts)
      end
      opts.parse!(args)

      if commands.get_field(:trace) then
        logger.level = :trace
      end
      
      commands.parse_jobflows(args)

      if commands.commands.size == 0 then
        commands.commands << HelpCommand.new("--help", "Print help text", nil, commands)
      end
      
      credentials = Credentials.new(commands)
      credentials.parse_credentials(commands.get_field(:credentials, "credentials.json"), 
                                    commands.global_options)
      
      work_out_globals(commands)
      fold_commands(commands)
      commands.validate
      client = EmrClient.new(commands, logger, client_class)
      commands.enact(client)
    rescue RuntimeError => e
      logger.puts("Error: " + e.message)
      if commands.get_field(:trace) then
        logger.puts(e.backtrace.join("\n"))
      end
      if exit_on_error then
        exit(-1)
      else
        raise e
      end
    end
    return commands
  end

  def self.work_out_globals(commands)
    options = commands.global_options
    if commands.have(:region) then
      if commands.have(:endpoint) then
        raise RuntimeError, "You may not specify --region together with --endpoint"
      end

      endpoint = "https://#{options[:region]}.elasticmapreduce.amazonaws.com"
      commands.global_options[:endpoint] = endpoint
    end

    if commands.have(:endpoint) then
      region_match = commands.get_field(:endpoint).match("^https*://(.*)\.elasticmapreduce")
      if ! commands.have(:apps_path) && region_match != nil then
        options[:apps_path] = "s3://#{region_match[1]}.elasticmapreduce"
      end
    end

    options[:apps_path] ||= "s3://us-east-1.elasticmapreduce"
    options[:beta_path] ||= "s3://beta.elasticmapreduce"
    for key in [:apps_path, :beta_path] do
      options[key].chomp!("/")
    end
  end 
end
