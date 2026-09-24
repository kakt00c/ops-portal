class Issues::Drafts::SummariesController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped

  def show
  end
end
