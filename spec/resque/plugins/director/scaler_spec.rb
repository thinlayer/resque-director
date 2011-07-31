require 'spec_helper'

describe Resque::Plugins::Director::Scaler do
  subject { Resque::Plugins::Director::Scaler }
  
  before do
    Resque::Plugins::Director::Config.queue = "test"
  end
  
  describe "#scale_up" do
    before do
      Resque::Plugins::Director::Config.queue = :test
    end
    
    it "should start a worker on a specific queue" do
      subject.should_receive(:system).with(" QUEUE=test rake  resque:work &")
      subject.scale_up
    end
    
    it "should start the specified number of workers on a specific queue" do
      subject.should_receive(:system).twice.with(" QUEUE=test rake  resque:work &")
      subject.scale_up(2)
    end
    
    it "should start the task with environment" do
      Resque::Plugins::Director::Config.setup(:env => true)
      subject.should_receive(:system).with(" QUEUE=test rake environment resque:work &")
      subject.scale_up
    end
    
    it "should start the vars" do
      Resque::Plugins::Director::Config.setup(:vars => "PID=/pid")
      subject.should_receive(:system).with("PID=/pid QUEUE=test rake  resque:work &")
      subject.scale_up
    end
    
    it "should use the specified rake command" do
      Resque::Plugins::Director::Config.setup(:rake_path => "/path/to/rake")
      subject.should_receive(:system).with(" QUEUE=test /path/to/rake  resque:work &")
      subject.scale_up
    end
    
    it "should navigate to the run_path" do
      Resque::Plugins::Director::Config.setup(:run_path => "/path/to/go")
      subject.should_receive(:system).with("cd /path/to/go &&  QUEUE=test rake  resque:work &")
      subject.scale_up
    end
    
    it "should override the entire comand" do
      Resque::Plugins::Director::Config.setup(:run_path => "/path/to/go", :command_override => "run this")
      subject.should_receive(:system).with("run this")
      subject.scale_up
    end
  end
  
  describe "#scaling" do
    before do
      @times_scaled = 0
    end
    
    it "should not scale workers if last time scaled is too soon" do
      2.times { subject.scaling { @times_scaled += 1 } }
      @times_scaled.should == 1
    end
    
    it "should scale workers if wait time has passed" do
      Resque::Plugins::Director::Config.setup(:wait_time => 0)
      2.times { subject.scaling { @times_scaled += 1 } }
      @times_scaled.should == 2
    end
  end
  
  describe "#scale_down" do
    before do
      @worker = Resque::Worker.new(:test)
      @worker.register_worker
    end
    
    it "should scale down a worker" do
      Resque.workers.should == [@worker]
      subject.scale_down
    end
    
    it "should scale down multiple workers" do
      
    end
  end
  
  describe "#scale_within_requirements" do
    it "should not scale up workers if the minumum number or greater are already running" do
      Resque::Worker.new(:test).register_worker
      subject.should_not_receive(:scale_up)
      subject.scale_within_requirements
    end
    
    it "should scale up the minimum number of workers if non are running" do
      Resque::Plugins::Director::Config.setup :min_workers => 2
      subject.should_receive(:scale_up).with(2)
      subject.scale_within_requirements
    end
    
    it "should ensure at least one worker is running if min_workers is less than zero" do
      Resque::Plugins::Director::Config.setup :min_workers => -10
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
    
    it "should scale up the minimum number of workers if less than the minimum are running" do
      Resque::Plugins::Director::Config.setup :min_workers => 2
      Resque::Worker.new(:test).register_worker
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
    
    it "should scale down the max number of workers if more than max" do
      Resque::Plugins::Director::Config.setup :max_workers => 1
      workers = 2.times.map { Resque::Worker.new(:test) }
      Resque.should_receive(:workers).and_return(workers)
      
      subject.should_receive(:scale_down).with(1)
      subject.scale_within_requirements
    end
    
    it "should ignore workers from other queues" do
      Resque::Worker.new(:other).register_worker
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
    
    it "should ignore workers on multiple queues" do
      Resque::Worker.new(:test, :other).register_worker
      subject.should_receive(:scale_up).with(1)
      subject.scale_within_requirements
    end
  end
  
end