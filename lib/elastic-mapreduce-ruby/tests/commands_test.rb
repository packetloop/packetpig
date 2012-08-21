#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'commands'
require 'test/unit'

module Commands

  class MockExecutor
    def exec(cmd)
    end
  end

  class MockEMRClient
    attr_accessor :state

    def initialize(config)
      @config = config
      @state = "RUNNING"
      @step_map =
      { "j-hive-installed" =>
        {"ExecutionStatusDetail"=>
          {"StartDateTime"=>1291074747.0, "EndDateTime"=>1291074776.0, "LastStateChangeReason"=>nil,
          "CreationDateTime"=>1291074521.0, "State"=>"COMPLETED"},
          "StepConfig"=>
            {"Name"=>"Setup Hive",
            "HadoopJarStep"=>
              {"Jar"=>"s3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar",
              "Args"=>
                ["s3://us-east-1.elasticmapreduce/libs/hive/hive-script",
                "--base-path", "s3://us-east-1.elasticmapreduce/libs/hive/",
                "--install-hive"],
                "Properties"=>[],
                "MainClass"=>nil},
              "ActionOnFailure"=>"CONTINUE"}},
        "j-hive-0.5-installed" =>
        {"ExecutionStatusDetail"=>
          {"StartDateTime"=>1291074747.0, "EndDateTime"=>1291074776.0, "LastStateChangeReason"=>nil,
          "CreationDateTime"=>1291074521.0, "State"=>"COMPLETED"},
          "StepConfig"=>
            {"Name"=>"Setup Hive",
            "HadoopJarStep"=>
              {"Jar"=>"s3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar",
              "Args"=>
                ["s3://us-east-1.elasticmapreduce/libs/hive/hive-script",
                "--base-path", "s3://us-east-1.elasticmapreduce/libs/hive/",
                "--install-hive","--hive-versions","0.5"],
                "Properties"=>[],
                "MainClass"=>nil},
              "ActionOnFailure"=>"CONTINUE"}},
        "j-hive-0.7-installed" =>
        {"ExecutionStatusDetail"=>
          {"StartDateTime"=>1291074747.0, "EndDateTime"=>1291074776.0, "LastStateChangeReason"=>nil,
          "CreationDateTime"=>1291074521.0, "State"=>"COMPLETED"},
          "StepConfig"=>
            {"Name"=>"Setup Hive",
            "HadoopJarStep"=>
              {"Jar"=>"s3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar",
              "Args"=>
                ["s3://us-east-1.elasticmapreduce/libs/hive/hive-script",
                "--base-path", "s3://us-east-1.elasticmapreduce/libs/hive/",
                "--install-hive","--hive-versions","0.7"],
                "Properties"=>[],
                "MainClass"=>nil},
              "ActionOnFailure"=>"CONTINUE"}},
      }
    end

    def self.new_aws_query(config)
      return MockEMRClient.new(config)
    end

    def DescribeJobFlows(args)
      steps = []
      if args["JobFlowIds"] != nil and @step_map.has_key? args["JobFlowIds"].first then
        steps = [@step_map[args["JobFlowIds"].first]]
      end
      return {
        "JobFlows" =>
        [
         {
           "LogUri" => "s3n://testing/", 
           "Name" => "Development Job Flow  (requires manual termination)", 
           "BootstrapActions" =>[], 
           "ExecutionStatusDetail" => {
             "EndDateTime" => 1286584312.0, 
             "CreationDateTime" => 1286584224.0, 
             "LastStateChangeReason" => "Terminated by user request", 
             "State" => @state, 
             "StartDateTime" => nil, 
             "ReadyDateTime" => nil
           }, 
           "Steps" => steps, 
           "JobFlowId" => "j-2HWO50OUKNMHG", 
           "Instances" => {
             "Ec2KeyName" => "richcole-test", 
             "InstanceCount" =>5, 
             "NormalizedInstanceHours" => nil, 
             "Placement" => {"AvailabilityZone" => "us-east-1d"}, 
             "KeepJobFlowAliveWhenNoSteps" => true, 
             "SlaveInstanceType" => "m2.xlarge", 
             "MasterInstanceType" => "m2.xlarge", 
             "MasterPublicDnsName" => nil, 
             "MasterInstanceId" => nil, 
             "InstanceGroups" => [{
               "SpotPrice" => nil,
               "EndDateTime" => nil,
               "Name" => "Task Instance Group",
               "InstanceRole" => "TASK",
               "CreationDateTime" => 1286862675.0,
               "LaunchGroup" => nil,
               "LastStateChangeReason" => "",
               "InstanceGroupId" => "ig-D2NC23WFSOOU",
               "State" => "RUNNING",
               "Market" => "ON_DEMAND",
               "InstanceType" => "c1.medium",
               "StartDateTime" => 1286862907.0,
               "InstanceRunningCount" => 2,
               "ReadyDateTime" => 1286862907.0,
               "InstanceRequestCount" => 2
               },
               {
               "SpotPrice" => nil,
               "EndDateTime" => nil,
               "Name" => "Master Instance Group",
               "InstanceRole" => "MASTER",
               "CreationDateTime" => 1286862675.0,
               "LaunchGroup" => nil,
               "LastStateChangeReason" => "",
               "InstanceGroupId" => "ig-1BFN7TCX7YE5Y",
               "State" => "RUNNING",
               "Market" => "ON_DEMAND",
               "InstanceType" => "m1.small",
               "StartDateTime" => 1286862866.0,
               "InstanceRunningCount" => 1,
               "ReadyDateTime" => 1286862906.0,
               "InstanceRequestCount" => 1
               },
               {
               "SpotPrice" => nil,
               "EndDateTime" => nil,
               "Name" => "Core Instance Group",
               "InstanceRole" => "CORE",
               "CreationDateTime" => 1286862675.0,
               "LaunchGroup" => nil,
               "LastStateChangeReason" => "Expanding cluster",
               "InstanceGroupId" => "ig-2EUIGTIPDLTXW",
               "State" => "RESIZING",
               "Market" => "ON_DEMAND",
               "InstanceType" => "m1.large",
               "StartDateTime" => 1286862907.0,
               "InstanceRunningCount" => 1,
               "ReadyDateTime" => 1286862907.0,
               "InstanceRequestCount" => 3
               }]
           },
           "HadoopVersion" => "0.20"
         } 
        ]
      }
    end

    def RunJobFlow(opts)
      return { "JobFlowId" => "j-ABABABABA" }
    end

    def AddJobFlowSteps(opts)
      return nil
    end

    def TerminateJobFlows(opts)
      return nil
    end

    def ModifyInstanceGroups(opts)
      return nil
    end

    def AddInstanceGroups(opts)
      return nil
    end

  end

  class MockLogger
    def puts(msg)
    end

    def trace(msg)
    end
  end

  class CommandTest < Test::Unit::TestCase

    def setup
      @client_class = MockEMRClient #FIXME: make this return always the same object
      @logger       = MockLogger.new
      @executor     = MockExecutor.new
    end

    def create_and_execute_commands(args)
      return ::Commands.create_and_execute_commands(args.split(/\s+/), @client_class, @logger, @executor, false)
    end

    def test_modify_instance_group_command
      args = "-c tests/credentials.json --modify-instance-group core --instance-count 10 --jobflow j-ABABABA"
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.size)
      c = @commands.last
      assert(c.is_a?(ModifyInstanceGroupCommand))
      assert_equal(10, c.instance_count)
      assert_not_nil(c.instance_group_id)
      assert_equal(nil, c.instance_type)
      assert_equal("CORE", c.instance_role)
    end

    def test_one
      args = "-c tests/credentials.json --create --alive --num-instances 10 " +
        "--slave-instance-type m1.small --master-instance-type m1.large"
      @commands = create_and_execute_commands(args)
    end

    def test_two
      args = "-c tests/credentials.json --create --alive --num-instances 10 " +
        "--slave-instance-type m1.small --master-instance-type m1.large " + 
        "--instance-group TASK --instance-type m1.small --instance-count 10 " + 
        "--bootstrap-action s3://elasticmapreduce/scripts/configure-hadoop " + 
        "--arg s3://mybucket/config/custom-site-config.xml "
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
    end

    def test_three
      args = "-c tests/credentials.json --create --alive --num-instances 10 " + 
        "--slave-instance-type m1.small --master-instance-type m1.large " +
        "--instance-group TASK --instance-type m1.small --instance-count 10 " + 
        "--bootstrap-action s3://elasticmapreduce/scripts/configure-hadoop " + 
        "--arg s3://mybucket/config/custom-site-config.xml " +
        "--pig-script s3://elasticmapreduce/samples/sample.pig " + 
        "--pig-interactive"
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
      cmd1 = @commands.commands.first
      assert_equal(2, cmd1.step_commands.size)
      assert_equal(PigInteractiveCommand, cmd1.step_commands[0].class)
    end

    def test_four
      args = "-a ACCESS_ID -p SECRET_KEY --create --alive " + 
        "--hive-script s3://maps.google.com --enable-debugging " + 
        "--log-uri s3://somewhere.com/logs/"
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
      assert_equal(3, @commands.commands[0].step_commands.size)
      steps = @commands.commands[0].step_commands
      assert_equal(EnableDebuggingCommand, steps[0].class) 
      assert_equal(HiveInteractiveCommand, steps[1].class) 
      assert_equal(HiveScriptCommand, steps[2].class) 
    end
    
    def hadoop_jar_step_args(command)
      command.steps[0]["HadoopJarStep"]["Args"]
    end
    
    def pig_script_command_default_args
      [
        "s3://us-east-1.elasticmapreduce/libs/pig/pig-script",
        "--base-path",
        "s3://us-east-1.elasticmapreduce/libs/pig/",
        "--run-pig-script",
        "--args",
        "-f"
      ]
    end
    
    def hive_script_command_default_args
      [
        "s3://us-east-1.elasticmapreduce/libs/hive/hive-script",
        "--base-path",
        "s3://us-east-1.elasticmapreduce/libs/hive/",
        "--run-hive-script",
        "--args",
        "-f"
      ]
    end

    def test_pig_arg
      args1 = "-a ACCESS_ID -p SECRET_KEY --create --alive " +
        "--pig-script --args s3://maps.google.com --args -p,INPUT=s3://maps.google.com/test.pig"
      args2 = "-a ACCESS_ID -p SECRET_KEY --create --alive " +
        "--pig-script s3://maps.google.com --args -p,INPUT=s3://maps.google.com/test.pig"
      @commands = create_and_execute_commands(args1)
      steps = @commands.commands.first.step_commands
      pig_command = steps[1]      
      assert_equal(pig_command.arg, nil)
      assert_equal(pig_command.args, ["s3://maps.google.com", "-p", "INPUT=s3://maps.google.com/test.pig"])
      assert_equal(pig_command.steps.size, 1)
      args = pig_script_command_default_args
      args << "s3://maps.google.com" << "-p" << "INPUT=s3://maps.google.com/test.pig"
      assert_equal(hadoop_jar_step_args(pig_command), args)
      
      @commands = create_and_execute_commands(args2)
      steps = @commands.commands.first.step_commands
      pig_command = steps[1]     
      assert_equal(pig_command.arg, "s3://maps.google.com")
      assert_equal(pig_command.args, ["-p", "INPUT=s3://maps.google.com/test.pig"])
      assert_equal(pig_command.steps.size, 1)
      assert_equal(hadoop_jar_step_args(pig_command), args)
    end
    
    def test_hive
      args = "-a ACCESS_ID -p SECRET_KEY --create --alive " + 
        "--hive-script --args s3://maps.google.com "
      @commands = create_and_execute_commands(args)
      create_command = @commands.commands.first
      steps = create_command.step_commands
      install_hive_command = steps[0]
      hive_command = steps[1]
      
      assert_equal(1, @commands.commands.size)
      assert_equal(2, steps.size)
      assert_equal(HiveScriptCommand, hive_command.class) 
      assert_equal(hive_command.arg, nil)
      assert_equal(hive_command.args, ["s3://maps.google.com"])
      assert_equal(hive_command.steps.size, 1)
      args = hive_script_command_default_args
      args << "s3://maps.google.com" 
      assert_equal(hadoop_jar_step_args(hive_command), args)
    end
    
    def test_install_hive_version
      args = "-a ACCESS_ID -p SECRET_KEY --create --alive " + 
        "--hive-script --args s3://maps.google.com --hive-versions 0.5"
      @commands = create_and_execute_commands(args)
      create_command = @commands.commands.first
      steps = create_command.step_commands
      install_hive_command = steps[0]
      hive_command = steps[1]
      assert_equal(1, @commands.commands.size)
      assert_equal(2, steps.size)
      assert_equal(HiveScriptCommand, hive_command.class) 
      assert_equal(hive_command.arg, nil)
      assert_equal(hive_command.args, ["s3://maps.google.com"])
      assert_equal(hive_command.steps.size, 1)
      args = hive_script_command_default_args
      args.insert(3, "--hive-versions")
      args.insert(4, "0.5")
      args  << "s3://maps.google.com"
      assert_equal(hadoop_jar_step_args(hive_command), args)
    end

    def test_run_hive_script_same_version
      args = "-a ACCESS_ID -p SECRET_KEY --jobflow j-hive-0.5-installed " + 
        "--hive-script --args s3://maps.google.com --hive-versions 0.5"
      @commands = create_and_execute_commands(args)
      create_command = @commands.commands.first
      steps = create_command.step_commands
      install_hive_command = steps[0]
      hive_command = steps[0]

      assert_equal(1, @commands.commands.size)
      assert_equal(1, steps.size)
      assert_equal(HiveScriptCommand, hive_command.class) 
      assert_equal(hive_command.arg, nil)
      assert_equal(hive_command.args, ["s3://maps.google.com"])
      assert_equal(hive_command.steps.size, 1)
      args = hive_script_command_default_args
      args.insert(3, "--hive-versions")
      args.insert(4, "0.5")
      args << "s3://maps.google.com"
      assert_equal(hadoop_jar_step_args(hive_command), args)
    end

    def test_run_hive_script_different_version
      args = "-a ACCESS_ID -p SECRET_KEY --jobflow j-hive-0.5-installed " + 
        "--hive-script --args s3://maps.google.com --hive-versions 0.7"
      @commands = create_and_execute_commands(args)
      create_command = @commands.commands.first
      steps = create_command.step_commands
      install_hive_command = steps[0]
      hive_command = steps[1]

      assert_equal(1, @commands.commands.size)
      assert_equal(2, steps.size)
      assert_equal(HiveScriptCommand, hive_command.class) 
      assert_equal(hive_command.arg, nil)
      assert_equal(hive_command.args, ["s3://maps.google.com"])
      assert_equal(hive_command.steps.size, 1)
      args = hive_script_command_default_args
      args.insert(3, "--hive-versions")
      args.insert(4, "0.7")
      args << "s3://maps.google.com"
      assert_equal(hadoop_jar_step_args(hive_command), args)
    end

    def test_hive_script_step_action_propogation
      args = "-a ACCESS_ID -p SECRET_KEY --jobflow j-hive-0.5-installed " + 
        "--hive-script --args s3://maps.google.com --hive-versions 0.7 " +
        "--step-action CONTINUE"
      @commands = create_and_execute_commands(args)
      create_command = @commands.commands.first
      steps = create_command.step_commands
      install_hive_command = steps[0]
      hive_command = steps[0]
      assert_equal(1, @commands.commands.size)
      assert_equal(2, steps.size)
      assert_equal(HiveInteractiveCommand, hive_command.class) 
      assert_equal(hive_command.arg, nil)
      assert_equal(hive_command.args, [])
      assert_equal(hive_command.steps.size, 1)
      assert_equal(hive_command.steps.first["ActionOnFailure"], "CONTINUE")
    end

    def test_hive_no_create
      args = "-a ACCESS_ID -p SECRET_KEY --jobflow j-ABABABABA " + 
        "--hive-script --args s3://maps.google.com "
      @commands = create_and_execute_commands(args)
      create_command = @commands.commands.first
      steps = create_command.step_commands
      install_hive_command = steps[0]
      hive_command = steps[1]

      assert_equal(1, @commands.commands.size)
      assert_equal(2, steps.size)
      assert_equal(HiveScriptCommand, hive_command.class) 
      assert_equal(hive_command.arg, nil)
      assert_equal(hive_command.args, ["s3://maps.google.com"])
      assert_equal(hive_command.steps.size, 1)
      args = hive_script_command_default_args
      args << "s3://maps.google.com" 
      assert_equal(hadoop_jar_step_args(hive_command), args)
    end
    
    def test_hive_no_create2
      args = "-a ACCESS_ID -p SECRET_KEY --jobflow j-ABABABABA " + 
        "--hive-script s3://maps.google.com --args -d,options "
      @commands = create_and_execute_commands(args)
      create_command = @commands.commands.first
      steps = create_command.step_commands
      install_hive_command = steps[0]
      hive_command = steps[1]

      assert_equal(1, @commands.commands.size)
      assert_equal(2, steps.size)
      assert_equal(HiveScriptCommand, hive_command.class) 
      assert_equal(hive_command.arg, "s3://maps.google.com")
      assert_equal(hive_command.args, ["-d", "options"])
      assert_equal(hive_command.steps.size, 1)
      args = hive_script_command_default_args
      args << "s3://maps.google.com" << "-d" << "options"
      assert_equal(hadoop_jar_step_args(hive_command), args)
    end   

    def test_five
      args = "-a ACCESS_ID -p SECRET_KEY -j j-ABABABAABA --hive-script " + 
        "s3://maps.google.com --enable-debugging --log-uri s3://somewhere.com/logs/"
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
      assert_equal(3, @commands.commands[0].step_commands.size)
      steps = @commands.commands[0].step_commands
      assert_equal(EnableDebuggingCommand, steps[0].class) 
      assert_equal(HiveInteractiveCommand, steps[1].class) 
      assert_equal(HiveScriptCommand, steps[2].class) 
    end

    def test_six
      args = "-a ACCESS_ID -p SECRET_KEY --list --active"
      @commands = create_and_execute_commands(args)
    end

    def test_seven
      args = "-a ACCESS_ID -p SECRET_KEY --list --active --terminate"
      @commands = create_and_execute_commands(args)
    end

    def test_eight
      args = "-a ACCESS_ID -p SECRET_KEY --terminate -j j-ABABABABA"
      @commands = create_and_execute_commands(args)
    end

    def test_create_one
      args = "-a ACCESS_ID -p SECRET_KEY --create --alive --name TestFlow"
      @commands = create_and_execute_commands(args)
    end

    def test_ssh_no_jobflow
      args = "-a ACCESS_ID -p SECRET_KEY --ssh"
      assert_raise RuntimeError do
        @commands = create_and_execute_commands(args)
      end
    end

    def test_ssh_too_many_jobflows
      args = "-a ACCESS_ID -p SECRET_KEY -j j-ABABABA j-ABABABA --ssh"
      assert_raise RuntimeError do
        @commands = create_and_execute_commands(args)
      end
    end

    def test_jar_with_mainclass
      args = "-a ACCESS_ID -p SECRET_KEY -j j-3TRNB9E4GU2NI 
        --jar s3://my-example-bucket/wordcount.jar 
        --main-class org.myorg.WordCount 
        --arg s3://elasticmapreduce/samples/wordcount/input/ 
        --arg hdfs:///wordcount/output/1 
      "

      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
      c = @commands.commands.first
      s = c.step_commands.first
      st = s.steps
      assert_equal([{"HadoopJarStep"=>{"Jar"=>"s3://my-example-bucket/wordcount.jar",
        "Args"=>["s3://elasticmapreduce/samples/wordcount/input/", "hdfs:///wordcount/output/1"],
        "MainClass"=>"org.myorg.WordCount"}, "ActionOnFailure"=>"CANCEL_AND_WAIT", "Name"=>"Example Jar Step"}], st)
    end

    def test_ssh
      args = "-a ACCESS_ID -p SECRET_KEY --key-pair-file test.pem -j j-ABABABA --ssh"
      @commands = create_and_execute_commands(args)
    end

    def test_unarrest
      args = "-a ACCESS_ID -p SECRET_KEY --unarrest-instance-group core -j j-ABABABA"
      @commands = create_and_execute_commands(args)
    end

    def test_late_name
      args = "-a ACCESS_ID -p SECRET_KEY --create --alive --enable-debugging --hive-interactive --name MyHiveJobFlow --log-uri=s3://haijun-test/logs"
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
      assert_equal("MyHiveJobFlow", @commands.commands.first.jobflow_name)
    end

    def test_ic_it
      args = "-a ACCESS_ID -p SECRET_KEY --create --alive --enable-debugging --hive-interactive --instance-count 5 --instance-type m1.small --name MyHiveJobFlow --log-uri=s3://haijun-test/logs"
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
      cc = @commands.commands.first
      assert_equal("MyHiveJobFlow", cc.jobflow_name)
      assert_equal(5, cc.instance_count)
      assert_equal("m1.small", cc.instance_type)
    end

    def test_json
      args = "-a ACCESS_ID -p SECRET_KEY --jobflow j-ABABABABA --json tests/example.json --param <bucket>=mybucket --param mybucket=yourbucket"
      @commands = create_and_execute_commands(args)
      assert_equal(1, @commands.commands.size)
      cc = @commands.commands.first.step_commands.first
      assert_equal("tests/example.json", cc.arg)
      assert_equal({:key => "<bucket>", :value => "mybucket"}, cc.variables[0])
      assert_equal({:key => "mybucket", :value => "yourbucket"}, cc.variables[1])

      st = cc.steps.first

      expected_step = {
        "HadoopJarStep" => {
          "Jar"  => "/home/hadoop/contrib/streaming/hadoop-0.18-streaming.jar", 
          "Args" => ["-input", "s3n://elasticmapreduce/samples/wordcount/input", 
                     "-output", "s3n://yourbucket/result", "-mapper", "s3://yourbucket/lib/mapper"]
        }, 
        "ActionOnFailure" => "CONTINUE", 
        "Name" => "Example Step"
      }

      assert_equal(expected_step, st)
    end

    def test_ic_it2
      args = "-a ACCESS_ID -p SECRET_KEY --jobflow j-ABABABAB --resize-jobflow --add-instance-group task --instance-type m1.large --instance-count 5"
      @commands = create_and_execute_commands(args)
      assert_equal(2, @commands.commands.size)
      cc = @commands.commands[1]
      assert_equal(5, cc.instance_count)
      assert_equal("m1.large", cc.instance_type)
      assert_equal("TASK", cc.instance_role)
    end

    def test_command_option_mismatch
      args = "-c tests/credentials.json --instance-group core --instance-count 10"
      assert_raise RuntimeError do
        @commands = create_and_execute_commands(args)
      end
    end
    
    def test_region_from_az
      @commands = create_and_execute_commands("-c tests/credentials.json")
      eip_command = EipCommand.new("eip-command", "eip-command", "arg", @commands)
      assert_equal('https://ec2.us-east-1.amazonaws.com', eip_command.ec2_endpoint_from_az('us-east-1a'))
      assert_equal('https://ec2.ap-northeast-1.amazonaws.com', eip_command.ec2_endpoint_from_az('ec2.ap-northeast-1b'))
      assert_equal('https://ec2.us-west-1.amazonaws.com', eip_command.ec2_endpoint_from_az('ec2.us-west-1b'))
      assert_equal('https://ec2.us-west-2.amazonaws.com', eip_command.ec2_endpoint_from_az('ec2.us-west-2b'))
      assert_equal('https://ec2.sa-east-1.amazonaws.com', eip_command.ec2_endpoint_from_az('ec2.sa-east-1b'))
    end

    def test_hbase_instance_types
      assert_raise RuntimeError do
        @commands = create_and_execute_commands("-c tests/credentials.json --create --hbase")
      end
    end

  end
end
