/* UserRow.vala
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

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/list/user-row.ui")]
class UserRow : Hdy.ActionRow {
  // UI-Elements of UserRow
  [GtkChild]
  private Gtk.Image user_active_symbol;
  [GtkChild]
  private Gtk.Button level_down_button;
  [GtkChild]
  private Gtk.Button edit_account_button;
  [GtkChild]
  private Gtk.Image lower_level_symbol;
  [GtkChild]
  private AvatarWidget user_avatar;

  // Non-UI-Elements of SnippetRow
  public Account account;
  public int64 user_id;
  public string user_name {
    get { return this.get_title(); }
    set { this.set_title(value); }
  }
  public string screen_name {
    get { return this.get_subtitle(); }
    set { this.set_subtitle(value); }
  }
  public string avatar_url {
    set { real_set_avatar (value); }
  }
  public Cairo.Surface avatar_surface {
    set { user_avatar.surface = value; }
  }

  // Variants of UserRow
  public enum row_variant {
    CLEAR,
    MAIN_LIST,
    MAIN_DETAIL,
    SETTINGS
  }
  public bool is_active {
    set {
      if (value) {
        user_active_symbol.icon_name = "object-select-symbolic";
      } else {
        user_active_symbol.icon_name = "";
      }
    }
  }

  // Signals of UserRow
  public signal void button_action ();

  public UserRow.from_account (Account acc, row_variant mode = CLEAR) {
    // Add account data
    this.account = acc;
    this.user_id = account.id;
    this.user_name = account.name;
    this.avatar_surface = acc.avatar;
    this.screen_name = "@" + account.screen_name;
    this.is_active = false;

    // Connect update signal
    acc.info_changed.connect (update_account);
    acc.notify["avatar"].connect (() => {
      this.avatar_surface = this.account.avatar;
    });

    // Set up wanted behavior according to the mode
    switch (mode) {
      case CLEAR:
        break;
      case MAIN_LIST:
        user_active_symbol.show();
        level_down_button.show();
        break;
      case MAIN_DETAIL:
        lower_level_symbol.show();
        break;
      case SETTINGS:
        this.set_activatable_widget(edit_account_button);
        edit_account_button.show();
        break;
      default:
        throw new GLib.OptionError.BAD_VALUE("No know UserRow variant");
    }
  }

  public UserRow.from_row (UserRow row, row_variant mode = CLEAR) {
    this.from_account(row.account, mode);
  }

  public void update_active (bool active) {
    is_active = active;
  }

  private void real_set_avatar (string avatar_url) {
    Twitter.get ().get_avatar.begin (user_id, avatar_url, user_avatar, 48 * this.get_scale_factor ());
  }

  private void update_account (string screen_name, string name, Cairo.Surface nop, Cairo.Surface avatar) {
    this.screen_name = "@" + screen_name;
    this.user_name = name;
    this.avatar_surface = avatar;
  }

  [GtkCallback]
  private void ui_action_button_press () {
    button_action();
  }
}
