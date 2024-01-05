<template>
  <div class="h-full">
    <iframe :src="iframeURL()" height="100%" width="100%" />
    
  </div>
</template>

<script>
import campaignMixin from 'shared/mixins/campaignMixin';
import Campaign from './Campaign.vue';
import AddCampaign from './AddCampaign';
import { mapGetters } from 'vuex';
import md5 from 'md5';



export default {
  components: {
    Campaign,
    AddCampaign,
  },
  mixins: [campaignMixin],
  data() {
    return { showAddPopup: false };
  },
  computed: {
    buttonText() {
      if (this.isOngoingType) {
        return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONGOING');
      }
      return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONE_OFF');
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.$store.dispatch('campaigns/get');
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    iframeURL() {
      return (
        "https://help.socialbot.dev/campaigns?account_id="+
        md5(
          this.accountId.toString() + window.chatwootConfig.randomString
        )
      );
    },
  },
};
</script>

<style scoped>
.h-full {
  height: 100%;
}
</style>
