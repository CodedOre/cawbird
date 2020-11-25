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
  private AvatarBannerWidget avatar_banner_widget;
  [GtkChild]
  private Gtk.Entry name_entry;
  [GtkChild]
  private Gtk.Entry website_entry;

  // UI-Elements of OptionsPage
  [GtkChild]
  private Gtk.Switch autostart_switch;
  [GtkChild]
  private Gtk.Stack delete_group_stack;
  [GtkChild]
  private Hdy.ActionRow delete_action_row;
  [GtkChild]
  private Hdy.ActionRow delete_confirm_row;

  // Non-UI-Elements of ModifyAccountWidget
  private Account account;
  private string old_name;
  private string old_website;
  private bool old_autostart = false;

  // Change-States of ModifyAccountWidget
  private bool details_changed   = false;
  private bool autostart_changed = false;

  // Signals of ModifyAccountWidget
  public signal void modify_done ();

  public ModifyAccountWidget (Account account) {
    this.account = account;

    // Set up DetailsPage
    this.avatar_banner_widget.set_account (account);
    this.old_name = account.name;
    this.old_website = account.website ?? "";

    this.name_entry.text = account.name;
    this.website_entry.text = account.website ?? "";

    // Set up OptionsPage
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    foreach (unowned string acc in startup_accounts) {
      if (acc == this.account.screen_name) {
        this.old_autostart = true;
        this.autostart_switch.active = true;
        break;
      }
    }
  }

  /*
   * Functions for DetailsPage
   */

  [GtkCallback]
  private void ui_action_details_changed () {
    details_changed = true;
    if (website_entry.text == old_website
        && name_entry.text == old_name) {
      details_changed = false;
      print("No one cares!");
    }

    if (name_entry.text == "") {
      name_entry.secondary_icon_name = "dialog-warning-symbolic";
      name_entry.secondary_icon_tooltip_text = _("Name can't be empty");
      details_changed = false;
    }
    print("Entry checked!\n");
    check_changes ();
  }

  private void save_details () {
    bool needs_save = (old_name    != name_entry.text) ||
                      //(old_description != description_text_view.buffer.text) ||
                      (old_website != website_entry.text);

    if (needs_save && account.proxy == null) {
      account.init_proxy ();
    }

    if (needs_save) {
      debug ("Saving data...");
      var call = account.proxy.new_call ();
      call.set_function ("1.1/account/update_profile.json");
      call.set_method ("POST");
      call.add_param ("url",  website_entry.text);
      call.add_param ("name", name_entry.text);
      //call.add_param ("description", description_text_view.buffer.text);
      call.invoke_async.begin (null, (obj, res) => {
        try {
          call.invoke_async.end (res);
          debug ("Profile successfully updated");
        } catch (GLib.Error e) {
          warning (e.message);
          //TODO: Utils.show_error_dialog (TweetUtils.failed_request_to_error (call, e), this);
        }
      });

      /* Update local user data */
      account.name = name_entry.text;
      //account.description = description_text_view.buffer.text;
      account.website = website_entry.text;
    }
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

  [GtkCallback]
  private void ui_action_delete_active () {
    delete_group_stack.set_visible_child (delete_confirm_row);
  }

  [GtkCallback]
  private void ui_action_delete_cancel () {
    delete_group_stack.set_visible_child (delete_action_row);
  }

  [GtkCallback]
  private void ui_reset_delete_stack () {
    unowned Gtk.Widget visible_row = delete_group_stack.get_visible_child ();
    if (visible_row != delete_action_row) {
      delete_group_stack.set_visible_child (delete_action_row);
    }
  }

  [GtkCallback]
  private void ui_action_delete_confirm () {
    /*
       - Close open window of that account
       - Remove the account from the db, disk, etc.
       - Remove the account from the app menu
       - If this would close the last opened window,
         set the account of that window to NULL
     */
    int64 acc_id = account.id;
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).db"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).png"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id)_small.png"));
    Cawbird.db.exec (@"DELETE FROM `accounts` WHERE `id`='$(acc_id)';");

    /* Remove account from startup accounts, if it's in there */
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    for (int i = 0; i < startup_accounts.length; i++) {
      if (startup_accounts[i] == account.screen_name) {
        string[] sa_new = new string[startup_accounts.length - 1];
        for (int x = 0; x < i; i++) {
          sa_new[x] = startup_accounts[x];
        }
        for (int x = i+1; x < startup_accounts.length; x++) {
          sa_new[x] = startup_accounts[x];
        }
        Settings.get ().set_strv ("startup-accounts", sa_new);
      }
    }

    Cawbird cb = (Cawbird) GLib.Application.get_default ();

    /* Handle windows, i.e. if this MainWindow is the last open one,
       we want to use it to show the "new account" UI, otherwise we
       just close it. */
    unowned GLib.List<Gtk.Window> windows = cb.get_windows ();
    Gtk.Window? account_window = null;
    int n_main_windows = 0;
    foreach (Gtk.Window win in windows) {
      if (win is MainWindow) {
        n_main_windows ++;
        if (((MainWindow)win).account.id == this.account.id) {
          account_window = win;
        }
      }
    }
    debug ("Open main windows: %d", n_main_windows);

    if (account_window != null) {
      if (n_main_windows > 1) {
        account_window.destroy ();
      }
      else {
        Account first_acct = null;
        Account first_startup_acct = null;
        startup_accounts = Settings.get ().get_strv ("startup-accounts");
        string startup_acct = null;
        if (startup_accounts.length > 0) {
          startup_acct = startup_accounts[0];
        }

        for (uint i = 0; i < Account.get_n (); i ++) {
          var acct = Account.get_nth (i);
          if (acct.screen_name == Account.DUMMY || acct.screen_name == account.screen_name) {
            continue;
          }
          else if (acct.screen_name == startup_acct) {
            first_startup_acct = acct;
          }
          else if (first_acct == null) {
            first_acct = acct;
          }
        }

        ((MainWindow)account_window).change_account (first_startup_acct ?? first_acct);
      }
    }

    /* Remove the account from the global list of accounts */
    Account acc_to_remove = Account.query_account_by_id (acc_id);
    cb.account_removed (acc_to_remove);
    Account.remove_account (acc_to_remove.screen_name);

    /* Close this dialog */
    modify_done();
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
    if (details_changed) {
      save_details ();
    }
    modify_done();
  }

  private void check_changes () {
    if ( autostart_changed
      || details_changed ) {
      header_confirm.set_sensitive(true);
    } else {
      header_confirm.set_sensitive(false);
    }
  }
}
