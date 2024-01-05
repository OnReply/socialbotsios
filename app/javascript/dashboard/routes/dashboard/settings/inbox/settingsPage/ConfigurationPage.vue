<template>
  <div v-if="isATwilioChannel" class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
      :sub-title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </settings-section>
  </div>
  <div v-else-if="isALineChannel" class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.TITLE')"
      :sub-title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </settings-section>
  </div>
  <div v-else-if="isAWebWidgetInbox">
    <div class="settings--content">
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
      >
        <woot-code
          :script="inbox.web_widget_script"
          lang="html"
          :codepen-title="`${inbox.name} - Chatwoot Widget Test`"
          :enable-code-pen="true"
        />
      </settings-section>

      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      >
        <woot-code :script="inbox.hmac_token" />
        <template #subTitle>
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION') }}
          <a
            target="_blank"
            rel="noopener noreferrer"
            href="https://www.chatwoot.com/docs/product/channels/live-chat/sdk/identity-validation/"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_LINK_TO_DOCS') }}
          </a>
        </template>
      </settings-section>
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
      >
        <div class="enter-to-send--checkbox">
          <input
            id="hmacMandatory"
            v-model="hmacMandatory"
            type="checkbox"
            @change="handleHmacFlag"
          />
          <label for="hmacMandatory">
            {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
          </label>
        </div>
      </settings-section>
    </div>
  </div>
  <div v-else-if="isAPIInbox" class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER_SUB_TEXT')"
    >
      <woot-code :script="inbox.inbox_identifier" />
    </settings-section>

    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION')"
    >
      <woot-code :script="inbox.hmac_token" />
    </settings-section>
    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
    >
      <div class="enter-to-send--checkbox">
        <input
          id="hmacMandatory"
          v-model="hmacMandatory"
          type="checkbox"
          @change="handleHmacFlag"
        />
        <label for="hmacMandatory">
          {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
        </label>
      </div>
    </settings-section>
  </div>
  <div v-else-if="isAnEmailChannel">
    <div class="settings--content">
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_SUB_TEXT')"
      >
        <woot-code :script="inbox.forward_to_email" />
      </settings-section>
    </div>
    <imap-settings :inbox="inbox" />
    <smtp-settings v-if="inbox.imap_enabled" :inbox="inbox" />
    <microsoft-reauthorize
      v-if="inbox.microsoft_reauthorization"
      :inbox="inbox"
    />
  </div>
  <div v-else-if="isAWhatsAppChannel && !isATwilioChannel">
    <div v-if="inbox.provider_config" class="settings--content">
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_SUBHEADER')"
      >
        <woot-code :script="inbox.provider_config.webhook_verify_token" />
      </settings-section>
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')"
      >
        <woot-code :script="inbox.provider_config.api_key" />
      </settings-section>
      <settings-section
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_SUBHEADER')
        "
      >
        <div v-if="!successfullyUpdated" class="whatsapp-settings--content">
          <div v-if="inbox.provider == 'whatsapp_cloud'">
            <div
              v-if="!hasLoginStarted"
              class="login-init text-left medium-8 mb-1 columns p-0"
            >
              <a href="#" @click="startLogin()">
                <img
                  src="~dashboard/assets/images/channels/facebook_login.png"
                  alt="Facebook-logo"
                />
              </a>
            </div>
            <div v-else class="login-init medium-8 columns p-0">
              <loading-state v-if="showLoader" :message="emptyStateMessage" />
            </div>
          </div>
          <div v-else class="whatsapp-settings--content">
            <woot-input
              v-model.trim="whatsAppInboxAPIKey"
              type="text"
              class="input"
              :placeholder="
                $t(
                  'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_PLACEHOLDER'
                )
              "
            />
            <woot-button
              :disabled="$v.whatsAppInboxAPIKey.$invalid"
              @click="updateWhatsAppInboxAPIKey"
            >
              {{
                $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON')
              }}
            </woot-button>
          </div>
        </div>
      </settings-section>
    </div>
  </div>
</template>

<script>
/* eslint-env browser */
/* global FB */

import alertMixin from 'shared/mixins/alertMixin';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from '../../../../../components/SettingsSection';
import ImapSettings from '../ImapSettings';
import SmtpSettings from '../SmtpSettings';
import MicrosoftReauthorize from '../channels/microsoft/Reauthorize';
import { required } from 'vuelidate/lib/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState';
import {
  loadFBsdk,
  initFB,
} from '../../../../../../shared/helpers/facebookInitializer';

export default {
  components: {
    SettingsSection,
    ImapSettings,
    SmtpSettings,
    MicrosoftReauthorize,
    LoadingState,
  },
  mixins: [inboxMixin, alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      hmacMandatory: false,
      whatsAppInboxAPIKey: '',
      hasLoginStarted: false,
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_FB'),
      successfullyUpdated: false,
    };
  },
  validations: {
    whatsAppInboxAPIKey: { required },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
    loadFBsdk();
    initFB();
  },
  methods: {
    setDefaults() {
      this.hmacMandatory = this.inbox.hmac_mandatory || false;
    },
    handleHmacFlag() {
      this.updateInbox();
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            hmac_mandatory: this.hmacMandatory,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateWhatsAppInboxAPIKey() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {},
        };

        payload.channel.provider_config = {
          ...this.inbox.provider_config,
          api_key: this.whatsAppInboxAPIKey,
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.successfullyUpdated = true;
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
        this.hasLoginStarted = false;
      }
    },
    startLogin() {
      this.hasLoginStarted = true;
      this.tryFBlogin();
    },
    tryFBlogin() {
      FB.login(
        response => {
          if (response.status === 'connected') {
            this.isFbConnected = true;
            this.whatsAppInboxAPIKey = response.authResponse.accessToken;
            this.updateWhatsAppInboxAPIKey();
          } else if (response.status === 'not_authorized') {
            // The person is logged into Facebook, but not your app.
            this.emptyStateMessage = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_AUTH'
            );
          } else {
            // The person is not logged into Facebook, so we're not sure if
            // they are logged into this app or not.
            this.emptyStateMessage = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_AUTH'
            );
          }
        },
        {
          scope: 'whatsapp_business_management,whatsapp_business_messaging',
        }
      );
    },
    showLoader() {
      return !this.user_access_token || this.isCreating;
    },
    shouldDisplayUpdateSettings() {
      return (
        this.inbox.provider !== 'whatsapp_cloud' ||
        this.inbox.provider_config.token_expiry_date !== 'never'
      );
    },
  },
};
</script>
<style lang="scss" scoped>
.whatsapp-settings--content {
  align-items: center;
  display: flex;
  flex: 1;
  justify-content: space-between;
  margin-top: var(--space-small);

  .input {
    flex: 1;
    margin-right: var(--space-small);
    ::v-deep input {
      margin-bottom: 0;
    }
  }
}
.p-0 {
  padding: 0%;
}
.text-left {
  text-align: left;
}

.mb-1 {
  margin-bottom: 1.6rem;
}
</style>
