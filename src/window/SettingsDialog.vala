/* SettingsDialog.vala
 *
 * This file is part of Cawbird, a Gtk+ linux Twitter client forked from Corebird.
 * Copyright 2020 Frederick Schenk
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/window/settings-dialog.ui")]
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

  // UI-Elements of AccountsPage
  [GtkChild]
  private Gtk.ListBox accounts_list;

  // UI-Elements of SnippetsPage
  [GtkChild]
  private Hdy.PreferencesGroup snippets_list;

  // Non-UI-Elements of SettingsDialog
  private GLib.Settings window_settings;
  private unowned Cawbird cawbird;
  private bool block_flag_emission = false;

  public SettingsDialog (Cawbird cawbird) {
    this.window_settings = new GLib.Settings ("uk.co.ibboard.cawbird.window.settings");
    this.cawbird = cawbird;
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

    // Populate AccountsPage with accounts
    accounts_list.set_sort_func (account_sort_func);
    for (uint i = 0; i < Account.get_n (); i ++) {
      var acc = Account.get_nth (i);
      if (acc.screen_name == Account.DUMMY) {
          continue;
      }
      UserRow row = new UserRow.from_account (acc, SETTINGS);
      accounts_list.add(row);
    }

    cawbird.account_added.connect ((new_acc) => {
      UserRow row = new UserRow.from_account(new_acc, SETTINGS);
      accounts_list.add(row);
    });

    cawbird.account_removed.connect ((acc) => {
      var entries = accounts_list.get_children ();
      foreach (Gtk.Widget urow in entries)
        if (urow is UserRow &&
            acc.screen_name == ((UserRow)urow).screen_name) {
          accounts_list.remove (urow);
          break;
        }
    });

    // Populate SnippetsPage with snippets
    Cawbird.snippet_manager.query_snippets ((keyword, replacement) => {
      SnippetRow row = new SnippetRow((string) keyword, (string) replacement, this);
      snippets_list.add(row);
    });

    load_geometry();
  }

  /*
   * Functions for InterfacePage
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
   * Functions for AccountsPage
   */
  [GtkCallback]
  private void ui_action_add_account () {
    CreateAccountWidget add_widget = new CreateAccountWidget (cawbird);
    add_widget.widget_closed.connect(close_account_creator);
    this.present_subpage(add_widget);
  }

  private void close_account_creator (Account? acc = null) {
    if (acc != null) {
      Account.add_account (acc);
    }
    this.close_subpage();
  }

  private int account_sort_func (Gtk.ListBoxRow a,
                                 Gtk.ListBoxRow b) {
    return ((UserRow)a).screen_name.ascii_casecmp (((UserRow)b).screen_name);
  }

  /*
   * Functions for SnippetsPage
   */

  [GtkCallback]
  private void ui_action_add_snippet () {
    ModifySnippetWidget mod_widget = new ModifySnippetWidget();
    mod_widget.modify_done.connect(close_snippet_modifier);
    this.present_subpage(mod_widget);
  }

  public void close_snippet_modifier (string? new_keyword = null, string? new_replacement = null) {
    if (new_keyword != null && new_replacement != null) {
      SnippetRow row = new SnippetRow(new_keyword, new_replacement, this);
      snippets_list.add(row);
    }
    this.close_subpage();
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
    int x, y, width, height;
    window_settings.get ("window-pos", "(ii)", out x, out y);
    window_settings.get ("window-size", "(ii)", out width, out height);
    this.move (x, y);
    this.resize (width, height);
  }

  private void save_geometry () {
    int x, y, width, height;
    this.get_size (out width, out height);
    this.get_position (out x, out y);
    window_settings.set ("window-pos", "(ii)", x, y);
    window_settings.set ("window-size", "(ii)", width, height);
  }
}
