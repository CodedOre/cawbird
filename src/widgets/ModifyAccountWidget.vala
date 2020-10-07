/* ModifyAccountWidget.vala
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

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/widget/modify-account-widget.ui")]
class ModifyAccountWidget : Gtk.Box {
  // UI-Elements of ModifyAccountWidget
  [GtkChild]
  private Gtk.Button header_confirm;

  // UI-Elements of DetailsPage
  [GtkChild]
  private Gtk.Entry name_entry;
  [GtkChild]
  private Gtk.Entry website_entry;

  // UI-Elements of OptionsPage
  [GtkChild]
  private Gtk.Switch autostart_switch;

  // Non-UI-Elements of ModifyAccountWidget
  private Account account;
  private string old_name;
  private string old_website;
  private bool old_autostart = false;

  // Change-States of ModifyAccountWidget
  private bool autostart_changed = false;

  // Signals of ModifyAccountWidget
  public signal void modify_done ();

  public ModifyAccountWidget (Account account) {
    this.account = account;
    this.set_sensitive (false);

    // Set up DetailsPage
    name_entry.text = account.name;
    website_entry.text = account.website ?? "";

    old_name = account.name;
    old_website = account.website ?? "";

    // Set up OptionsPage
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    foreach (unowned string acc in startup_accounts) {
      if (acc == this.account.screen_name) {
        this.old_autostart = true;
        autostart_switch.active = true;
        break;
      }
    }

    this.set_sensitive (true);
  }

  /*
   * Functions for OptionsPage
   */

  [GtkCallback]
  private void ui_action_autostart_switch () {
    if (autostart_switch.active != old_autostart) {
      autostart_changed = true;
    } else {
      autostart_changed = false;
    }
    check_changes ();
  }

  private void save_autostart () {
    bool active = autostart_switch.active;
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    if (active) {
      foreach (unowned string acc in startup_accounts) {
        if (acc == this.account.screen_name) {
          return;
        }
      }

      string[] new_startup_accounts = new string[startup_accounts.length + 1];
      int i = 0;
      foreach (unowned string s in startup_accounts) {
        new_startup_accounts[i] = s;
        i ++;
      }
      new_startup_accounts[new_startup_accounts.length - 1] = this.account.screen_name;
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
    } else {
      string[] new_startup_accounts = new string[startup_accounts.length - 1];
      int i = 0;
      foreach (unowned string acc in startup_accounts) {
        if (acc != this.account.screen_name) {
          new_startup_accounts[i] = acc;
          i ++;
        }
      }
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
    }
  }

  /*
   * General Functions
   */

  [GtkCallback]
  private void ui_action_header_cancel () {
    modify_done();
  }

  [GtkCallback]
  private void ui_action_header_confirm () {
    // Save elements for OptionsPage
    if (autostart_changed) {
      save_autostart ();
    }
    modify_done();
  }

  private void check_changes () {
    if (autostart_changed) {
      header_confirm.set_sensitive(true);
    } else {
      header_confirm.set_sensitive(false);
    }
  }
}
