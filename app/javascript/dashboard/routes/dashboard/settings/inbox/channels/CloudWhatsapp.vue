<template>
  <form class="row" @submit.prevent="createChannel()">
    <div class="medium-8 columns">
      <label :class="{ error: $v.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model.trim="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="$v.inboxName.$touch"
        />
        <span v-if="$v.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model.trim="phoneNumber"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
          @blur="$v.phoneNumber.$touch"
        />
        <span v-if="$v.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.phoneNumberId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.LABEL') }}
        </span>
        <input
          v-model.trim="phoneNumberId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.PLACEHOLDER')
          "
          @blur="$v.phoneNumberId.$touch"
        />
        <span v-if="$v.phoneNumberId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.businessAccountId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.LABEL') }}
        </span>
        <input
          v-model.trim="businessAccountId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.PLACEHOLDER')
          "
          @blur="$v.businessAccountId.$touch"
        />
        <span v-if="$v.businessAccountId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.ERROR') }}
        </span>
      </label>
    </div>
    <div v-if="apiKey === ''" class="medium-8 columns ">
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
    <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
        :disabled="!isFbConnected"
      />
    </div>
  </form>
</template>

<script>
/* eslint-env browser */
/* global FB */
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty, isNumber } from 'shared/helpers/Validators';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import LoadingState from 'dashboard/components/widgets/LoadingState';
import { loadFBsdk, initFB } from 'shared/helpers/facebookInitializer';

export default {
  components: {
    LoadingState,
  },
  mixins: [alertMixin, globalConfigMixin],
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
      phoneNumberId: '',
      businessAccountId: '',
      hasLoginStarted: false,
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_FB'),
      isFbConnected: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
      globalConfig: 'globalConfig/get',
    }),
  },
  created() {
    initFB();
    loadFBsdk();
  },
  mounted() {
    initFB();
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    apiKey: { required },
    phoneNumberId: { required, isNumber },
    businessAccountId: { required, isNumber },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName,
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider: 'whatsapp_cloud',
              provider_config: {
                api_key: this.apiKey,
                phone_number_id: this.phoneNumberId,
                business_account_id: this.businessAccountId,
              },
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: whatsappChannel.id,
          },
        });
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'));
      }
    },
    startLogin() {
      this.hasLoginStarted = true;
      this.tryFBlogin();
    },
    showLoader() {
      return !this.user_access_token || this.isCreating;
    },
    initFB() {
      if (window.fbSDKLoaded === undefined) {
        window.fbAsyncInit = () => {
          FB.init({
            appId: window.chatwootConfig.fbAppId,
            xfbml: true,
            version: window.chatwootConfig.fbApiVersion,
            status: true,
          });
          window.fbSDKLoaded = true;
          FB.AppEvents.logPageView();
        };
      }
    },
    loadFBsdk() {
      ((d, s, id) => {
        let js;
        // eslint-disable-next-line
        const fjs = (js = d.getElementsByTagName(s)[0]);
        if (d.getElementById(id)) {
          return;
        }
        js = d.createElement(s);
        js.id = id;
        js.src = '//connect.facebook.net/en_US/sdk.js';
        fjs.parentNode.insertBefore(js, fjs);
      })(document, 'script', 'facebook-jssdk');
    },
    tryFBlogin() {
      FB.login(
        response => {
          if (response.status === 'connected') {
            this.isFbConnected = true;
            this.apiKey = response.authResponse.accessToken;
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
  },
};
</script>

<style scoped>
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
