class Issues::IssuesUpdatesController < ApplicationController
  include IssueScoped
  before_action :require_user, only: [ :create, :edit, :update ]
  before_action :ensure_citizen
  before_action :check_permissions
  before_action :check_rate_limit, only: [ :new, :create ]

  def show
    redirect_to @issue, status: :moved_permanently
  end

  def index
    redirect_to @issue, status: :moved_permanently
  end

  def new
    @update = Issues::Update.new
    @update.resolves_issue = true if params[:verification].present?
  end

  def edit
    @update = current_user.issues_updates.find(params[:id])
  end

  def update
    @update = current_user.issues_updates.find(params[:id])
    @update.assign_attributes(update_params)
    if @update.save(context: :edit)
      render @update
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @update = Issues::Update.new(update_params)
    @update.build_activity(issue: @issue, type: Issues::UpdateActivity)
    @update.author = current_user
    @update.published = true

    if @update.save
      respond_to do |format|
        format.turbo_stream
        format.html {
          notice_message = @update.resolves_issue? ? "Podnet bol označený za vyriešený" : "Aktualizácia podnetu bola pridaná"
          redirect_to @issue, notice: notice_message
        }
      end
      Issues::SyncEditableActivityToTriageJob.perform_later(@update, sync_job: SyncIssueActivityObjectToTriageJob)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived?
  end

  def update_params
    params.require(:issues_update).permit(:text, :resolves_issue, attachments: [])
  end

  def check_rate_limit
    redirect_to_with_turbo please_wait_profile_path if current_user.create_issue_update_limit_exceeded?
  end
end
