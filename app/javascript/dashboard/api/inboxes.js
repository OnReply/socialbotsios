/* global axios */
import CacheEnabledApiClient from './CacheEnabledApiClient';

class Inboxes extends CacheEnabledApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'inbox';
  }

  getCampaigns(inboxId) {
    return axios.get(`${this.url}/${inboxId}/campaigns`);
  }

  deleteInboxAvatar(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/avatar`);
  }

  refreshToken(inboxId, refreshed) {
    return axios.post(`${this.url}/${inboxId}/refresh_token`, {
      refreshed: refreshed,
    });
  }

  getAgentBot(inboxId) {
    return axios.get(`${this.url}/${inboxId}/agent_bot`);
  }

  createTemplate(inboxId, template, headerType, image, buttonType, buttonData) {
    var params_template = template
    params_template.components = template.components.filter(component => component.text)
    const formData = new FormData();
    if (headerType == 'image') {
      params_template.components = template.components.filter(component => component.type != 'HEADER')
      formData.append("image", image);
    } else if (headerType == 'none') {
      params_template.components = template.components.filter(component => component.type != 'HEADER')
    }
    if (buttonType !== 'none') {
      params_template.components.push({"type": "BUTTONS", "buttons": buttonData})
    }
    formData.append("template", JSON.stringify(params_template));
    formData.append("header_type", headerType);
    return axios.post(`${this.url}/${inboxId}/template`, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
  }
  UpdateProfilePicture(inboxId, image, profile) {
    const formData = new FormData();
    if (image !== '' ||  image !== undefined)
      formData.append("image", image);
    formData.append("profile", JSON.stringify(profile))
    return axios.post(`${this.url}/${inboxId}/update_profile_picture`, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
  }

  setAgentBot(inboxId, botId) {
    return axios.post(`${this.url}/${inboxId}/set_agent_bot`, {
      agent_bot: botId,
    });
  }

  deleteTemplate(inboxId, template) {
    return axios.delete(`${this.url}/${inboxId}/delete_template?name=${template.name}`);
  }
}

export default new Inboxes();
