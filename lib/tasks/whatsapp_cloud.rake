require_relative '../../config/environment'
namespace :whatsapp_cloud do

  task :get_app_id do
		channels = Channel::Whatsapp.where(provider: 'whatsapp_cloud')

		channels.each do |channel|
			Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel).get_app_id
		end
	end

end