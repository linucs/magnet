class TeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, only: [:edit, :update, :destroy]

  add_crumb('Platform user teams') { |instance| instance.send :teams_path }

  respond_to :js

  def index
    load_teams
    authorize! :index, Team
    respond_with(@teams) do |format|
      format.html { render }
    end
  end

  def new
    @team = Team.new
    respond_with(@team)
  end

  def edit
    authorize! :edit, @team
  end

  def create
    @team = Team.new(team_params)
    authorize! :create, @team
    @team.save
    respond_with(@team) do |format|
      format.js do
        load_teams
      end
    end
  end

  def update
    authorize! :update, @team
    @team.update(team_params)
    respond_with(@team) do |format|
      format.js { load_teams }
    end
  end

  def destroy
    authorize! :destroy, @team
    @team.destroy
    respond_with(@team) do |format|
      format.js { load_teams }
    end
  end

  private

  def load_teams
    @teams = Team.search(params[:q]).result.page(params[:page])
  end

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :enabled, user_ids: [])
  end
end
