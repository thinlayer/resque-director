require 'spec_helper'

describe Resque::Plugins::Director::Config do
  subject { Resque::Plugins::Director::Config }
  
  describe "#setup" do  
    it "should set the variables to defaults if none are specified" do
      subject.min_workers.should == 1
      subject.wait_time.should == 60
    end
    
    it "should set the variables to the specified values" do
      subject.setup(:min_workers => 3, :wait_time => 30)
      subject.min_workers.should == 3
      subject.wait_time.should == 30
    end
    
    it "should handle bogus config options" do
      lambda { subject.setup(:bogus => 3) }.should_not raise_error
    end
    
    it "should set max_workers to default if less than min_workers" do
      subject.setup(:min_workers => 3, :max_workers => 2)
      subject.min_workers.should == 3
      subject.max_workers.should == 0
    end
  end
  
  describe "#reset!" do
    it "should reset the Config" do
      subject.setup(:min_workers => 3, :wait_time => 30)
      subject.reset!
      subject.min_workers.should == 1
      subject.wait_time.should == 60
    end
  end
  
  describe "log" do
    it "logs message to a logger using given log level if specified" do
      log = mock('Logger')
      subject.setup(:logger => log, :log_level => :info)
      log.should_receive(:info).with("DIRECTORS LOG: test message")
      subject.log("test message")
    end
    
    it "defaults log level to debug" do
      log = mock('Logger')
      subject.setup(:logger => log)
      log.should_receive(:debug).with("DIRECTORS LOG: test message")
      subject.log("test message")
    end
  end
end