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

#if OLD_HANDY
[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/window/settings-dialog.old.ui")]
#else
[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/window/settings-dialog.ui")]
#endif
class SettingsDialog : Hdy.PreferencesWindow {
  // UI-Elements of InterfacePage
  [GtkChild]
  private Gtk.Switch dark_theme_switch;
  [GtkChild]
  private Gtk.ComboBoxText media_visibility_combo;
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

  // UI-Elements of NotificationPage
  [GtkChild]
  private Gtk.ComboBoxText new_tweet_combo;
  [GtkChild]
  private Gtk.Switch new_mention_switch;
  [GtkChild]
  private Gtk.Switch new_message_switch;

  // UI-Elements of SnippetsPage
  [GtkChild]
  private Hdy.PreferencesGroup snippets_list;

  private bool block_flag_emission = false;

  public SettingsDialog () {
    var text_transform_flags = Settings.get_text_transform_flags ();

    // Bind InterfacePage switches to settings
    Settings.get ().bind ("use-dark-theme", dark_theme_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("media-visibility", media_visibility_combo,
                          "active-id", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("auto-scroll-on-new-tweets", auto_scroll_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("double-click-activation", double_click_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("round-avatars", round_avatar_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("hide-nsfw-content", hide_nsfw_switch,
                          "active", SettingsBindFlags.DEFAULT);

    // Bind NotificationPage switches to settings
    Settings.get ().bind ("new-tweets-notify", new_tweet_combo,
                          "active-id", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-mentions-notify", new_mention_switch,
                          "active", SettingsBindFlags.DEFAULT);
    Settings.get ().bind ("new-dms-notify", new_message_switch,
                          "active", SettingsBindFlags.DEFAULT);

    // Additional functions for InterfacePage
    Settings.get ().changed["media-visibility"].connect(setting_update_media_visibility);
    block_flag_emission = true;
    trail_hashtags_switch.active = (Cb.TransformFlags.REMOVE_TRAILING_HASHTAGS in
                                    text_transform_flags);
    media_link_switch.active = (Cb.TransformFlags.REMOVE_MEDIA_LINKS in text_transform_flags);
    block_flag_emission = false;

    // Additional functions for NotificationPage
    update_new_tweet_access ();

    load_geometry();
  }

  /*
   * Signal Handling for InterfacePage
   */

  [GtkCallback]
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
  private void update_new_tweet_access () {
    new_tweet_combo.sensitive = !auto_scroll_switch.active;
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

  /*
   * General Functions
   */

  [GtkCallback]
  private bool window_action_close () {
    save_geometry ();
    return Gdk.EVENT_PROPAGATE;
  }

  private void load_geometry () {
    GLib.Variant geom = Settings.get ().get_value ("settings-geometry");
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    x = geom.get_child_value (0).get_int32 ();
    y = geom.get_child_value (1).get_int32 ();
    w = geom.get_child_value (2).get_int32 ();
    h = geom.get_child_value (3).get_int32 ();
    if (w == 0 || h == 0)
      return;

    this.move (x, y);
    this.set_default_size (w, h);
  }

  private void save_geometry () {
    var builder = new GLib.VariantBuilder (GLib.VariantType.TUPLE);
    int x = 0,
        y = 0,
        w = 0,
        h = 0;
    this.get_position (out x, out y);
    this.get_size (out w, out h);
    builder.add_value (new GLib.Variant.int32(x));
    builder.add_value (new GLib.Variant.int32(y));
    builder.add_value (new GLib.Variant.int32(w));
    builder.add_value (new GLib.Variant.int32(h));
    Settings.get ().set_value ("settings-geometry", builder.end ());
  }
}
