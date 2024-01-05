<template>
  <div class="main-div">
    <div class="add-button-div">
      <woot-submit-button
        button-text="Create New template"
        @click="openModal(JSON.parse(JSON.stringify(defaultTempate))); editMode=false;"
      />
    </div>
    <div class="mt-2">
      <templates-picker
        :inbox-id="inbox.id"
        classes="max-h-full template__list-container"
        :filter-templates="false"
        @onSelect="editTemplate"
      />
      <woot-modal
        :show.sync="showWhatsAppTemplatesBuilderModal"
        :on-close="onClose"
        size="modal-big"
      >
        <woot-modal-header
          :header-title="$t('WHATSAPP_TEMPLATES.MODAL.TITLE')"
          header-content="Edit your Template"
        />
        <div class="modal-content">
          <whatsapp-template-builder
            :inbox-id="inbox.id"
            :show="showWhatsAppTemplatesBuilderModal"
            :template="template"
            :edit-mode="editMode"
            @disable-submit-button="toggleSubmitButton"
            ref="templateBuilder"
          />
        </div>
        <div class="modal-footer">
          <div class="medium-12 row text-center">
            <woot-submit-button
              
              :button-text="$t('EMAIL_TRANSCRIPT.SUBMIT')"
              @click="submitForm"
              :disabled="isDisabled"
            />
             <woot-button
              
              :button-text="$t('EMAIL_TRANSCRIPT.SUBMIT')"
              @click="deleteTemplate"
              color-scheme="alert"
            >
              {{ $t('WHATSAPP_TEMPLATES.BUILDER.DELETE') }}
            </woot-button>
          </div>
        </div>
      </woot-modal>
    </div>
    <woot-confirm-modal
      ref="confirmDialog"
      :title="$t('WHATSAPP_TEMPLATES.BUILDER.DELETE')"
      :description="$t('WHATSAPP_TEMPLATES.BUILDER.DELETE_DESCRIPTION')"
    />
  </div>
</template>

<script>
import TemplatesPicker from '../../../../../components/widgets/conversation/WhatsappTemplates/TemplatesPicker.vue';
import WhatsappTemplateBuilder from './WhatsappTemplateBuilder.vue';
import InboxesAPI from '../../../../../api/inboxes';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: { TemplatesPicker, WhatsappTemplateBuilder },
  props: {
    inbox: {
      type: Object,
      default() {
        return {};
      },
    },
  },
  data() {
    return {
      showWhatsAppTemplatesBuilderModal: false,
      isDisabled: true,
      template: null,
      defaultTempate: {
        category: "UTILITY",
        components : [
          {
            format: "TEXT",
            type: "HEADER",
            text: "",
          },
          {
            type: "BODY",
            text: "",
          },
          {
            type: "FOOTER",
            text: "",
          },
        ],
        language: "ar",
        name: "",
      },
      editMode: false
    };
  },
  mixins: [alertMixin],
  computed: {},
  methods: {
    openModal(template) {
      this.showWhatsAppTemplatesBuilderModal = true;
      this.template = template;
    },
    onClose() {
      this.showWhatsAppTemplatesBuilderModal = false;
    },
    async submitForm() {
      this.isDisabled = true;
      const response = await InboxesAPI.createTemplate(this.inbox.id, this.template, this.$refs.templateBuilder.headerType, this.$refs.templateBuilder.imageFile, this.$refs.templateBuilder.buttonType, this.$refs.templateBuilder.buttonData)
      if(response.data.message) {
        this.showAlert(this.editMode? this.$t('WHATSAPP_TEMPLATES.BUILDER.SUCCESSFUL_EDIT') : this.$t('WHATSAPP_TEMPLATES.BUILDER.SUCCESSFUL_SUBMISSION'))
        this.template = this.defaultTempate;
        this.onClose();
      } else {
        this.showAlert(response.data.error)
        this.isDisabled = false
      }
    },
    toggleSubmitButton(value) {
      this.isDisabled = value;
    },
    editTemplate(template) {
      this.editMode = true;
      this.openModal(template)
    },
    async deleteTemplate() {
      const ok = await this.$refs.confirmDialog.showConfirmation();
      if (ok) {
        const response = await InboxesAPI.deleteTemplate(this.inbox.id, this.template);
        if(response.data.message) {
          this.showAlert(this.$t('WHATSAPP_TEMPLATES.BUILDER.SUCCESSFUL_DELETION'))
        } else {
          this.showAlert(response.data.error)
        }
        this.onClose();
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.template__list-container {
  background-color: var(--s-25);
  border-radius: var(--border-radius-medium);
  overflow-y: auto;
  padding: var(--space-one);
}
.modal-content {
  padding: 2.5rem 3.2rem;
}

.add-button-div{
  display: flex;
  justify-content: end;
  margin: 0.8rem ;
}
.main-div {
  margin: 1.2rem;
}
</style>
