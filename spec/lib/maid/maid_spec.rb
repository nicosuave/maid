require 'spec_helper'

module Maid
  describe Maid do
    before :each do
      @logger = mock('Logger')
      @logger.stub!(:progname=)
      Logger.stub!(:new).and_return(@logger)
    end

    describe '.new' do
      it 'should set up a logger with the default path' do
        Logger.should_receive(:new).with(Maid::DEFAULTS[:log_path])
        Maid.new
      end

      it 'should set up a logger with the given path, if provided' do
        log_path = '/var/log/maid.log'
        Logger.should_receive(:new).with(log_path)
        Maid.new(:log_path => log_path)
      end

      it 'should make the log directory in case it does not exist' do
        FileUtils.should_receive(:mkdir_p).with('/home/username/log')
        Maid.new(:log_path => '/home/username/log/maid.log')
      end

      it 'should set the trash to the default path' do
        maid = Maid.new
        maid.trash_path.should_not be_nil
        maid.trash_path.should == Maid::DEFAULTS[:trash_path]
      end

      it 'should set the trash to the given path, if provided' do
        trash_path = '/home/username/.local/share/Trash/files/'
        maid = Maid.new(:trash_path => trash_path)
        maid.trash_path.should_not be_nil
        maid.trash_path.should == trash_path
      end

      it 'should set the progname for the logger' do
        @logger.should_receive(:progname=).with(Maid::DEFAULTS[:progname])
        Maid.new
      end

      it 'should set the progname for the logger to the given name, if provided' do
        @logger.should_receive(:progname=).with('Fran')
        Maid.new(:progname => 'Fran')
      end

      it 'should set the file options to the defaults' do
        Maid.new.file_options.should == Maid::DEFAULTS[:file_options]
      end

      it 'should set the file options to the given options, if provided' do
        maid = Maid.new(:file_options => {:verbose => true})
        maid.file_options.should == {:verbose => true}
      end

      it 'should set the rules path' do
        Maid.new.rules_path.should == Maid::DEFAULTS[:rules_path]
      end

      it 'should set the ruels pathto the given path, if provided' do
        maid = Maid.new(:rules_path => 'Maidfile')
        maid.rules_path.should == 'Maidfile'
      end

      it 'should ignore nil options' do
        maid = Maid.new(:rules_path => nil)
        maid.rules_path.should == Maid::DEFAULTS[:rules_path]
      end
    end

    describe '#clean' do
      before :each do
        @maid = Maid.new
        @maid.stub!(:add_rules)
        @logger.stub!(:info)
      end

      it 'should log start and finish' do
        @logger.should_receive(:info).with('Started')
        @logger.should_receive(:info).with('Finished')
        @maid.clean
      end

      it 'should process the default rules' do
        @maid.should_receive(:add_rules).with(Maid::DEFAULTS[:rules_path])
        @maid.clean
      end

      it 'should follow the given rules, if provided' do
        rules_path = '/home/username/.local/maid/rules.rb'
        @maid.should_receive(:add_rules).with(rules_path)
        @maid.should_receive(:follow_rules)
        @maid.clean(rules_path)
      end
    end

    describe '#add_rules' do
      before :each do
        Kernel.stub!(:require)
        @maid = Maid.new
      end

      it 'should set the Maid instance' do
        ::Maid.should_receive(:with_instance).with(@maid)
        @maid.add_rules('path')
      end

      it 'should require the path' do
        path = 'rules.rb'
        Kernel.should_receive(:require).with(path)
        @maid.add_rules(path)
      end
    end

    describe '#rule' do
      before :each do
        @maid = Maid.new
      end

      it 'should add a rule to the list of rules' do
        @maid.rules.length.should == 0

        @maid.rule 'description' do
          'instructions'
        end

        @maid.rules.length.should == 1
        @maid.rules.first.description.should == 'description'
      end
    end

    describe '#follow_rules' do
      it 'should follow each rule' do
        n = 3
        maid = Maid.new
        @logger.should_receive(:info).exactly(n).times
        rules = (1..n).map do |n|
          mock = mock("rule ##{n}", :description => 'description')
          mock.should_receive(:follow)
          mock
        end
        maid.instance_eval { @rules = rules }

        maid.follow_rules
      end
    end
  end
end