require 'acts_as_saveable'
require 'spec_helper'

describe SaveableSaver do
  it_behaves_like "a saveable_model" do
    # TODO Replace with factories
    let (:saver) { SaveableSaver.create(:name => 'i can saved!') }
    let (:saver2) { SaveableSaver.create(:name => 'a new person') }
    let (:saver3) { Saver.create(:name => 'another person') }
    let (:saveable) { SaveableSaver.create(:name => 'a saving model') }
    let (:saveable_cache) { SaveableCache.create(:name => 'saving model with cache') }
  end

  it_behaves_like "a saver_model" do
    # TODO Replace with factories
    let (:saver) { SaveableSaver.create(:name => 'i can saved!') }
    let (:saver2) { SaveableSaver.create(:name => 'a new person') }
    let (:saveable) { SaveableSaver.create(:name => 'a saving model') }
    let (:saveable2) { SaveableSaver.create(:name => 'a 2nd saving model') }
  end
end
