<template>
  <div
    class="options-message chat-bubble agent"
    :class="$dm('bg-white', 'dark:bg-slate-700')"
  >
    <div class="card-body">
      <h4 class="title" :class="$dm('text-black-900', 'dark:text-slate-50')">        

          <div v-if="isImageFile()">
            <img
              :src="messageContentAttributes.message_payload.content.image"
              alt="Picture message"
            />
            <br/>
          </div>

          <file-bubble v-if="isVideoFile()" :url="messageContentAttributes.message_payload.content.video" />
          <file-bubble v-if="isDocumentFile()" :url="messageContentAttributes.message_payload.content.document" />

        {{ title }}
      </h4>
      <ul
        v-if="!hideFields"
        class="options"
        :class="{ 'has-selected': !!selected }"
      >
        <chat-option
          v-for="option in options"
          :key="option.id"
          :action="option"
          :is-selected="isSelected(option)"
          @click="onClick"
        />
      </ul>
    </div>
  </div>
</template>

<script>
import ChatOption from 'shared/components/ChatOption';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';
import FileBubble from 'widget/components/FileBubble';

export default {
  components: {
    ChatOption,
    FileBubble
  },
  mixins: [darkModeMixin],
  props: {
    title: {
      type: String,
      default: '',
    },
    options: {
      type: Array,
      default: () => [],
    },
    selected: {
      type: String,
      default: '',
    },
    hideFields: {
      type: Boolean,
      default: false,
    },
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
  },
  methods: {

    isImageFile() {
      return !!this.messageContentAttributes?.message_payload?.content?.image
    },

    isVideoFile() {
      return !!this.messageContentAttributes?.message_payload?.content?.video
    },

    isDocumentFile() {
      return !!this.messageContentAttributes?.message_payload?.content?.document
    },

    isSelected(option) {
      return this.selected === option.id;
    },
    onClick(selectedOption) {
      this.$emit('click', selectedOption);
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables.scss';
.has-selected {
  .option-button:not(.is-selected) {
    color: $color-light-gray;
    cursor: initial;
  }
}
</style>
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.options-message {
  max-width: 17rem;
  padding: $space-small $space-normal;
  border-radius: $space-small;
  overflow: hidden;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-normal;
    margin-top: $space-smaller;
    margin-bottom: $space-smaller;
    line-height: 1.5;
  }

  .options {
    width: 100%;

    > li {
      list-style: none;
      padding: 0;
    }
  }
}
</style>
