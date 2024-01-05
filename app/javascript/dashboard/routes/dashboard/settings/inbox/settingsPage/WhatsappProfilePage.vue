<template>
	<div>
		<div class="m-2">
			<div class="input-group-field">
        <label for="name" >
          {{ $t('WHATSAPP_PROFILE.DESCRIPTION.LABEL') }}
          <input
            v-model.trim="profile.description"
            name="name"
            type="text"
						maxlength="256"
						:placeholder="$t('WHATSAPP_PROFILE.DESCRIPTION.PLACEHOLDER')"
          />
        </label>
      </div>
			<div class="input-group-field">
        <label for="name" >
          {{ $t("WHATSAPP_PROFILE.ABOUT.LABEL") }}
          <input
            v-model.trim="profile.about"
            name="name"
            type="text"
						maxlength="139"
						:placeholder="$t('WHATSAPP_PROFILE.ABOUT.PLACEHOLDER')"
          />
        </label>
      </div>
			<div class="input-group-field">
        <label for="name" >
          {{ $t("WHATSAPP_PROFILE.ADDRESS.LABEL") }}
          <input
            v-model.trim="profile.address"
            name="name"
            type="text"
						maxlength="256"
						:placeholder="$t('WHATSAPP_PROFILE.ADDRESS.PLACEHOLDER')"
          />
        </label>
      </div>
			<div class="input-group-field row  align-items-center">
				<label>
					{{ $t("WHATSAPP_PROFILE.PROFILE_PICTURE.LABEL") }}
					<img :src="imageUrl" class="profile-pic m-2" alt="">
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
        <label for="name" >
          {{ $t("WHATSAPP_PROFILE.EMAIL.LABEL") }}
          <input
            v-model.trim="profile.email"
            name="name"
            type="email"
						maxlength="138"
						:placeholder="$t('WHATSAPP_PROFILE.EMAIL.PLACEHOLDER')"
          />
        </label>
      </div>
			<div class="input-group-field">
        <label for="name" >
          {{ $t("WHATSAPP_PROFILE.WEBSITE.LABEL") }}
          <input
            v-model.trim="profile.websites[0]"
            name="name"
            type="text"
						maxlength="256"
						:placeholder="$t('WHATSAPP_PROFILE.WEBSITE.PLACEHOLDER')"
          />
        </label>
      </div>
		</div>
		<woot-submit-button
			:button-text="$t('EMAIL_TRANSCRIPT.SUBMIT')"
			class="m-2"
			@click="submitForm"
			:disabled="isDisabled"
			
		/>
	</div>
</template>

<script>
import InboxesAPI from '../../../../../api/inboxes'
import alertMixin from 'shared/mixins/alertMixin';

export default {
	props: {
		inbox: {
      type: Object,
      default() {
        return {};
      },
    },
	},
	mixins: [alertMixin],
	data() {
		return {
			imageUrl: '',
			imageFile: '',
			isDisabled: true,
			profile: {
				description: '',
				about: '',
				address: '',
				email: '',
				websites: [''],
				messaging_product: 'whatsapp'
			},
		}
	},
	methods: {
		async handleImageUpload(event) {
      const [file] = event.target.files;
      this.imageFile = file;
      this.imageUrl = file? URL.createObjectURL(file) : '';
    },
		async submitForm() {
			this.isDisabled = true
      const response = await InboxesAPI.UpdateProfilePicture(this.inbox.id, this.imageFile, this.profile)
      if(response.data.message) {
        this.showAlert(this.$t('WHATSAPP_TEMPLATES.BUILDER.SUCCESSFUL_SUBMISSION'))
      } else {
        this.showAlert(response.data.error)
      }
			this.isDisabled = false
    },
	},
	watch: {
		inbox: {
			handler(val){
				this.imageUrl = val.profile_picture_url
				this.profile.description = val.provider_config.profile?.description || ''
				this.profile.about = val.provider_config.profile?.about || ''
				this.profile.email = val.provider_config.profile?.email || ''
				this.profile.address = val.provider_config.profile?.address || ''
				this.profile.websites[0] = val.provider_config.profile?.websites[0] || ''
				this.profile.websites[1] = val.provider_config.profile?.websites[1] || ''
				
			},
			deep: true,
			immediate: true, 
		},
		imageFile(newVal){
			if(newVal === undefined){
				this.imageUrl = this.inbox.profile_picture_url
			} else {
				this.isDisabled = false
			}
		},
		profile: {
			handler(newVal){
				if(newVal.about == ''){
					this.isDisabled = true
				} else {
					this.isDisabled = false
				}
			},
			deep: true
		}
	}
}
</script>

<style scoped>
.profile-pic{
	border-radius: 100%;
	width: 100px;
	height: 100px;
	border: 1px solid grey;
}
.m-2{
	margin: 2rem;
}
.align-items-center {
	align-items: center;
}
</style>
