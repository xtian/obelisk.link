# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tag do
  describe 'validations' do
    it 'allows a valid tag to be created' do
      valid_params = { tag: 'tag_name', hotness_mod: 0.25, description: 'test description' }

      expect(described_class.create(valid_params))
        .to be_valid
    end

    it 'does not allow a tag to be saved without a name' do
      expect(described_class.create).not_to be_valid
    end

    it 'does not allow an empty tag to be saved' do
      expect(described_class.create(tag: '')).not_to be_valid
    end

    it 'does not allow a tag with a name too long to be saved' do
      expect(described_class.create(tag: 'tag_name' * 20)).not_to be_valid
    end

    it 'does not allow a tag with a hotness_mod too high to be saved' do
      expect(described_class.create(tag: 'tag_name', hotness_mod: 25)).not_to be_valid
    end

    it 'does not allow a tag with a hotness_mod too low to be saved' do
      expect(described_class.create(tag: 'tag_name', hotness_mod: -15)).not_to be_valid
    end

    it 'does not allow a tag with a description too long to be saved' do
      expect(described_class.create(tag: 'tag_name', description: 'test_desc' * 20)).not_to be_valid
    end
  end

  describe 'logs modification in moderation log' do
    let(:user) { create(:user) }

    it 'logs on create' do
      expect { described_class.create(tag: 'tag_name', edit_user_id: user.id) }
        .to(change(Moderation, :count))
      mod = Moderation.order(id: :desc).first
      expect(mod.action).to include 'tag_name'
      expect(mod.moderator_user_id).to be user.id
    end

    it 'logs on update' do
      expect { described_class.first.update(tag: 'new_tag_name', edit_user_id: user.id) }
        .to(change(Moderation, :count))
      mod = Moderation.order(id: :desc).first
      expect(mod.action).to include 'new_tag_name'
      expect(mod.moderator_user_id).to be user.id
    end
  end
end
