class Public::Api::V1::PortalsController < Public::Api::V1::Portals::BaseController
  before_action :ensure_custom_domain_request, only: [:show]
  before_action :portal
  before_action :redirect_to_portal_with_locale, only: [:show]
  before_action :verify_authenticity_token
  layout 'portal'

  def show
    head :forbidden if current_user.nil?
  end

  private

  def portal
    @portal ||= Portal.find_by!(slug: params[:slug], archived: false)
    @locale = params[:locale] || @portal.default_locale
  end

  def redirect_to_portal_with_locale
    return if params[:locale].present?

    redirect_to "/hc/#{@portal.slug}/#{@portal.default_locale}"
  end
end
