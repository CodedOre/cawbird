/* MainWindow.vala
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

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/window/main-window.ui")]
public class MainWindow : Gtk.ApplicationWindow {
  // GLib Actions
  private const GLib.ActionEntry[] win_entries = {
    {"compose-tweet",       show_hide_compose_window},
    {"toggle-topbar",       Settings.toggle_topbar_visible},
    {"switch-page",         simple_switch_page, "i"},
    {"previous",            previous},
    {"next",                next}
  };

  // UI-Elements of MainWindow
  [GtkChild]
  private Hdy.Squeezer header_squeezer;
  [GtkChild]
  private Hdy.ViewSwitcher upper_stack_switch;
  [GtkChild]
  private Hdy.ViewSwitcherBar lower_stack_switch;
  [GtkChild]
  public Gtk.Button back_button;
  [GtkChild]
  public Gtk.ToggleButton compose_tweet_button;
  [GtkChild]
  private Gtk.Button search_button;
  [GtkChild]
  private Gtk.ToggleButton app_menu_button;

  // UI-Elements of AppMenu
  [GtkChild]
  private Gtk.PopoverMenu app_menu_popover;
  [GtkChild]
  private Gtk.ListBox main_account_list;
  [GtkChild]
  private Gtk.ListBox account_details_row_holder;

  // Non-UI-Elements of MainWindow
  public MainWidget main_widget;
  public unowned Account? account;
  private GLib.Settings window_settings;
  private ComposeTweetWindow? compose_tweet_window = null;
  private Gtk.GestureMultiPress thumb_button_gesture;

  public int cur_page_id {
    get {
      return main_widget.cur_page_id;
    }
  }

  public MainWindow (Gtk.Application app, Account? account = null) {
    this.window_settings = new GLib.Settings ("uk.co.ibboard.cawbird.window.main-window");
    var group = new Gtk.WindowGroup ();
    group.add_window (this);

#if DEBUG
    this.set_focus.connect ((w) => {
      debug ("Focus widget now: %s %p", w != null ? __class_name (w) : "(null)", w);
    });
#endif

    main_account_list.set_sort_func (account_sort_func);
    for (uint i = 0; i < Account.get_n (); i ++) {
      var acc = Account.get_nth (i);
      if (acc.screen_name == Account.DUMMY) {
          continue;
      }
      UserRow row = new UserRow.from_account (acc, MAIN_LIST);
      row.button_action.connect(open_account_detail_page);
      main_account_list.add(row);
    }

    change_account (account);

    ((Cawbird)app).account_added.connect ((new_acc) => {
      UserRow row = new UserRow.from_account(new_acc, MAIN_LIST);
      row.button_action.connect(open_account_detail_page);
      main_account_list.add(row);
    });

    ((Cawbird)app).account_removed.connect ((acc) => {
      var entries = main_account_list.get_children ();
      foreach (Gtk.Widget urow in entries)
        if (urow is UserRow &&
            acc.screen_name == ((UserRow)urow).screen_name) {
          main_account_list.remove (urow);
          break;
        }
    });

    this.add_action_entries (win_entries, this);

    this.thumb_button_gesture = new Gtk.GestureMultiPress (this);
    thumb_button_gesture.set_button (0);
    thumb_button_gesture.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
    thumb_button_gesture.pressed.connect (thumb_button_pressed_cb);

    load_geometry ();
  }

  [GtkCallback]
  private void ui_action_back_button () {
    main_widget.switch_page (Page.PREVIOUS);
  }

  [GtkCallback]
  private void ui_action_settings_menu_button () {
    Cawbird cb = (Cawbird)this.get_application ();
    new SettingsDialog (cb);
  }

  [GtkCallback]
  private void ui_action_about_menu_button () {
    AboutDialog about_window = new AboutDialog ();
    about_window.set_transient_for(this);
    about_window.show();
  }

  [GtkCallback]
  private void ui_action_main_account_list (Gtk.ListBoxRow row) {
    UserRow e = (UserRow)row;
    int64 user_id = e.user_id;
    Cawbird cb = (Cawbird)this.get_application ();

    MainWindow? account_window = null;
    if (user_id == this.account.id ||
        cb.is_window_open_for_user_id (user_id, out account_window)) {

      if (account_window != null)
        account_window.present ();

      return;
    }

    Account? acc = Account.query_account_by_id (user_id);
    if (acc != null) {
      change_account (acc);
    } else
      warning ("account == null");
  }

  private void open_account_detail_page (UserRow row) {
    UserRow detail_row = new UserRow.from_row (row, MAIN_DETAIL);
    foreach (Gtk.Widget element in account_details_row_holder.get_children ()) {
      account_details_row_holder.remove (element);
    }
    account_details_row_holder.add(detail_row);
    this.app_menu_popover.open_submenu("account-detail");
  }

  [GtkCallback]
  private void ui_action_account_details_back (Gtk.ListBoxRow row) {
    this.app_menu_popover.open_submenu("main");
  }

  [GtkCallback]
  private void ui_action_account_in_new_window () {
    Gtk.ListBoxRow detail_row = account_details_row_holder.get_row_at_index(0);
    if (detail_row == null) {
      return;
    }
    UserRow row = (UserRow) detail_row;
    Account account = row.account;
    var cb = (Cawbird) GLib.Application.get_default ();
    var window = new MainWindow (cb, account);
    cb.add_window (window);
    window.show();
  }

  [GtkCallback]
  private void ui_action_view_profile () {
    Gtk.ListBoxRow detail_row = account_details_row_holder.get_row_at_index(0);
    if (detail_row == null) {
      return;
    }
    UserRow row = (UserRow) detail_row;
    var bundle = new Cb.Bundle ();
    bundle.put_int64 (ProfilePage.KEY_USER_ID, row.user_id);
    bundle.put_string (ProfilePage.KEY_SCREEN_NAME, row.screen_name);
    this.main_widget.switch_page (Page.PROFILE, bundle);
  }

  [GtkCallback]
  private void ui_adaptive_change () {
    var child = header_squeezer.get_visible_child();
    lower_stack_switch.set_reveal(child != upper_stack_switch);
  }

  [GtkCallback]
  private bool window_action_close (Gdk.EventAny event) {

    if (main_widget != null)
      main_widget.stop ();

    if (account == null)
      return Gdk.EVENT_PROPAGATE;

    unowned GLib.List<Gtk.Window> ws = this.application.get_windows ();
    debug("Windows: %u", ws.length ());

    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    if (startup_accounts.length == 1 && startup_accounts[0] == "")
      startup_accounts.resize (0);

    save_geometry ();

    if (startup_accounts.length > 0)
      return Gdk.EVENT_PROPAGATE;

    int n_main_windows = 0;
    foreach (Gtk.Window win in ws)
      if (win is MainWindow &&
          ((MainWindow) win).account != null &&
          ((MainWindow) win).account.screen_name != Account.DUMMY)
        n_main_windows ++;


    if (n_main_windows == 1) {
      // This is the last window so we save this one anyways...
      string[] new_startup_accounts = new string[1];
      new_startup_accounts[0] = ((MainWindow)ws.nth_data (0)).account.screen_name;
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
      debug ("Saving the account %s", ((MainWindow)ws.nth_data (0)).account.screen_name);
    }
    return Gdk.EVENT_PROPAGATE;
  }

  public void change_account (Account? account) {
    int64? old_user_id = null;
    if (this.account != null) {
      old_user_id = this.account.id;
      this.account.info_changed.disconnect (account_info_changed);
    }
    this.account = account;

    if (main_widget != null) {
      main_widget.stop ();
    }

    if (get_child () != null) {
      remove (get_child ());
    }

    Cawbird cb = (Cawbird) GLib.Application.get_default ();

    if (account != null && account.screen_name != Account.DUMMY) {
      main_widget = new MainWidget (account, this, cb);
      main_widget.show_all ();
      this.add (main_widget);
      main_widget.switch_page (0);
      this.set_window_title (main_widget.get_page (0).get_title ());

      foreach (Gtk.Widget element in main_account_list.get_children ()) {
        if (element is UserRow) {
          UserRow row = (UserRow)element;
          if (row.account == account) {
            row.update_active(true);
          } else {
            row.update_active(false);
          }
        }
      }

      account.info_changed.connect (account_info_changed);
      this.set_title ("Cawbird - @%s".printf (account.screen_name));

      cb.account_window_changed (old_user_id, account.id);
    } else {
      /* "Special case" when creating a new account */

      Account acc_;
      if (account == null)
        acc_ = new Account (0, Account.DUMMY, "name");
      else
        acc_ = account;

      this.account = acc_;

      this.set_title ("Cawbird");

      Account.add_account (acc_);
      var create_widget = new AccountCreateWidget (acc_, cb, this);
      create_widget.result_received.connect ((result, acc) => {
        if (result) {
          change_account (acc);
        } else {
          //Account.remove ("screen_name");
        }
      });
      this.add (create_widget);
    }

  }

  private void thumb_button_pressed_cb (Gtk.GestureMultiPress gesture,
                                        int                   n_press,
                                        double                x,
                                        double                y) {
    uint button = gesture.get_current_button ();
    if (button == 9) {
      // Forward thumb button
      main_widget.switch_page (Page.NEXT);
      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    } else if (button == 8) {
      // backward thumb button
      main_widget.switch_page (Page.PREVIOUS);
      gesture.set_state (Gtk.EventSequenceState.CLAIMED);
    }
  }

  private void show_hide_compose_window () {
    if (this.account == null ||
        this.account.screen_name == Account.DUMMY)
      return;

    if (compose_tweet_window == null) {
      compose_tweet_window = new ComposeTweetWindow (this, account, null,
                                                     ComposeTweetWindow.Mode.NORMAL);
      compose_tweet_window.show ();
      compose_tweet_window.hide.connect (() => {
        compose_tweet_button.active = false;
      });

      compose_tweet_window.destroy.connect (() => {
        compose_tweet_window = null;
      });
    } else {
      compose_tweet_window.hide ();
      compose_tweet_window.destroy ();
    }
  }

  /**
   * GSimpleActionActivateCallback version of switch_page, used
   * for keyboard accelerators.
   */
  private void simple_switch_page (GLib.SimpleAction a, GLib.Variant? param) {
    main_widget.switch_page (param.get_int32 ());
  }

  private void previous (GLib.SimpleAction a, GLib.Variant? param) {
    if (this.account == null ||
        this.account.screen_name == Account.DUMMY)
      return;

    main_widget.switch_page (Page.PREVIOUS);
  }

  private void next (GLib.SimpleAction a, GLib.Variant? param) {
    if (this.account == null ||
        this.account.screen_name == Account.DUMMY)
      return;

    main_widget.switch_page (Page.NEXT);
  }

  public IPage get_page (int page_id) {
    return main_widget.get_page (page_id);
  }

  private void account_info_changed (string        screen_name,
                                     string        name,
                                     Cairo.Surface small_avatar,
                                     Cairo.Surface avatar) {
    this.set_window_title (main_widget.get_page (main_widget.cur_page_id).get_title ());
    this.set_title ("Cawbird - @%s".printf (screen_name));
  }

  /**
   *
   */
  private void load_geometry () {
    if (account == null || account.screen_name == Account.DUMMY) {
      debug ("Could not load geometry, account == null");
      return;
    }

    int x, y, width, height;
    GLib.Variant win_pos = window_settings.get_value ("window-pos");
    GLib.Variant win_size = window_settings.get_value ("window-size");

    if (!win_pos.lookup (account.screen_name, "(ii)", out x, out y)) {
      warning ("Couldn't load window geometry for screen_name `%s'", account.screen_name);
      return;
    }
    if (!win_size.lookup (account.screen_name, "(ii)", out width, out height)) {
      warning ("Couldn't load window geometry for screen_name `%s'", account.screen_name);
      return;
    }

    if (width == 0 || height == 0)
      return;

    this.move (x, y);
    this.resize (width, height);
  }

  /**
   * Saves this window's geometry in the window-geometry gsettings key.
   */
  public void save_geometry () {
    if (account == null || account.screen_name == Account.DUMMY)
      return;

    GLib.Variant win_pos = window_settings.get_value ("window-pos");
    GLib.Variant win_size = window_settings.get_value ("window-size");
    GLib.Variant new_pos;
    GLib.Variant new_size;

    GLib.VariantBuilder pos_builder = new GLib.VariantBuilder (new GLib.VariantType("a{s(ii)}"));
    GLib.VariantBuilder size_builder = new GLib.VariantBuilder (new GLib.VariantType("a{s(ii)}"));

    var pos_iter = win_pos.iterator ();
    var size_iter = win_size.iterator ();

    string? key = null;
    int x, y, w, h;
    while (pos_iter.next ("{s(ii)}", out key, out x, out y)) {
      if (key != account.screen_name) {
        pos_builder.add ("{s(ii)}", key, x, y);
      }
      key = null; // Otherwise we leak key
    }
    key = null;
    while (size_iter.next ("{s(ii)}", out key, out w, out h)) {
      if (key != account.screen_name) {
        size_builder.add ("{s(ii)}", key, w, h);
      }
      key = null; // Otherwise we leak key
    }

    /* Finally, add this window */
    this.get_position (out x, out y);
    this.get_size (out w, out h);
    pos_builder.add ("{s(ii)}", account.screen_name, x, y);
    size_builder.add ("{s(ii)}", account.screen_name, w, h);
    new_pos = pos_builder.end ();
    new_size = size_builder.end ();
    debug ("Saving geomentry for %s: %d,%d,%d,%d", account.screen_name, x, y, w, h);

    window_settings.set_value ("window-pos", new_pos);
    window_settings.set_value ("window-size", new_size);
  }

  private int account_sort_func (Gtk.ListBoxRow a,
                                 Gtk.ListBoxRow b) {
    return ((UserRow)a).screen_name.ascii_casecmp (((UserRow)b).screen_name);
  }

  public void rerun_filters () {
    /* We only do this for stream + mentions at the moment */
    ((DefaultTimeline)get_page (Page.STREAM)).rerun_filters ();
    ((DefaultTimeline)get_page (Page.MENTIONS)).rerun_filters ();
  }

  public void set_window_title (string title,
                                Gtk.StackTransitionType transition_type = Gtk.StackTransitionType.NONE) {
    // TODO: Reimplement
  }

  public void reply_to_tweet (int64 tweet_id) {
    Cb.Tweet? tweet = null;
    tweet = ((DefaultTimeline)this.main_widget.get_page(Page.STREAM)).tweet_list.model.get_for_id (tweet_id,
                                                                                                   0);
    if (tweet == null) {
      warning ("tweet with id %s could not be found", tweet_id.to_string ());
      return;
    }

    var ctw = new ComposeTweetWindow (this, this.account, tweet,
                                      ComposeTweetWindow.Mode.REPLY);
    ctw.show_all ();
  }

  public void mark_tweet_as_read (int64 tweet_id) {
    DefaultTimeline home_timeline     = ((DefaultTimeline)this.main_widget.get_page(Page.STREAM));
    DefaultTimeline mentions_timeline = ((DefaultTimeline)this.main_widget.get_page(Page.MENTIONS));
    Cb.Tweet? tweet = null;
    tweet = home_timeline.tweet_list.model.get_for_id (tweet_id,
                                                       0);
    if (tweet != null) {
      tweet.set_seen (true);
      home_timeline.unread_count --;
    }

    // and now with the MentionsTimeline
    tweet = mentions_timeline.tweet_list.model.get_for_id (tweet_id,
                                                           0);
    if (tweet != null) {
      tweet.set_seen (true);
      mentions_timeline.unread_count --;
    }
  }
}
