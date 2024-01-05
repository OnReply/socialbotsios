/* global axios */
import ApiClient from './ApiClient';
import { serialize } from 'object-to-formdata';

class AutomationsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }

  create(data) {
    const formData = serialize(data)
    // Recursively traverse the data object and append values to formData
    return axios.post(this.url, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  update(automationId, data) {
    if ('conditions' in data) {
      data.conditions = data.conditions.map(condition => {
        const sortedKeys = Object.keys(condition).sort();
        const sortedCondition = sortedKeys.reduce((sortedObj, key) => {
          sortedObj[key] = condition[key];
          return sortedObj;
        }, {});
        return sortedCondition;
      });
    }
    if ('actions' in data) {
      data.actions = data.actions.map(action => {
        const sortedKeys = Object.keys(action).sort();
        const sortedAction = sortedKeys.reduce((sortedObj, key) => {
          sortedObj[key] = action[key];
          return sortedObj;
        }, {});
        return sortedAction;
      });
    }
    // Recursively traverse the data object and append values to formData
    return axios.patch(`${this.url}/${automationId}`, serialize(data), {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }
  clone(automationId) {
    return axios.post(`${this.url}/${automationId}/clone`);
  }

  attachment(file) {
    return axios.post(`${this.url}/attach_file`, file, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }
}

export default new AutomationsAPI();
