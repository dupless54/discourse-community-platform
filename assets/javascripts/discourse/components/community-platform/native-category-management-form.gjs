import Component from "@glimmer/component";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import UppyImageUploader from "discourse/components/uppy-image-uploader";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class NativeCategoryManagementForm extends Component {
  @tracked saving = false;
  @tracked errorMessage = null;
  @tracked savedMessage = null;
  @tracked description = "";
  @tracked visibility = "public";
  @tracked iconEmoji = "";
  @tracked bannerColor = "";
  @tracked iconUploadId = null;
  @tracked iconUrl = null;
  @tracked bannerUploadId = null;
  @tracked bannerUrl = null;
  @tracked rulesText = "";

  constructor(owner, args) {
    super(owner, args);
    this.syncManagementForm(args.community);
  }

  @action
  communityChanged() {
    this.errorMessage = null;
    this.savedMessage = null;
    this.saving = false;
    this.syncManagementForm(this.args.community);
  }

  @action
  updateDescription(event) {
    this.description = event.target.value;
  }

  @action
  updateVisibility(event) {
    this.visibility = event.target.value;
  }

  @action
  updateIconEmoji(event) {
    this.iconEmoji = event.target.value;
  }

  @action
  updateBannerColor(event) {
    this.bannerColor = event.target.value;
  }

  @action
  updateRules(event) {
    this.rulesText = event.target.value;
  }

  @action
  iconUploadDone(upload) {
    this.iconUploadId = upload.id;
    this.iconUrl = upload.url;
  }

  @action
  iconUploadDeleted() {
    this.iconUploadId = null;
    this.iconUrl = null;
  }

  @action
  bannerUploadDone(upload) {
    this.bannerUploadId = upload.id;
    this.bannerUrl = upload.url;
  }

  @action
  bannerUploadDeleted() {
    this.bannerUploadId = null;
    this.bannerUrl = null;
  }

  @action
  async saveManagement(event) {
    event?.preventDefault();

    const communitySlug = this.args.community?.slug;
    if (!communitySlug || this.saving) {
      return;
    }

    this.saving = true;
    this.errorMessage = null;
    this.savedMessage = null;

    try {
      const response = await ajax(
        `/community-platform/communities/${encodeURIComponent(communitySlug)}.json`,
        {
          type: "PATCH",
          data: {
            community: {
              description: this.description,
              visibility: this.visibility,
              icon_emoji: this.iconEmoji,
              banner_color: this.bannerColor,
              icon_upload_id: this.iconUploadId,
              banner_upload_id: this.bannerUploadId,
              rules: this.rulesText
                .split(/\r?\n/)
                .map((rule) => rule.trim())
                .filter(Boolean),
            },
          },
        }
      );

      if (this.args.community?.slug !== communitySlug) {
        return;
      }

      this.syncManagementForm(response.community);
      this.args.onCommunityUpdated?.(response.community);
      this.savedMessage = i18n("community_platform.management.saved");
    } catch {
      if (this.args.community?.slug === communitySlug) {
        this.errorMessage = i18n("community_platform.management.error");
      }
    } finally {
      if (this.args.community?.slug === communitySlug) {
        this.saving = false;
      }
    }
  }

  syncManagementForm(community) {
    this.description = community?.description || "";
    this.visibility = community?.visibility || "public";
    this.iconEmoji = community?.icon_emoji || "";
    this.bannerColor = community?.banner_color || "";
    this.iconUploadId = community?.icon_upload_id || null;
    this.iconUrl = community?.icon_url || null;
    this.bannerUploadId = community?.banner_upload_id || null;
    this.bannerUrl = community?.banner_url || null;
    this.rulesText = (community?.rules || []).join("\n");
  }

  <template>
    <section
      class="dcp-sidebar-card dcp-management-card dcp-native-community-management"
      data-test-native-community-management
      {{didUpdate this.communityChanged @community.id}}
    >
      <div class="dcp-section-heading dcp-section-heading--compact">
        <div>
          <p class="dcp-eyebrow">
            {{i18n "community_platform.management.eyebrow"}}
          </p>
          <h2>{{i18n "community_platform.management.title"}}</h2>
        </div>
      </div>

      <form class="dcp-management-form" {{on "submit" this.saveManagement}}>
        <label class="dcp-field">
          <span>{{i18n "community_platform.management.description"}}</span>
          <textarea
            rows="4"
            value={{this.description}}
            disabled={{this.saving}}
            data-test-native-community-description
            {{on "input" this.updateDescription}}
          ></textarea>
        </label>

        <label class="dcp-field">
          <span>{{i18n "community_platform.management.visibility"}}</span>
          <select
            value={{this.visibility}}
            disabled={{this.saving}}
            data-test-native-community-visibility
            {{on "change" this.updateVisibility}}
          >
            <option value="public">
              {{i18n "community_platform.visibility.public"}}
            </option>
            <option value="restricted">
              {{i18n "community_platform.visibility.restricted"}}
            </option>
            <option value="private">
              {{i18n "community_platform.visibility.private"}}
            </option>
          </select>
        </label>

        <div class="dcp-management-branding-grid">
          <div class="dcp-field dcp-branding-field">
            <strong>{{i18n "community_platform.management.logo"}}</strong>
            <UppyImageUploader
              @imageUrl={{this.iconUrl}}
              @onUploadDone={{this.iconUploadDone}}
              @onUploadDeleted={{this.iconUploadDeleted}}
              @type="category_logo"
              @id="dcp-native-community-logo-uploader"
              class="dcp-branding-uploader dcp-branding-uploader--logo"
            />
            <small>{{i18n "community_platform.management.logo_hint"}}</small>
          </div>

          <div class="dcp-field dcp-branding-field">
            <strong>{{i18n
                "community_platform.management.banner_image"
              }}</strong>
            <UppyImageUploader
              @imageUrl={{this.bannerUrl}}
              @onUploadDone={{this.bannerUploadDone}}
              @onUploadDeleted={{this.bannerUploadDeleted}}
              @type="category_background"
              @id="dcp-native-community-banner-uploader"
              class="dcp-branding-uploader dcp-branding-uploader--banner"
            />
            <small>
              {{i18n "community_platform.management.banner_image_hint"}}
            </small>
          </div>
        </div>

        <label class="dcp-field">
          <span>{{i18n "community_platform.management.icon"}}</span>
          <input
            type="text"
            value={{this.iconEmoji}}
            disabled={{this.saving}}
            data-test-native-community-icon-emoji
            {{on "input" this.updateIconEmoji}}
          />
        </label>

        <label class="dcp-field">
          <span>{{i18n "community_platform.management.banner_color"}}</span>
          <input
            type="text"
            value={{this.bannerColor}}
            disabled={{this.saving}}
            data-test-native-community-banner-color
            {{on "input" this.updateBannerColor}}
          />
        </label>

        <label class="dcp-field">
          <span>{{i18n "community_platform.management.rules"}}</span>
          <textarea
            rows="6"
            value={{this.rulesText}}
            disabled={{this.saving}}
            data-test-native-community-rules
            {{on "input" this.updateRules}}
          ></textarea>
          <small>{{i18n "community_platform.management.rules_hint"}}</small>
        </label>

        <button
          type="submit"
          class="btn btn-primary dcp-management-save"
          disabled={{this.saving}}
          data-test-native-community-save
        >
          {{#if this.saving}}
            {{i18n "community_platform.management.saving"}}
          {{else}}
            {{i18n "community_platform.management.save"}}
          {{/if}}
        </button>
      </form>

      {{#if this.savedMessage}}
        <p class="dcp-community-feedback" role="status">
          {{this.savedMessage}}
        </p>
      {{/if}}

      {{#if this.errorMessage}}
        <div class="alert alert-error dcp-community-feedback" role="alert">
          {{this.errorMessage}}
        </div>
      {{/if}}
    </section>
  </template>
}
