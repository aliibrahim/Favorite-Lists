shared_examples "a saver_model" do
  let (:saveable_klass) { saveable.class }

  it "should be saved on after a saver has saved" do
    saveable.save_by :saver => saver
    expect(saver.saved_on?(saveable)).to be true
    expect(saver.saved_for?(saveable)).to be true
  end

  it "should not be saved on if a saver has not saved" do
    expect(saver.saved_on?(saveable)).to be false
  end

  it "should be saved on after a saver has saved under scope" do
    saveable.save_by :saver => saver, :save_scope => 'rank'
    expect(saver.saved_on?(saveable, :save_scope => 'rank')).to be true
  end

  it "should not be saved on other scope after a saver has saved under one scope" do
    saveable.save_by :saver => saver, :save_scope => 'rank'
    expect(saver.saved_on?(saveable)).to be false
  end

  it "should be saved as true when a saver has saved true" do
    saveable.save_by :saver => saver
    expect(saver.saved_as_when_saved_on(saveable)).to be true
    expect(saver.saved_as_when_saved_for(saveable)).to be true
  end

  it "should be saved as true when a saver has saved true under scope" do
    saveable.save_by :saver => saver, :save_scope => 'rank'
    expect(saver.saved_as_when_saved_for(saveable, :save_scope => 'rank')).to be true
  end

  it "should be saved as false when a saver has saved false" do
    saveable.save_by :saver => saver, :saved => false
    expect(saver.saved_as_when_saved_for(saveable)).to be false
  end

  it "should be saved as false when a saver has saved false under scope" do
    saveable.save_by :saver => saver, :saved => false, :save_scope => 'rank'
    expect(saver.saved_as_when_saved_for(saveable, :save_scope => 'rank')).to be false
  end

  it "should be saved as nil when a saver has never saved" do
    expect(saver.saved_as_when_saving_on(saveable)).to be nil
  end

  it "should be saved as nil when a saver has never saved under the scope" do
    saveable.save_by :saver => saver, :saved => false, :save_scope => 'rank'
    expect(saver.saved_as_when_saving_on(saveable)).to be nil
  end

  it "should return true if saver has saved true" do
    saveable.save_by :saver => saver
    expect(saver.saved_up_on?(saveable)).to be true
  end

  it "should return false if saver has not saved true" do
    saveable.save_by :saver => saver, :saved => false
    expect(saver.saved_up_on?(saveable)).to be false
  end

  it "should return true if the saver has saved false" do
    saveable.save_by :saver => saver, :saved => false
    expect(saver.saved_down_on?(saveable)).to be true
  end

  it "should return false if the saver has not saved false" do
    saveable.save_by :saver => saver, :saved => true
    expect(saver.saved_down_on?(saveable)).to be false
  end

  it "should provide reserve functionality, saver can saved on saveable" do
    saver.saved :saveable => saveable, :saved => 'bad'
    expect(saver.saved_as_when_saving_on(saveable)).to be false
  end

  it "should allow the saver to saved up a model" do
    saver.save_up_for saveable
    expect(saveable.get_up_saves.first.saver).to eq(saver)
    expect(saveable.saves_for.up.first.saver).to eq(saver)
  end

  it "should allow the saver to saved down a model" do
    saver.save_down_for saveable
    expect(saveable.get_down_saves.first.saver).to eq(saver)
    expect(saveable.saves_for.down.first.saver).to eq(saver)
  end

  it "should allow the saver to unsaved a model" do
    saver.save_up_for saveable
    saver.unsave_for saveable
    expect(saveable.find_saves_for.size).to eq(0)
    expect(saveable.saves_for.count).to eq(0)
  end

  it "should get all of the savers saves" do
    saver.save_up_for saveable
    expect(saver.find_saves.size).to eq(1)
    expect(saver.saves.up.count).to eq(1)
  end

  it "should get all of the savers up saves" do
    saver.save_up_for saveable
    expect(saver.find_up_saves.size).to eq(1)
    expect(saver.saves.up.count).to eq(1)
  end

  it "should get all of the savers down saves" do
    saver.save_down_for saveable
    expect(saver.find_down_saves.size).to eq(1)
    expect(saver.saves.down.count).to eq(1)
  end

  it "should get all of the saves saves for a class" do
    saveable.save_by :saver => saver
    saveable2.save_by :saver => saver, :saved => false
    expect(saver.find_saves_for_class(saveable_klass).size).to eq(2)
    expect(saver.saves.for_type(saveable_klass).count).to eq(2)
  end

  it "should get all of the savers up saves for a class" do
    saveable.save_by :saver => saver
    saveable2.save_by :saver => saver, :saved => false
    expect(saver.find_up_saves_for_class(saveable_klass).size).to eq(1)
    expect(saver.saves.up.for_type(saveable_klass).count).to eq(1)
  end

  it "should get all of the savers down saves for a class" do
    saveable.save_by :saver => saver
    saveable2.save_by :saver => saver, :saved => false
    expect(saver.find_down_saves_for_class(saveable_klass).size).to eq(1)
    expect(saver.saves.down.for_type(saveable_klass).count).to eq(1)
  end

  it "should be contained to instances" do
    saver.saved :saveable => saveable, :saved => false
    saver2.saved :saveable => saveable

    expect(saver.saved_as_when_saving_on(saveable)).to be false
  end

  describe '#find_saved_items' do
    it 'returns objects that a user has upsaved for' do
      saveable.save_by :saver => saver
      saveable2.save_by :saver => saver2
      expect(saver.find_saved_items).to include saveable
      expect(saver.find_saved_items.size).to eq(1)
    end

    it 'returns objects that a user has upsaved for, using scope' do
      saveable.save_by :saver => saver, :save_scope => 'rank'
      saveable2.save_by :saver => saver2, :save_scope => 'rank'
      expect(saver.find_saved_items(:save_scope => 'rank')).to include saveable
      expect(saver.find_saved_items(:save_scope => 'rank').size).to eq(1)
    end

    it 'returns objects that a user has downsaved for' do
      saveable.save_down saver
      saveable2.save_down saver2
      expect(saver.find_saved_items).to include saveable
      expect(saver.find_saved_items.size).to eq(1)
    end

    it 'returns objects that a user has downsaved for, using scope' do
      saveable.save_down saver, :save_scope => 'rank'
      saveable2.save_down saver2, :save_scope => 'rank'
      expect(saver.find_saved_items(:save_scope => 'rank')).to include saveable
      expect(saver.find_saved_items(:save_scope => 'rank').size).to eq(1)
    end
  end

  describe '#find_up_saved_items' do
    it 'returns objects that a user has upsaved for' do
      saveable.save_by :saver => saver
      saveable2.save_by :saver => saver2
      expect(saver.find_up_saved_items).to include saveable
      expect(saver.find_up_saved_items.size).to eq(1)
    end

    it 'returns objects that a user has upsaved for, using scope' do
      saveable.save_by :saver => saver, :save_scope => 'rank'
      saveable2.save_by :saver => saver2, :save_scope => 'rank'
      expect(saver.find_up_saved_items(:save_scope => 'rank')).to include saveable
      expect(saver.find_up_saved_items(:save_scope => 'rank').size).to eq(1)
    end

    it 'does not return objects that a user has downsaved for' do
      saveable.save_down saver
      expect(saver.find_up_saved_items.size).to eq(0)
    end

    it 'does not return objects that a user has downsaved for, using scope' do
      saveable.save_down saver, :save_scope => 'rank'
      expect(saver.find_up_saved_items(:save_scope => 'rank').size).to eq(0)
    end
  end

  describe '#find_down_saved_items' do
    it 'does not return objects that a user has upsaved for' do
      saveable.save_by :saver => saver
      expect(saver.find_down_saved_items.size).to eq(0)
    end

    it 'does not return objects that a user has upsaved for, using scope' do
      saveable.save_by :saver => saver, :save_scope => 'rank'
      expect(saver.find_down_saved_items(:save_scope => 'rank').size).to eq(0)
    end

    it 'returns objects that a user has downsaved for' do
      saveable.save_down saver
      saveable2.save_down saver2
      expect(saver.find_down_saved_items).to include saveable
      expect(saver.find_down_saved_items.size).to eq(1)
    end

    it 'returns objects that a user has downsaved for, using scope' do
      saveable.save_down saver, :save_scope => 'rank'
      saveable2.save_down saver2, :save_scope => 'rank'
      expect(saver.find_down_saved_items(:save_scope => 'rank')).to include saveable
      expect(saver.find_down_saved_items(:save_scope => 'rank').size).to eq(1)
    end

 end

  describe '#get_saved' do
    subject { saver.get_saved(saveable.class) }

    it 'returns objects of a class that a saver has saved for' do
      saveable.save_by :saver => saver
      saveable2.save_down saver
      expect(subject).to include saveable
      expect(subject).to include saveable2
      expect(subject.size).to eq(2)
    end

    it 'does not return objects of a class that a saver has saved for' do
      saveable.save_by :saver => saver2
      saveable2.save_by :saver => saver2
      expect(subject.size).to eq(0)
    end
  end

  describe '#get_up_saved' do
    subject { saver.get_up_saved(saveable.class) }

    it 'returns up saved items that a saver has saved for' do
      saveable.save_by :saver => saver
      expect(subject).to include saveable
      expect(subject.size).to eq(1)
    end

    it 'does not return down saved items a saver has saved for' do
      saveable.save_down saver
      expect(subject.size).to eq(0)
    end
  end

  describe '#get_down_saved' do
    subject { saver.get_down_saved(saveable.class) }

    it 'does not return up saved items that a saver has saved for' do
      saveable.save_by :saver => saver
      expect(subject.size).to eq(0)
    end

    it 'returns down saved items a saver has saved for' do
      saveable.save_down saver
      expect(subject).to include saveable
      expect(subject.size).to eq(1)
    end
  end

end
