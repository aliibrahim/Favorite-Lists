require 'acts_as_saveable'
require 'spec_helper'

describe ActsAsSaveable::Helpers::Words do

  before :each do
    @saved = ActsAsSaveable::Save.new
  end

  it "should know that like is a true saved" do
    expect(@saved.saveable_words.that_mean_true).to include "like"
  end

  it "should know that bad is a false saved" do
    expect(@saved.saveable_words.that_mean_false).to include "bad"
  end

  it "should be a saved for true when word is good" do
    expect(@saved.saveable_words.meaning_of('good')).to be true
  end

  it "should be a saved for false when word is down" do
    expect(@saved.saveable_words.meaning_of('down')).to be false
  end

  it "should be a saved for true when the word is unknown" do
    expect(@saved.saveable_words.meaning_of('lsdhklkadhfs')).to be true
  end

end
