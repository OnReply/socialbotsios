<template>
  <div class="parent-div">
    <div class="medium-9 small mr-2">
      <div class="input-group-field">
        <label for="name" :class="{ error: $v.template.name.$error }">
          {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.NAME') }}
          <input
            v-model.trim="template.name"
            name="name"
            type="text"
            @keydown="validateInput"
            :disabled="editMode"
          />
          <span v-if="$v.template.name.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
          </span>
        </label>
      </div>
      <div class="input-group-field">
        <label for="category"> {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.CATEGORY') }} </label>
        <select v-model="template.category" :disabled="editMode && template.status == 'APPROVED'" name="category">
          <option v-for="t in templateTypes" :key="t" :value="t">
            {{ t }}
          </option>
        </select>
      </div>
      <div class="input-group-field">
        <label for="language"> {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.LANGUAGE') }} </label>
        <select v-model="template.language" name="language" :disabled="editMode">
          <option
            v-for="language in languages"
            :key="language.code"
            :value="language.code"
          >
            {{ language.language }}
          </option>
        </select>
      </div>
      <div class="input-group-field">
        <label for="language"> {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.HEADER_TYPE') }} </label>
        <select v-model="headerType" @change="UpdateDisplayHeaderInputField" name="headerType">
          <option
            value="none"
          >
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.HEADER_TYPES.NONE') }}
          </option>
          <option
            value="text"
          >
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.HEADER_TYPES.TEXT') }}
          </option>
          <option
            value="image"
          >
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.HEADER_TYPES.IMAGE') }}
          </option>
        </select>
      </div>
      <div v-if="displayHeaderInputField == 'text'" class="input-group-field">
        <label for="" :class="{ error: $v.headerValue.$error }">
          {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.HEADER') }}
          <input
            v-model.trim="headerValue"
            type="text"
            @input="updateHeaderValue"
            maxlength="60"
          />
          <span v-if="$v.headerValue.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
          </span>
        </label>
      </div>
      <div v-else-if="displayHeaderInputField == 'image'" class="input-group-field row">
        <label>
          <input
            id="file"
            ref="file"
            type="file"
            accept="image/png, image/jpeg, image/gif"
            @change="handleImageUpload"
          />
          <slot />
        </label>
      </div>
      <div class="input-group-field">
        <label for="body" :class="{ error: $v.bodyValue.$error }"> 
          {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BODY') }} 
          <textarea
            v-model.trim="bodyValue"
            type="text"
            name="body"
            @input="updateBodyValue"
            maxlength="1024"
          />
          <span v-if="$v.bodyValue.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
          </span>
        </label>
      </div>
      <div class="input-group-field">
        <label for="">
          {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.FOOTER') }}
          <input
            v-model.trim="footerValue"
            type="text"
            @input="updateFooterValue"
            maxlength="60"
          />
        </label>
      </div>
      <div class="input-group-field">
        <label for="button"> {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.BUTTON') }} </label>
        <select v-model="buttonType" @change="UpdateDisplaybuttons" class="mx-1" name="buttonType">
          <option
            value="none"
          >
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.BUTTON_TYPE.NONE') }}
          </option>
          <option
            value="QUICK_REPLY"
          >
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.BUTTON_TYPE.QUICK_REPLY') }}
          </option>
          <option
            value="CALL"
          >
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.BUTTON_TYPE.CALL') }}
          </option>
        </select>
      </div>
      <div>
      <div class="input-group-field" v-if="buttonType!=='never' ">
        <div v-if="buttonType === 'QUICK_REPLY'">
          <label for="" v-for="(button, index) in buttonData" v-bind:key="index" :class="{ error: error.text[`${index}`] }">
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.BUTTON_TEXT') }}
            <div class="parent-div">
              <input
                v-model.trim="button.text"
                type="text"
                maxlength="60"
                class="mx-1"
                
              />
              <woot-button
                color-scheme="secondary"
                variant="link"
                size="tiny"
                icon="dismiss"
                @click="removeButton(index)"
                class="mx-1 mt-2"
                v-if="buttonData.length > 1"
              />
            </div>
            <span v-if="error.text[`${index}`]" class="message">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
            </span>
          </label>
        </div>
        <div v-else-if="buttonType === 'CALL'">
          <label for="" v-for="(button, index) in buttonData"  v-bind:key="index">
            {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.TYPE_OF_ACTION.LABEL') }}
            <div class="parent-div input-group-field align-items-center">
              <div class="flex mt-2">
                <select v-model="button.type" @change="changeActionType(index, button)" :disabled="disableButtonType" class="mx-1" name="actionType">
                  <option
                    value="PHONE_NUMBER"
                  >
                    {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.TYPE_OF_ACTION.PHONE_NUMBER') }}
                  </option>
                  <option
                    value="URL"
                  >
                    {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.TYPE_OF_ACTION.URL') }}
                  </option>
                </select>
              </div>
              <div v-if="button.type == 'PHONE_NUMBER'" class="parent-div">
                <label for="" class="mx-1" :class="{ error: error.text[`${index}`] }">
                  {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.BUTTON_TEXT') }}
                  <input
                  v-model.trim="button.text"
                  type="text"
                  maxlength="60"
                  />
                  <span v-if="error.text[`${index}`]" class="message">
                    {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
                  </span>
                </label>
                <label for="" class="mx-1" :class="{ error: error.phone_number }">
                  {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.PHONE_NUMBER.LABEL') }}
                  <input
                  v-model.trim="button.phone_number"
                  type="text"
                  maxlength="60"
                  />
                  <span v-if="error.phone_number" class="message">
                  {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.PHONE_NUMBER.ERROR') }}
                  </span>
                </label>
              </div>
              <div v-else-if="button.type == 'URL'" class="parent-div">
                <label for="" class="mx-1" :class="{ error: error.text[`${index}`] }">
                  {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.BUTTON_TEXT') }}
                  <input
                  v-model.trim="button.text"
                  type="text"
                  maxlength="60"
                  />
                  <span v-if="error.text[`${index}`]" class="message">
                    {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
                  </span>
                </label>
                <div class="flex mt-2 mx-1" >
                  <select v-model="urlType" class="mx-1" name="urlType">
                    <option
                      value="static"
                    >
                      {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.URL.TYPE.STATIC') }}
                    </option>
                    <option
                      value="dynamic"
                    >
                      {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.URL.TYPE.DYNAMIC') }}
                    </option>
                  </select>
                </div>
                <label for="" class="mx-1" :class="{ error: error.url }">
                  {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.URL.LABEL') }}
                  <input
                  v-model.trim="button.url"
                  type="text"
                  maxlength="60"
                  class="mx-1"
                  />
                  <span v-if="error.url" class="message">
                  {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.URL.ERROR') }}
                  </span>
                </label>
              </div>
              <woot-button
                color-scheme="alert"
                variant="clear"
                size="tiny"
                icon="dismiss"
                @click="removeButton(index)"
                class="mx-1 mt-2"
                v-if="buttonData.length > 1"
              />
            </div>
            <div v-if="button.type == 'URL' && urlType == 'dynamic'">
              <label for="">
                  {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.URL.EXAMPLE') }}
                <input
                v-model.trim="button.example"
                type="text"
                maxlength="60"
                :class="`example-${index}`"
                />
              </label>
            </div>
          </label>
        </div>
        <button class="button clear" @click="addNewButton" v-if="buttonData.length < maximumButtonsCount">
          {{ $t('WHATSAPP_TEMPLATES.BUILDER.FORM.BUTTONS.NEW_BUTTON') }}
        </button>
      </div>

      </div>
    </div>
    <div class="medium-3 whatsapp-chat-background">
      <div class="first-parent">
        <div class="second-parent">
          <div class="third-parent">
            <div class="bg-white rounded relative padding-1" :class="footerValue.length > 0 ? 'pb-1' : ''">
              <div v-if="displayHeaderInputField == 'text'" class="bold padding-left-1 header-font">
                {{ headerValue }}
              </div>
              <div v-else-if="displayHeaderInputField == 'image'">
                <img :src="imageUrl" alt="">
              </div>
              <div class="padding-1 pb-1 body-font">
                {{ bodyValue }}
              </div>
              <div class="footer footer-font">
                {{ footerValue }}
                <span></span>
              </div>
              <div class="_6xe5">
                <time aria-hidden="true">07:26</time>
              </div>
            </div>
            <div class="button-div">
              <div v-for="(button, index) in buttonData" class="span" :key="index">
                <span class="icon" :class="button.type.toLowerCase().replace(/_/g, '-')"></span>
                <span >{{button.text}}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import facebookLanguageList from '../../../../../helper/facebookLanguagesList.json';
import { required } from 'vuelidate/lib/validators';
import Vue from 'vue';
import InboxesAPI from '../../../../../api/inboxes';

export default {
  computed: {
   
  },
  props: {
    inboxId: {
      type: Number,
      default: undefined,
    },
    show: {
      type: Boolean,
      default: true,
    },
    template: {
      type: Object,
      default() {
        return {
          name: '',
          category: 'UTILITY',
          language: 'ar',
          components: [],
        };
      },
    },
    editMode: {
      type: Boolean,
      default: false
    }
  },
  validations: {
    template: {
      name: {
        required,
      }
    },
    headerValue: { required },
    bodyValue: { required },
    buttonData: {
      ...function () {
        return this.buttonValidations.reduce((merged, curr) => {
          return { ...merged, ...curr };
        }, {});
      },
    }
  },
  data() {
    return {
      templateTypes: ['UTILITY', 'MARKETING', 'AUTHENTICATION'],
      languages: facebookLanguageList,
      bodyValue: '',
      headerValue: '',
      footerValue: '',
      nameError: false,
      headerType: 'none',
      displayHeaderInputField: 'none',
      imageUrl: '',
      imageFile: '',
      buttonType: 'none',
      maximumButtonsCount: 2,
      buttonData:[],
      actionType:[],
      urlType: 'static',
      disableButtonType: false,
      error: {
        phone_number: false,
        url: false,
        text: {}
      }
    };
  },
  mounted() {
    this.getComponentValues();
  },
  methods: {
    getComponentValues() {
      this.template.components.forEach(component => {
        if (component.type === 'HEADER') {
          if (component.format == "TEXT")
          {
            this.displayHeaderInputField = this.headerType = 'text';
            this.headerValue = component.text;
          }
          else if (component.format == 'IMAGE'){
            this.displayHeaderInputField = this.headerType = 'image';
            if (component.example)  this.imageUrl = component.example.header_handle[0]
          }
        } else if (component.type === 'BODY') {
          this.bodyValue = component.text;
        } else if (component.type === 'FOOTER') {
          this.footerValue = component.text;
        } else if (component.type === "BUTTONS") {
          
          this.buttonData = component.buttons
          this.buttonType = component.buttons[0].type == "QUICK_REPLY"? "QUICK_REPLY" : "CALL"
          this.maximumButtonsCount = this.buttonType == "CALL" ? 2 : 3
        }
      });
    },
    updateBodyValue() {
      var component = this.template.components.filter(c => c.type === 'BODY');
      component[0].text = this.bodyValue;
      this.$v.bodyValue.$touch()
    },
    updateHeaderValue() {
      var component = this.template.components.filter(c => c.type === 'HEADER');
      component[0].text = this.headerValue;
      this.$v.headerValue.$touch()
    },
    updateFooterValue() {
      var component = this.template.components.filter(c => c.type === 'FOOTER');
      component[0].text = this.footerValue;
    },
    validateInput(event) {
      const keyPressed = event.key;
      const alphanumericRegex = /^[0-9a-zA-Z_]+$/;
      if (!alphanumericRegex.test(keyPressed)) {
        event.preventDefault();
        if (keyPressed == ''){
          this.template.name += '_'
        }
      }
      this.$v.template.name.$touch()
    },
    UpdateDisplayHeaderInputField() {
      this.displayHeaderInputField = this.headerType;
    },
    async handleImageUpload(event) {
      const [file] = event.target.files;
      this.imageFile = file;
      this.imageUrl = file? URL.createObjectURL(file) : '';
    },
    shouldDisableSubmitButton() {
      let disableSubmitButton = this.$v.template.name.$invalid || this.IsHeaderValueInvalid() || this.$v.bodyValue.$invalid || this.buttonValidations()
      this.$emit('disable-submit-button', disableSubmitButton)
    },
    IsHeaderValueInvalid() {
      if(this.headerType == 'text') {
        return this.$v.headerValue.$invalid;
      } else if (this.headerType == 'none') {
        return false;
      }
       else {
        return this.imageFile == '';
      }
    },
    UpdateDisplaybuttons() {
      if(this.buttonType == 'QUICK_REPLY') {
        this.maximumButtonsCount = 3
        this.buttonData = [{"type": "QUICK_REPLY","text": ""}]
      } 
      else {
        this.maximumButtonsCount = 2
        this.buttonData = [{"type":"PHONE_NUMBER","text": "", "phone_number": ''}]
      }
    },
    addNewButton() {
      if(this.buttonType == 'QUICK_REPLY') {
        this.buttonData.push({"type": "QUICK_REPLY","text": ""})
      } else if(this.buttonType == 'CALL') {
        if(this.buttonData[0].type == 'URL') {
          this.buttonData.push({"type": "PHONE_NUMBER","text": "", "phone_number": ''})
        } else {
           this.buttonData.push({"type": "URL","text": "", "url": ''})
        }
        this.disableButtonType = true
      }
    },
    removeButton(index) {
      this.buttonData.splice(index, 1);
      if(this.buttonType == "CALL"){
        this.disableButtonType = false
      }
    },
    changeActionType(index, button) {
      if(button.type == 'PHONE_NUMBER') {
        Vue.delete(button,'url')
        button.text = ''
        Vue.set(button,'phone_number', '')
      } else {
        Vue.delete(button, 'phone_number')
        Vue.set(button,'url','')
        button.text = ''
      }
    },
    isFieldRequired(index) {
      const validations = this.buttonValidations[index];
      return Object.values(validations).some((rule) => rule.required);
    },
    buttonValidations() {
      if (this.buttonType == 'none')
      {
        return false;
      }
      var test =  this.buttonData.map((button, index) => {
        
        if(button.text == '')
        {
          this.error.text[`${index}`]=true
          return true
        } else {
         this.error.text[`${index}`]=false 
        }
        if (this.buttonType === "CALL") {
          if (button.type === "PHONE_NUMBER" ) {
            if (!this.isValidPhoneNumber(button.phone_number)){
              this.error.phone_number = true;
              return true;
            } else {
              this.error.phone_number = false
            }
          } else if (button.type === "URL") {
            if(!this.isValidPhoneURL(button.url)) {
              this.error.url = true;
              return true;
            } else {
              this.error.url = false;
            }
            if(this.urlType == 'dynamic' && button.example == '') {
              return true
            }
          }
        }
        return false; // For other cases or when buttonType is 'never'
      });
      return test.some((value) => value === true)
    },
    isValidPhoneNumber(phoneNumber) {
      const phoneNumberRegex = /^[0-9\-\+]{9,15}$/;
      return phoneNumberRegex.test(phoneNumber);
    },
    isValidPhoneURL(url) {
      const urlRegex = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,})([\/\w .-]*)*\/?$/i;
      return urlRegex.test(url);
    },
    getIcon(type) {
      return 'call-icon'
    }
  },
  watch: {
    template: {
      handler() {
        this.shouldDisableSubmitButton();
      },
      deep: true,
    },
    imageFile: function() {
      this.shouldDisableSubmitButton();
    },
    headerType: function() {
      this.shouldDisableSubmitButton();
    },
    buttonData: {
      handler() {
        this.shouldDisableSubmitButton();
      },
      deep: true,
    },
  }
};
</script>

<style lang="scss" scoped>
@import '../../../../../assets/scss/app.scss';
.max-h-full {
  max-height: 60% !important;
}
.whatsapp-chat-background {
  background-color: #e5ddd5;
  box-sizing: border-box;
  position: relative;
  z-index: 0;
  margin: 0.5rem 0.5rem;
}
.whatsapp-chat-background::before {
  background: url(https://static.xx.fbcdn.net/rsrc.php/v3/yb/r/rmr3BrOAAd8.png);
  background-size: 366.5px 666px;
  content: '';
  height: 100%;
  left: 0;
  opacity: 0.06;
  position: absolute;
  top: 0;
  width: 100%;
}

.parent-div {
  display: flex;
  justify-content: space-between;
}
.first-parent {
  margin-left: 8px;
  margin-right: 8px;
  margin-bottom: 12px;
  margin-top: 12px;
}
.second-parent {
  box-sizing: border-box;
  display: inline-block;
  font-family: BlinkMacSystemFont, -apple-system, Roboto, Arial, sans-serif;
  min-width: 95%;
  max-width: 100%;
  position: relative;
}
.third-parent {
  background-color: #fff;
  border-radius: 7.5px;
  border-top-left-radius: 0;
  box-shadow: 0 1px 0.5px rgba(0, 0, 0, .15);
  min-height: 20px;
  position: relative;
  word-wrap: break-word;
  min-width: 50px;
}
._6xe5 {
  bottom: 3px;
  color: rgba(0, 0, 0, .4);
  font-size: 11px;
  height: 15px;
  line-height: 15px;
  position: absolute;
  right: 7px;
}
.bold {
  font-weight: bold;
}
.pb-1{
  padding-bottom: 3px;
}
.required-field:required {
  border-color: red; /* Optional: Apply a red border to the required fields */
}
.flex {
  display: flex;
}
.align-items-end{
  align-items: end;
}
.mx-1{
  margin-left: 0.25rem;
  margin-right: 0.25rem;
}
.mt-2{
  margin-top: 2.5rem;
}
.relative {
  position: relative;
}
.button-div {
  border-top: 1px solid #dadde1;
  min-width: 100%;
  padding: 0 8px;
  .span {
    border-top: 1px solid #dadde1;
    color: #00a5f4;
    font-size: 14px;
    height: 44px;
    line-height: 20px;
    min-width: 100%;
    white-space: pre-wrap;
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
  }
}
  .icon {
    background-repeat: no-repeat;
    background-size: contain;
    flex-shrink: 0;
    height: 16px;
    opacity: .8;
    width: 16px;
    margin-right: 4px;
  }
  .phone-number {
    background-image: url(https://static.xx.fbcdn.net/rsrc.php/v3/yO/r/8o77vvYFLgb.png);
  }
  .url {
    background-image: url(https://static.xx.fbcdn.net/rsrc.php/v3/y0/r/OzOCQC-ukqH.png);
  }
  .quick-reply {
    background-image: url(https://static.xx.fbcdn.net/rsrc.php/v3/ym/r/a1ABEwh1MaF.png);
  }
  .footer {
    color: rgba(0, 0, 0, .45);
    font-size: 13px;
    line-height: 17px;
    padding: 0 7px 3px 9px;
    display: flex;
    flex-flow: column;
    margin-right: 13%;
  }
  .body-font {
    font-size: 13.6px;
  }
  .header-font {
    font-size: 15px;
  }
  .footer-font {
    font-size: 13px;
  }
</style>
