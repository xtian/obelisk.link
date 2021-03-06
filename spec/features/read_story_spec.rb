# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Reading Stories' do
  let!(:story) { create(:story) }
  let!(:comment) { create(:comment, story: story) }

  describe 'when logged out' do
    scenario 'reading a story' do
      visit "/s/#{story.short_id}"
      expect(page).to have_content(story.title)
      expect(page).to have_content(comment.comment)
    end
  end

  describe 'when logged in' do
    let(:user) { create(:user) }

    before { stub_login_as user }

    scenario 'reading a story' do
      visit "/s/#{story.short_id}"
      expect(page).to have_content(story.title)
      expect(page).to have_content(comment.comment)

      fill_in 'comment', with: 'New reply'
      click_button 'Post'

      expect(page).to have_content('New reply')
    end
  end
end
