class CampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_campaign, only: [:edit, :update, :destroy]

  add_crumb('Advertising campaigns') { |instance| instance.send :campaigns_path }

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
    @campaigns = Campaign.rank(:row_order).page(params[:page])
  end

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:enabled, :name, :board_id, :row_order_position, :threshold, :content,
    :start_displaying_at, :end_displaying_at)
  end
end
