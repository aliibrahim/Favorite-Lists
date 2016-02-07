shared_examples "a saveable_model" do
  it "should return false when a saved with no saver is saved" do
    expect(saveable.save_by).to be false
  end

  it "should have one saved when saved" do
    saveable.save_by :saver => saver, :saved => 'yes'
    expect(saveable.saves_for.size).to eq(1)
  end

  it "should have one saved when saved on twice by the same person" do
    saveable.save_by :saver => saver, :saved => 'yes'
    saveable.save_by :saver => saver, :saved => 'no'
    expect(saveable.saves_for.size).to eq(1)
  end

  it "should have two saves_for when saved on twice by the same person with duplicate paramenter" do
    saveable.save_by :saver => saver, :saved => 'yes'
    saveable.save_by :saver => saver, :saved => 'no', :duplicate => true
    expect(saveable.saves_for.size).to eq(2)
  end

  it "should have one scoped saved when saving under an scope" do
    saveable.save_by :saver => saver, :saved => 'yes', :save_scope => 'rank'
    expect(saveable.find_saves_for(:save_scope => 'rank').size).to eq(1)
  end

  it "should have one saved when saved on twice using scope by the same person" do
    saveable.save_by :saver => saver, :saved => 'yes', :save_scope => 'rank'
    saveable.save_by :saver => saver, :saved => 'no', :save_scope => 'rank'
    expect(saveable.find_saves_for(:save_scope => 'rank').size).to eq(1)
  end

  it "should have two saves_for when saving on two different scopes by the same person" do
    saveable.save_by :saver => saver, :saved => 'yes', :save_scope => 'weekly_rank'
    saveable.save_by :saver => saver, :saved => 'no', :save_scope => 'monthly_rank'
    expect(saveable.saves_for.size).to eq(2)
  end

  it "should be callable with save_up" do
    saveable.save_up saver
    expect(saveable.get_up_saves.first.saver).to eq(saver)
  end

  it "should be callable with save_down" do
    saveable.save_down saver
    expect(saveable.get_down_saves.first.saver).to eq(saver)
  end

  it "should have 2 saves_for when saved on once by two different people" do
    saveable.save_by :saver => saver
    saveable.save_by :saver => saver2
    expect(saveable.saves_for.size).to eq(2)
  end

  it "should have one true saved" do
    saveable.save_by :saver => saver
    saveable.save_by :saver => saver2, :saved => 'dislike'
    expect(saveable.get_up_saves.size).to eq(1)
  end

  it "should have 2 false saves_for" do
    saveable.save_by :saver => saver, :saved => 'no'
    saveable.save_by :saver => saver2, :saved => 'dislike'
    expect(saveable.get_down_saves.size).to eq(2)
  end

  it "should have been saved on by saver2" do
    saveable.save_by :saver => saver2, :saved => true
    expect(saveable.find_saves_for.first.saver.id).to be saver2.id
  end

  it "should count the saved as registered if this is the savers first saved" do
    saveable.save_by :saver => saver
    expect(saveable.save_registered?).to be true
  end

  it "should not count the saved as being registered if that saver has already saved and the saved has not changed" do
    saveable.save_by :saver => saver, :saved => true
    saveable.save_by :saver => saver, :saved => 'yes'
    expect(saveable.save_registered?).to be false
  end

  it "should count the saved as registered if the saver has saved and the saved flag has changed" do
    saveable.save_by :saver => saver, :saved => true
    saveable.save_by :saver => saver, :saved => 'dislike'
    expect(saveable.save_registered?).to be true
  end

  it "should count the saved as registered if the saver has saved and the saved weight has changed" do
    saveable.save_by :saver => saver, :saved => true, :save_weight => 1
    saveable.save_by :saver => saver, :saved => true, :save_weight => 2
    expect(saveable.save_registered?).to be true
  end

  it "should be saved on by saver" do
    saveable.save_by :saver => saver
    expect(saveable.saved_on_by?(saver)).to be true
  end

  it "should be able to unsaved a saver" do
    saveable.upsaved_by(saver)
    saveable.unsave_by(saver)
    expect(saveable.saved_on_by?(saver)).to be false
  end

  it "should unsaved a positive saved" do
    saveable.save_by :saver => saver
    saveable.unsaved :saver => saver
    expect(saveable.find_saves_for.count).to eq(0)
  end

  it "should set the saveable to unregistered after unsaving" do
    saveable.save_by :saver => saver
    saveable.unsaved :saver => saver
    expect(saveable.save_registered?).to be false
  end

  it "should unsaved a negative saved" do
    saveable.save_by :saver => saver, :saved => 'no'
    saveable.unsaved :saver => saver
    expect(saveable.find_saves_for.count).to eq(0)
  end

  it "should unsaved only the from a single saver" do
    saveable.save_by :saver => saver
    saveable.save_by :saver => saver2
    saveable.unsaved :saver => saver
    expect(saveable.find_saves_for.count).to eq(1)
  end

  it "should be contained to instances" do
    saveable2 = Saveable.new(:name => '2nd saveable')
    saveable2.save

    saveable.save_by :saver => saver, :saved => false
    saveable2.save_by :saver => saver, :saved => true
    saveable2.save_by :saver => saver, :saved => true

    expect(saveable.save_registered?).to be true
    expect(saveable2.save_registered?).to be false
  end

  it "should set default saved weight to 1 if not specified" do
    saveable.upsave_by saver
    expect(saveable.find_saves_for.first.save_weight).to eq(1)
  end

  describe "with cached saves_for" do

    before(:each) do
      clean_database
      saver = Saver.new(:name => 'i can saved!')
      saver.save

      saveable = Saveable.new(:name => 'a saving model without a cache')
      saveable.save

      saveable_cache = SaveableCache.new(:name => 'saving model with cache')
      saveable_cache.save
    end

    it "should not update cached saves_for if there are no columns" do
      saveable.save_by :saver => saver
    end

    it "should update cached total saves_for if there is a total column" do
      saveable_cache.cached_saves_total = 50
      saveable_cache.save_by :saver => saver
      expect(saveable_cache.cached_saves_total).to eq(1)
    end

    it "should update cached total saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true'
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_saves_total).to eq(0)
    end

    it "should update cached total saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false'
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_saves_total).to eq(0)
    end

    it "should update cached score saves_for if there is a score column" do
      saveable_cache.cached_saves_score = 50
      saveable_cache.save_by :saver => saver
      expect(saveable_cache.cached_saves_score).to eq(1)
      saveable_cache.save_by :saver => saver2, :saved => 'false'
      expect(saveable_cache.cached_saves_score).to eq(0)
      saveable_cache.save_by :saver => saver, :saved => 'false'
      expect(saveable_cache.cached_saves_score).to eq(-2)
    end

    it "should update cached score saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true'
      expect(saveable_cache.cached_saves_score).to eq(1)
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_saves_score).to eq(0)
    end

    it "should update cached score saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false'
      expect(saveable_cache.cached_saves_score).to eq(-1)
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_saves_score).to eq(0)
    end

    it "should update cached weighted total if there is a weighted total column" do
      saveable_cache.cached_weighted_total = 50
      saveable_cache.save_by :saver => saver
      expect(saveable_cache.cached_weighted_total).to eq(1)
      saveable_cache.save_by :saver => saver2, :saved => 'false'
      expect(saveable_cache.cached_weighted_total).to eq(2)
    end

    it "should update cached weighted total saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_weight => 3
      expect(saveable_cache.cached_weighted_total).to eq(3)
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_weighted_total).to eq(0)
    end

    it "should update cached weighted total saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_weight => 4
      expect(saveable_cache.cached_weighted_total).to eq(4)
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_weighted_total).to eq(0)
    end

    it "should update cached weighted score if there is a weighted score column" do
      saveable_cache.cached_weighted_score = 50
      saveable_cache.save_by :saver => saver, :save_weight => 3
      expect(saveable_cache.cached_weighted_score).to eq(3)
      saveable_cache.save_by :saver => saver2, :saved => 'false', :save_weight => 5
      expect(saveable_cache.cached_weighted_score).to eq(-2)
      # saver changes her saved from 3 to 5
      saveable_cache.save_by :saver => saver, :save_weight => 5
      expect(saveable_cache.cached_weighted_score).to eq(0)
      saveable_cache.save_by :saver => saver3, :save_weight => 4
      expect(saveable_cache.cached_weighted_score).to eq(4)
    end

    it "should update cached weighted score saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_weight => 3
      expect(saveable_cache.cached_weighted_score).to eq(3)
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_weighted_score).to eq(0)
    end

    it "should update cached weighted score saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_weight => 4
      expect(saveable_cache.cached_weighted_score).to eq(-4)
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_weighted_score).to eq(0)
    end

    it "should update cached weighted average if there is a weighted average column" do
      saveable_cache.cached_weighted_average = 50.0
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_weight => 5
      expect(saveable_cache.cached_weighted_average).to eq(5.0)
      saveable_cache.save_by :saver => saver2, :saved => 'true', :save_weight => 3
      expect(saveable_cache.cached_weighted_average).to eq(4.0)
      # saver changes her saved from 5 to 4
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_weight => 4
      expect(saveable_cache.cached_weighted_average).to eq(3.5)
      saveable_cache.save_by :saver => saver3, :saved => 'true', :save_weight => 5
      expect(saveable_cache.cached_weighted_average).to eq(4.0)
    end

    it "should update cached weighted average saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_weight => 5
      saveable_cache.save_by :saver => saver2, :saved => 'true', :save_weight => 3
      expect(saveable_cache.cached_weighted_average).to eq(4)
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_weighted_average).to eq(3)
    end

    it "should update cached up saves_for if there is an up saved column" do
      saveable_cache.cached_saves_up = 50
      saveable_cache.save_by :saver => saver
      saveable_cache.save_by :saver => saver
      expect(saveable_cache.cached_saves_up).to eq(1)
    end

    it "should update cached down saves_for if there is a down saved column" do
      saveable_cache.cached_saves_down = 50
      saveable_cache.save_by :saver => saver, :saved => 'false'
      expect(saveable_cache.cached_saves_down).to eq(1)
    end

    it "should update cached up saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true'
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_saves_up).to eq(0)
    end

    it "should update cached down saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false'
      saveable_cache.unsaved :saver => saver
      expect(saveable_cache.cached_saves_down).to eq(0)
    end

    it "should select from cached total saves_for if there a total column" do
      saveable_cache.save_by :saver => saver
      saveable_cache.cached_saves_total = 50
      expect(saveable_cache.count_saves_total).to eq(50)
    end

    it "should select from cached up saves_for if there is an up saved column" do
      saveable_cache.save_by :saver => saver
      saveable_cache.cached_saves_up = 50
      expect(saveable_cache.count_saves_up).to eq(50)
    end

    it "should select from cached down saves_for if there is a down saved column" do
      saveable_cache.save_by :saver => saver, :saved => 'false'
      saveable_cache.cached_saves_down = 50
      expect(saveable_cache.count_saves_down).to eq(50)
    end

    it "should select from cached weighted total if there is a weighted total column" do
      saveable_cache.save_by :saver => saver, :saved => 'false'
      saveable_cache.cached_weighted_total = 50
      expect(saveable_cache.weighted_total).to eq(50)
    end

    it "should select from cached weighted score if there is a weighted score column" do
      saveable_cache.save_by :saver => saver, :saved => 'false'
      saveable_cache.cached_weighted_score = 50
      expect(saveable_cache.weighted_score).to eq(50)
    end

    it "should select from cached weighted average if there is a weighted average column" do
      saveable_cache.save_by :saver => saver, :saved => 'false'
      saveable_cache.cached_weighted_average = 50
      expect(saveable_cache.weighted_average).to eq(50)
    end

    it "should update cached total saves_for when saving under an scope" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_scope => 'rank'
      expect(saveable_cache.cached_saves_total).to eq(1)
    end

    it "should update cached up saves_for when saving under an scope" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_scope => 'rank'
      expect(saveable_cache.cached_saves_up).to eq(1)
    end

    it "should update cached total saves_for when a scoped saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_scope => 'rank'
      saveable_cache.unsaved :saver => saver, :save_scope => 'rank'
      expect(saveable_cache.cached_saves_total).to eq(0)
    end

    it "should update cached up saves_for when a scoped saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_scope => 'rank'
      saveable_cache.unsaved :saver => saver, :save_scope => 'rank'
      expect(saveable_cache.cached_saves_up).to eq(0)
    end

    it "should update cached down saves_for when downsaving under a scope" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => 'rank'
      expect(saveable_cache.cached_saves_down).to eq(1)
    end

    it "should update cached down saves_for when a scoped saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => 'rank'
      saveable_cache.unsaved :saver => saver, :save_scope => 'rank'
      expect(saveable_cache.cached_saves_down).to eq(0)
    end

  end

  describe "with scoped cached saves_for" do

    it "should update cached total saves_for if there is a total column" do
      saveable_cache.cached_scoped_test_saves_total = 50
      saveable_cache.save_by :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_total).to eq(1)
    end

    it "should update cached total saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_scope => "test"
      saveable_cache.unsaved :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_total).to eq(0)
    end

    it "should update cached total saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => "test"
      saveable_cache.unsaved :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_total).to eq(0)
    end

    it "should update cached score saves_for if there is a score column" do
      saveable_cache.cached_scoped_test_saves_score = 50
      saveable_cache.save_by :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_score).to eq(1)
      saveable_cache.save_by :saver => saver2, :saved => 'false', :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_score).to eq(0)
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_score).to eq(-2)
    end

    it "should update cached score saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_score).to eq(1)
      saveable_cache.unsaved :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_score).to eq(0)
    end

    it "should update cached score saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_score).to eq(-1)
      saveable_cache.unsaved :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_score).to eq(0)
    end

    it "should update cached up saves_for if there is an up saved column" do
      saveable_cache.cached_scoped_test_saves_up = 50
      saveable_cache.save_by :saver => saver, :save_scope => "test"
      saveable_cache.save_by :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_up).to eq(1)
    end

    it "should update cached down saves_for if there is a down saved column" do
      saveable_cache.cached_scoped_test_saves_down = 50
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_down).to eq(1)
    end

    it "should update cached up saves_for when a saved up is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'true', :save_scope => "test"
      saveable_cache.unsaved :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_up).to eq(0)
    end

    it "should update cached down saves_for when a saved down is removed" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => "test"
      saveable_cache.unsaved :saver => saver, :save_scope => "test"
      expect(saveable_cache.cached_scoped_test_saves_down).to eq(0)
    end

    it "should select from cached total saves_for if there a total column" do
      saveable_cache.save_by :saver => saver, :save_scope => "test"
      saveable_cache.cached_scoped_test_saves_total = 50
      expect(saveable_cache.count_saves_total(false, "test")).to eq(50)
    end

    it "should select from cached up saves_for if there is an up saved column" do
      saveable_cache.save_by :saver => saver, :save_scope => "test"
      saveable_cache.cached_scoped_test_saves_up = 50
      expect(saveable_cache.count_saves_up(false, "test")).to eq(50)
    end

    it "should select from cached down saves_for if there is a down saved column" do
      saveable_cache.save_by :saver => saver, :saved => 'false', :save_scope => "test"
      saveable_cache.cached_scoped_test_saves_down = 50
      expect(saveable_cache.count_saves_down(false, "test")).to eq(50)
    end

  end

  describe "sti models" do

    it "should be able to saved on a saveable child of a non saveable sti model" do
      saveable = SaveableChildOfStiNotSaveable.create(:name => 'sti child')

      saveable.save_by :saver => saver, :saved => 'yes'
      expect(saveable.saves_for.size).to eq(1)
    end

    it "should not be able to saved on a parent non saveable" do
      expect(StiNotSaveable).not_to be_saveable
    end

    it "should be able to saved on a child when its parent is saveable" do
      saveable = ChildOfStiSaveable.create(:name => 'sti child')

      saveable.save_by :saver => saver, :saved => 'yes'
      expect(saveable.saves_for.size).to eq(1)
    end
  end
end
