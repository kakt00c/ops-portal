class IssuesController < ApplicationController
  before_action :ensure_user_onboarded
  before_action :set_issue, only: %i[ show edit update ]
  before_action :force_responsible_subject_login, only: :show, if: -> { params.key?(:force_rs_login) }
  before_action :check_show_permissions, only: :show
  before_action :check_edit_permissions, only: %i[ edit update ]

  def relevant
    path = if current_user.responsible_subject
      issues_path(zodpovedny: current_user.responsible_subject.subject_name)
    elsif session[:last_municipality].present?
      issues_path(obec: session[:last_municipality], cast: session[:last_municipality_district].presence)
    elsif current_user.municipality
      issues_path(obec: current_user.municipality.name)
    else
      issues_path
    end

    redirect_to path
  end

  def index
    if params[:obec].present?
      session[:last_municipality] = params[:obec]
      session[:last_municipality_district] = params[:cast]
    else
      session.delete(:last_municipality)
      session.delete(:last_municipality_district)
    end

    @tab = params[:tab].in?(%w[map stats]) ? params[:tab] : "list"

    scope = Issue.searchable.includes(:state, :municipality_district, :municipality, :responsible_subject)

    case @tab
    when "list"
        scope = scope.with_attached_photos
        @search_results = search_engine.search(scope, params)
    when "stats"
        @search_results = search_engine.stats(scope, params) do |scope, results|
          results.stats = {
            by_state: scope.group("state").order("count_all DESC").async_count,
            by_category: scope.group("category").order("count_all DESC").async_count,
            by_responsible_subject: scope.group("responsible_subject").order("count_all DESC").async_count
          }
        end
    when "map"
        @search_results = search_engine.search(scope, params)
    end
  end

  def geo
    scope = Issue.searchable.includes(:state)

    @search_results = search_engine.stats(scope, params) do |scope, results|
      target_zoom = case params[:z].to_i
      when 1..5
          2
      when 6..7
          3
      when 8..10
          4
      when 11..12
          5
      when 13..15
          6
      when 16..17
          7
      when 18..20
          18
      else
          4
      end

      issues_groups_scope = scope
        .select("avg(latitude) avg_latitude, avg(longitude) as avg_longitude,
                min(latitude) as min_latitude, max(latitude) as max_latitude,
                min(longitude) as min_longitude, max(longitude) as max_longitude,
                count(*) as count")
        .group("st_geohash(st_point(issues.longitude, issues.latitude, 4326), #{target_zoom})")
        .where("st_point(longitude, latitude, 4326) && st_makeenvelope(?, ?, ?, ?, 4326)", *params[:bbox].split(",").map(&:to_f))
        .reorder("")

      lateral_join_scope = scope.unscoped
        .where("st_point(longitude, latitude, 4326) && st_point(issue_groups.avg_longitude, issue_groups.avg_latitude, 4326)")
        .limit(1)

      scope = scope.unscoped
        .select("i.*, issue_groups.*")
        .joins("LEFT JOIN LATERAL (#{lateral_join_scope.to_sql}) AS i ON true")
        .from("(#{issues_groups_scope.to_sql}) issue_groups")

      results.stats = {
        aggs_by_geohash: scope.includes(:municipality, :municipality_district)
      }
    end
  end

  # GET /issues/1 or /issues/1.json
  def show
    @activity_objects = @issue.visible_activity_objects
  end

  def edit
  end

  def update
    @issue.assign_attributes(issue_params)
    if @issue.save
      SyncIssueToTriageJob.perform_later(@issue, sync_activities: false)
      redirect_to @issue
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_issue
    @issue = Issue.find(params.expect(:id))
  end

  def issue_params
    params.expect(issue: [ :title, :description, photos: [] ])
  end

  def force_responsible_subject_login
    if current_user.responsible_subject
      redirect_to request.path
    else
      session[:login_redirect] = request.path
      session[:force_rs_login] = true
      redirect_to rodauth.email_auth_request_path
    end
  end

  def check_show_permissions
    raise ActionController::RoutingError.new("Not Found") unless @issue.viewable_by?(current_user)
  end

  def check_edit_permissions
    raise ActionController::RoutingError.new("Not Found") unless @issue.editable_by?(current_user)
  end

  ZAMMAD_TICKET_NAME_REGEXP = /Tic?ket#.-(\d+)/ # Ticket#T-300000, Tiket#R-300000

  def search_engine
    SearchEngine.new(
      filters: [
        SearchEngine::Controls::Dropdown.new(
          param_name: :dopyt,
          label: "Typ dopytu",
          items: %w[Podnet Otázka Pochvala],
          filter: ->(scope, params) do
            map = {
              "Podnet" => :issue,
              "Pochvala" => :praise,
              "Otázka" => :question
            }

            scope.where(issue_type: map.values_at(*Array(params[:dopyt])))
          end,
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :stav,
          label: "Stav podnetu",
          items: -> do
            Issues::State.order(:name).pluck(:name) -
            [ "Archivovaný", "Čakajúci", "Čaká na autora", "Zamietnutý", "Vyriešený (skrytý)", "Duplicitný" ] +
            [ "Archivovaný" ] # add as last option
          end,
          filter: ->(scope, params) do
            # push down ids as constants so optimizer can use stats
            ids = Issues::State.where(name: params[:stav]).pluck(:id)
            scope.where(state_id: ids)
          end,
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :kategoria,
          label: "Kategória",
          items: -> { Issues::Category.non_legacy.order(:name).distinct.pluck(:name) },
          filter: ->(scope, params) do
            if params[:kategoria] == "Bez kategórie"
              scope.where(category_id: nil)
            else
              # push down ids as constants so optimizer can use stats
              ids = Issues::Category.non_legacy.where(name: params[:kategoria]).pluck(:id)
              scope.where(category_id: ids)
            end
          end,
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :podkategoria,
          label: "Podkategória",
          items: ->(params) do
            return [] unless params[:kategoria]

            Issues::Subcategory.non_legacy.joins(:category)
              .where(issues_categories: { name: params[:kategoria] })
              .order(:name)
              .pluck(:name)
              .uniq
          end,
          filter: ->(scope, params) do
            # push down ids as constants so optimizer can use stats
            ids = Issues::Subcategory.non_legacy
              .where(name: params[:podkategoria])
              .pluck(:id)
            scope.where(subcategory_id: ids)
          end
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :typ,
          filter: ->(scope, params) do
            # push down ids as constants so optimizer can use stats
            ids = Issues::Subtype.where(name: params[:typ]).pluck(:id)
            scope.where(subtype_id: ids)
          end
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :ulica,
          filter: ->(scope, params) { scope.where(address_street: params[:ulica]) }
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :pin,
          filter_label: "vzdialenosť do 500m",
          filter: ->(scope, params) do
            return scope unless params[:pin].present?

            distance = 500

            lat, lon = params[:pin].split(",", 2).map(&:to_f)

            scope.within_distance_from_point(lat, lon, distance)
          end
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :oblast,
          filter_label: "Oblasť na mape",
          filter: ->(scope, params) do
            return scope unless params[:oblast].present?

            bbox = params[:oblast].split(",", 4).map(&:to_f)

            scope.within_bbox(bbox)
          end
        ),

        SearchEngine::Controls::Autocomplete.new(
          param_name: :obec,
          label: "Obec",
          items: -> { Municipality.active.where(active_on_old_portal: false).order(Arel.sql("name COLLATE unicode")).pluck(:name) },
          filter: ->(scope, params) do
            # push down ids as constants so optimizer can use stats
            ids = Municipality.active.where(name: params[:obec]).pluck(:id)
            scope.where(municipality_id: ids)
          end
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :cast,
          label: "Mestská časť",
          items: ->(params) do
            return [] unless params[:obec].present?

            MunicipalityDistrict.joins(:municipality)
              .where(municipalities: { name: params[:obec], active: true })
              .order(Arel.sql("municipality_districts.name COLLATE unicode"))
              .pluck(:name)
          end,
          filter: ->(scope, params) do
            # push down ids as constants so optimizer can use stats
            ids = MunicipalityDistrict.where(name: params[:cast]).pluck(:id)
            scope.where(municipality_district_id: ids)
          end
        ),

        SearchEngine::Controls::Autocomplete.new(
          param_name: :zodpovedny,
          label: "Zodpovedný subjekt",
          items: -> { ResponsibleSubject.active.order(Arel.sql("subject_name COLLATE unicode")).pluck("subject_name").uniq },
          filter: ->(scope, params) do
            # push down ids as constants so optimizer can use stats
            ids = ResponsibleSubject.active.where(subject_name: params[:zodpovedny]).pluck(:id)
            scope.where(responsible_subject_id: ids)
          end
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :obdobie,
          label: "Obdobie",
          default_label: "Celé",
          items: [
            "Posledných 30 dní",
            "Tento rok",
            "Minulý rok"
          ],
          multiple: false,
          sort: false,
          filter: ->(scope, params) do
            case params[:obdobie]
            when "Posledných 30 dní"
              scope = scope.where(resolution_started_at: 30.days.ago..)
            when "Tento rok"
              scope = scope.where(resolution_started_at: Date.current.beginning_of_year..)
            when "Minulý rok"
              scope = scope.where(resolution_started_at: 1.year.ago.beginning_of_year..1.year.ago.end_of_year)
            end

            scope
          end
        ),

        SearchEngine::Controls::SearchField.new(
          param_name: :q,
          label: "Textové vyhľadávanie",
          filter: ->(scope, params) do
            id_match = params[:q][ZAMMAD_TICKET_NAME_REGEXP, 1]

            if id_match.present?
              scope.where(id: id_match)
            else
              scope.fulltext_search(
                params[:q],
                against: [ :title, :description, :legacy_id, :id, :fulltext_extra ],
                unaccent_f: :f_unaccent
              )
            end
          end,
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :zobrazit,
          label: "Zobrazovať",
          items: -> { logged_in? ? [ "Moje dopyty", "Sledované dopyty" ] : [] },
          multiple: false,
          default_label: "Všetko",
          filter: ->(scope, params) do
            return scope unless logged_in?
            return scope unless params[:zobrazit].present?

            case params[:zobrazit]
            when "Moje dopyty"
              scope.where(author_id: current_user.id)
            when "Sledované dopyty"
              scope.joins(:subscriptions).where(issue_subscriptions: { subscriber_id: current_user.id })
            else
              scope
            end
          end
        )
      ],

      sorts: [
        SearchEngine::Controls::Sort.new(
          name: :nove,
          label: "Najnovšie",
          apply_if: ->(params) do
            return false unless params[:sort].nil? || params[:sort] == "nove"
            return false if params[:pin].present? && (params[:sort].nil? || params[:sort] == "vzd")

            true
          end,
          order: ->(scope, _) { scope.newest }
        ),

        SearchEngine::Controls::Sort.new(
          name: :oblubene,
          label: "Najobľúbenejšie",
          order: ->(scope, _) { scope.order(likes_count: :desc, resolution_started_at: :desc) }
        ),

        SearchEngine::Controls::Sort.new(
          name: :komentare,
          label: "Najkomentovanejšie",
          order: ->(scope, _) { scope.order(comments_count: :desc, resolution_started_at: :desc) }
        ),

        SearchEngine::Controls::Sort.new(
          name: :komentovane,
          label: "Naposledy komentované",
          order: ->(scope, _) do
            scope.order("last_activity_at DESC NULLS LAST")
          end
        ),

        SearchEngine::Controls::Sort.new(
          name: :zodpovedane,
          label: "Naposledy zodpovedané",
          order: ->(scope, _) do
            scope.where.not(responsible_subject_last_contact_at: nil)
              .order(responsible_subject_last_contact_at: :desc)
          end
        ),

        SearchEngine::Controls::Sort.new(
          name: :vzd,
          label: "Najbližšie",
          visible_if: ->(params) { params[:pin].present? },
          apply_if: ->(params) do
            return false unless params[:sort].nil? || params[:sort] == "vzd"
            return false unless params[:pin].present?

            true
          end,
          order: ->(scope, params) do
            lat, lon = params[:pin].split(",", 2).map(&:to_f)

            scope.order_by_distance_from_point(lat, lon)
          end
        )
      ],

      per_page: 12,
      default_permitted_params: [ "tab" ]
    )
  end
end
