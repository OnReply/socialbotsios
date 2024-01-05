<template>
  <div class="csml-editor--container">
    <loading-state
      v-if="iframeLoading"
      :message="$t('AGENT_BOTS.LOADING_EDITOR')"
      class="dashboard-app_loading-container"
    />
    <iframe id="csml-editor--frame" :src="iframeURL()" @load="onEditorLoad" />
  </div>
</template>
<script>
import LoadingState from 'dashboard/components/widgets/LoadingState';
import { mapGetters } from 'vuex';
import md5 from 'md5';

export default {
  components: { LoadingState },
  props: {
    value: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      iframeLoading: true,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      currentAccountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    window.onmessage = e => {
      if (
        typeof e.data !== 'string' ||
        !e.data.startsWith('chatwoot-csml-editor:update')
      ) {
        return;
      }
      const csmlContent = e.data.replace('chatwoot-csml-editor:update', '');
      this.$emit('input', csmlContent);
    };
  },
  methods: {
    onEditorLoad() {
      const frameElement = document.getElementById(`csml-editor--frame`);
      const eventData = {
        event: 'editorContext',
        data: this.value || '',
      };
      frameElement.contentWindow.postMessage(JSON.stringify(eventData), '*');
      this.iframeLoading = false;
    },
    iframeURL() {
      return (
        this.globalConfig.csmlEditorHost +
        '?dbidentification=' +
        md5(
          this.currentAccountId.toString() + window.chatwootConfig.randomString
        )
      );
    },
  },
};
</script>

<style scoped>
#csml-editor--frame {
  border: 0;
  width: 100%;
  height: 100%;
}
</style>
