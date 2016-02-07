require 'acts_as_saveable'
require 'spec_helper'

describe ActsAsSaveable::Saver do

  it "should not be a saver" do
    expect(NotSaveable).not_to be_saveable
  end

  it "should be a saver" do
    expect(Saveable).to be_saveable
  end

  it_behaves_like "a saver_model" do
    # TODO Replace with factories
    let (:saver) { Saver.create(:name => 'i can saved!') }
    let (:saver2) { Saver.create(:name => 'a new person') }
    let (:saveable) { Saveable.create(:name => 'a saving model') }
    let (:saveable2) { Saveable.create(:name => 'a 2nd saving model') }
  end
end
