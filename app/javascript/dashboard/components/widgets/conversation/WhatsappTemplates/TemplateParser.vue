<template>
  <div class="medium-12 columns">
    <textarea
      v-model="processedString"
      rows="4"
      readonly
      class="template-input"
    />
    <div v-if="variables" class="template__variables-container">
      <p class="variables-label">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
      </p>
      <div
        v-for="(variable, key) in processedParams"
        :key="key"
        class="template__variable-item"
      >
        <span class="variable-label">
          {{ key }}
        </span>
        <woot-input
          v-model="processedParams[key]"
          type="text"
          class="variable-input"
          :styles="{ marginBottom: 0 }"
        />
      </div>
      <p v-if="$v.$dirty && $v.$invalid" class="error">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>
    <div v-if="image" class="template__variables-container">
      <input
        id="file"
        ref="file"
        type="file"
        accept="image/png, image/jpeg"
        @change="handleImageUpload"
      />
      <p v-if="$v.$dirty && $v.$invalid" class="error">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.ATTACH_IMAGE_ERROR') }}
      </p>
    </div>
    <footer>
      <woot-button variant="smooth" @click="$emit('resetTemplate')">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL') }}
      </woot-button>
      <woot-button @click="sendMessage">
        {{ buttonText == 'automation'?  $t('WHATSAPP_TEMPLATES.PARSER.SELECT_TEMPLATE') : $t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL') }}
      </woot-button>
    </footer>
  </div>
</template>

<script>
const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};
import { requiredIf } from 'vuelidate/lib/validators';
export default {
  props: {
    template: {
      type: Object,
      default: () => {},
    },
    buttonText: {
      type: String,
      default: 'conversation'
    }
  },
  validations: {
    processedParams: {
      requiredIfKeysPresent: requiredIf('variables'),
      allKeysRequired,
    },
    imageFile: {
     required: requiredIf(function() {
        return this.image
      })
    }
  },
  data() {
    return {
      processedParams: {},
      imageFile: null,
    };
  },
  computed: {
    variables() {
      const variables = this.templateString.match(/{{([^}]+)}}/g);
      return variables;
    },
    templateString() {
      return this.template.components.find(
        component => component.type === 'BODY'
      ).text;
    },
    processedString() {
      return this.templateString.replace(/{{([^}]+)}}/g, (match, variable) => {
        const variableKey = this.processVariable(variable);
        return this.processedParams[variableKey] || `{{${variable}}}`;
      });
    },
    image() {
      const headerComponent = this.template.components.find(
        component => component.type === 'HEADER'
      );
      return headerComponent && headerComponent.format === "IMAGE";
    }
  },
  mounted() {
    this.generateVariables();
  },
  methods: {
    sendMessage() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      const payload = {
        message: this.processedString,
        templateParams: {
          name: this.template.name,
          category: this.template.category,
          language: this.template.language,
          namespace: this.template.namespace,
          processed_params: this.processedParams,
        },
        image: this.imageFile
      };
      this.$emit('sendMessage', payload);
    },
    async handleImageUpload(event) {
      const [file] = event.target.files;
      this.imageFile = file;
      // this.imageUrl = file? URL.createObjectURL(file) : '';
    },
    processVariable(str) {
      return str.replace(/{{|}}/g, '');
    },
    generateVariables() {
      const matchedVariables = this.templateString.match(/{{([^}]+)}}/g);
      if (!matchedVariables) return;

      const variables = matchedVariables.map(i => this.processVariable(i));
      this.processedParams = variables.reduce((acc, variable) => {
        acc[variable] = '';
        return acc;
      }, {});
    },
  },
};
</script>

<style scoped lang="scss">
.template__variables-container {
  padding: var(--space-one);
}

.variables-label {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-one);
}

.template__variable-item {
  align-items: center;
  display: flex;
  margin-bottom: var(--space-one);

  .label {
    font-size: var(--font-size-mini);
  }

  .variable-input {
    flex: 1;
    font-size: var(--font-size-small);
    margin-left: var(--space-one);
  }

  .variable-label {
    background-color: var(--s-75);
    border-radius: var(--border-radius-normal);
    display: inline-block;
    font-size: var(--font-size-mini);
    padding: var(--space-one) var(--space-medium);
  }
}

footer {
  display: flex;
  justify-content: flex-end;

  button {
    margin-left: var(--space-one);
  }
}
.error {
  background-color: var(--r-100);
  border-radius: var(--border-radius-normal);
  color: var(--r-800);
  padding: var(--space-one);
  text-align: center;
}
.template-input {
  background-color: var(--s-25);
}
</style>
