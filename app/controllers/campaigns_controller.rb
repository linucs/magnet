class CampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_campaign, only: [:edit, :update, :destroy]

  add_crumb('Adv campaigns') { |instance| instance.send :campaigns_path }

  respond_to :js

  def index
    load_campaigns
    authorize! :index, Campaign
    @campaign = Campaign.new
    respond_with(@campaigns) do |format|
      format.html { render }
    end
  end

  def new
    @campaign = Campaign.new
    respond_with(@campaign)
  end

  def edit
    authorize! :edit, @campaign
  end

  def create
    @campaign = Campaign.new(campaign_params)
    @campaign.team_id = current_user.team_id
    authorize! :create, @campaign
    @campaign.save
    respond_with(@campaign) do |format|
      format.js do
        load_campaigns
      end
    end
  end

  def update
    authorize! :update, @campaign
    @campaign.update(campaign_params)
    respond_with(@campaign) do |format|
      format.js { load_campaigns }
    end
  end

  def destroy
    authorize! :destroy, @campaign
    @campaign.destroy
    respond_with(@campaign) do |format|
      format.js { load_campaigns }
    end
  end

  private

  def load_campaigns
    @campaigns = Campaign.of_teammates(current_user).rank(:row_order).page(params[:page])
  end

  def set_campaign
    @campaign = Campaign.of_teammates(current_user).find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:enabled, :name, :board_id, :row_order_position, :threshold, :content,
    :start_displaying_at, :end_displaying_at, :activate_on_deck, :activate_on_timeline, :activate_on_wall)
  end
end
