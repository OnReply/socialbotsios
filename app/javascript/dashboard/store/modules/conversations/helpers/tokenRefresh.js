/* global FB */

import {
  unloadFacebookSDK,
  loadFBsdk,
} from '../../../../../shared/helpers/facebookInitializer';
import ChannelApi from '../../../../api/channels';
import InboxesAPI from '../../../../api/inboxes';
export const refreshToken = async accountID => {
  return new Promise(resolve => {
    loadFBsdk();
    if (window.fbSDKLoaded === undefined) {
      window.fbAsyncInit = () => {
        FB.init({
          appId: window.chatwootConfig.fbAppId,
          xfbml: true,
          version: window.chatwootConfig.fbApiVersion,
          status: true,
        });
        let response = ChannelApi.fetchFacebookTokens(accountID);
        response.then(res => {
          res.data.tokens.forEach(token => {
            FB.api(`/me?access_token=${token.key}`, res => {
              if (res.error) {
                InboxesAPI.refreshToken(token.id, false);
              } else {
                InboxesAPI.refreshToken(token.id, true);
              }
            });
          });
          unloadFacebookSDK();
        });
        window.fbSDKLoaded = true;
        // FB.api(`/me?access_token=${selectedChat.meta.access_token}`);
      };
    }

    resolve();
  });
  // FB.api('/me',{accessToken: selectedChat.meta.accessToken})
};
