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
  private Gtk.Image lower_level_symbol;

  // Non-UI-Elements of SnippetRow
  public Account account;
  public bool is_active;
  public int64 user_id;
  public bool lower_level;
  public string user_name {
    get { return this.get_title(); }
    set { this.set_title(value); }
  }
  public string screen_name {
    get { return this.get_subtitle(); }
    set { this.set_subtitle(value); }
  }

  // Signals of UserRow
  public signal void level_down ();

  public UserRow.from_account (Account acc, bool active = false, bool lowlevel = false) {
    // Add account data
    this.account = acc;
    this.user_id = account.id;
    this.user_name = account.name;
    this.screen_name = "@" + account.screen_name;
    this.is_active = active;
    this.lower_level = lowlevel;

    // Connect update signal
    acc.info_changed.connect (update_account);

    // Set symbols visibility
    update_active (is_active);
    if (lower_level) {
      lower_level_symbol.show();
    } else {
      level_down_button.show();
    }
  }

  public UserRow.from_row (UserRow row, bool active = false, bool lowlevel = false) {
    this.from_account(row.account, active, lowlevel);
  }

  public void update_active (bool active) {
    is_active = active;
    if (is_active) {
      user_active_symbol.icon_name = "object-select-symbolic";
    } else {
      user_active_symbol.icon_name = "";
    }
  }

  private void update_account (string screen_name, string name, Cairo.Surface nop, Cairo.Surface avatar) {
    this.screen_name = "@" + screen_name;
    this.user_name = name;
  }

  [GtkCallback]
  private void ui_action_level_down_button () {
    level_down();
  }
}
