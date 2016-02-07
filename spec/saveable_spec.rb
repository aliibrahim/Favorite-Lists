require 'acts_as_saveable'
require 'spec_helper'

describe ActsAsSaveable::Saveable do
  it "should not be saveable" do
    expect(NotSaveable).not_to be_saveable
  end

  it "should be saveable" do
    expect(Saveable).to be_saveable
  end

  it_behaves_like "a saveable_model" do
    # TODO Replace with factories
    let (:saver) { Saver.create(:name =>'i can saved!') }
    let (:saver2) { Saver.create(:name => 'a new person') }
    let (:saver3) { Saver.create(:name => 'another person') }
    let (:saveable) { Saveable.create(:name =>'a saving model') }
    let (:saveable_cache) { SaveableCache.create(:name => 'saving model with cache') }
  end
end
