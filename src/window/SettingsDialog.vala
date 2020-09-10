/*  This file is part of Cawbird, a Gtk+ linux Twitter client forked from Corebird.
 *  Copyright (C) 2020 Frederick Schenk
 *
 *  Cawbird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Cawbird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with cawbird.  If not, see <http://www.gnu.org/licenses/>.
 */

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/settings-dialog.ui")]
class SettingsDialog : Hdy.PreferencesWindow {
  // UI-Elements of InterfacePage
  [GtkChild]
  private Gtk.Switch dark_theme_switch;
  [GtkChild]
  private Gtk.ComboBoxText media_visibility_box;
  [GtkChild]
  private Gtk.Switch auto_scroll_switch;
  [GtkChild]
  private Gtk.Switch double_click_switch;
  [GtkChild]
  private Gtk.Switch round_avatar_switch;
  [GtkChild]
  private Gtk.Switch trail_hashtags_switch;
  [GtkChild]
  private Gtk.Switch media_link_switch;
  [GtkChild]
  private Gtk.Switch hide_nsfw_switch;

  private bool block_flag_emission = false;

  public SettingsDialog () {
    var text_transform_flags = Settings.get_text_transform_flags ();

    // Bind InterfacePage switches to settings
    Settings.get ().bind ("use-dark-theme", dark_theme_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("media-visibility", media_visibility_box,
                          "active-id", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("auto-scroll-on-new-tweets", auto_scroll_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("double-click-activation", double_click_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("round-avatars", round_avatar_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("hide-nsfw-content", hide_nsfw_switch,
                          "active", SettingsBindFlags.DEFAULT);

    // Additional functions for InterfacePage
    dark_theme_switch.notify["active"].connect (setting_update_dark_theme);
    Settings.get ().changed["media-visibility"].connect(setting_update_media_visibility);
    block_flag_emission = true;
    trail_hashtags_switch.active = (Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS in
                                    text_transform_flags);
    media_link_switch.active = (Cb.TransformFlags.REMOVE_MEDIA_LINKS in text_transform_flags);
    block_flag_emission = false;
  }

  private void setting_update_dark_theme () {
    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = Settings.use_dark_theme();
  }

  [GtkCallback]
  private void setting_update_media_visibility () {
    block_flag_emission = true;
    if (Settings.get_media_visiblity () == MediaVisibility.SHOW) {
      media_link_switch.sensitive = true;
      media_link_switch.active = (Cb.TransformFlags.REMOVE_MEDIA_LINKS in Settings.get_text_transform_flags ());
    }
    else {
      media_link_switch.sensitive = false;
      media_link_switch.active = false;
    }
    block_flag_emission = false;
  }

  [GtkCallback]
  private void setting_update_auto_scroll () {
    print("\n\nHELLO TEST\n\n");
    //on_new_tweets_combobox.sensitive = !auto_scroll_switch.active;
  }

  [GtkCallback]
  private void setting_update_trail_hashtags () {
    if (block_flag_emission)
      return;

    if (trail_hashtags_switch.active) {
      Settings.add_text_transform_flag (Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS);
    } else {
      Settings.remove_text_transform_flag (Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS);
    }
  }

  [GtkCallback]
  private void setting_update_media_links () {
    if (block_flag_emission)
      return;

    if (media_link_switch.active) {
      Settings.add_text_transform_flag (Cb.TransformFlags.REMOVE_MEDIA_LINKS);
    } else {
      Settings.remove_text_transform_flag (Cb.TransformFlags.REMOVE_MEDIA_LINKS);
    }
  }
}
