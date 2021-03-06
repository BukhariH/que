require 'spec_helper'

describe Que, 'helpers' do
  it "should be able to drop and create the jobs table" do
    DB.table_exists?(:que_jobs).should be true
    Que.drop!
    DB.table_exists?(:que_jobs).should be false
    Que.execute "SET client_min_messages TO 'warning'" # Avoid annoying NOTICE messages.
    Que.create!
    DB.table_exists?(:que_jobs).should be true
  end

  it "should be able to clear the jobs table" do
    DB[:que_jobs].insert :job_class => "Que::Job"
    DB[:que_jobs].count.should be 1
    Que.clear!
    DB[:que_jobs].count.should be 0
  end
end
