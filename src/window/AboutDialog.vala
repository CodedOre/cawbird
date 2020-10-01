/* AboutDialog.vala
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


[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/window/about-dialog.ui")]
#if OLD_HANDY
class AboutDialog : Gtk.Window {
#else
class AboutDialog : Hdy.Window {
#endif
  // UI-Elements of AboutDialog
  [GtkChild]
  private Hdy.Squeezer header_squeezer;
  [GtkChild]
  private Hdy.ViewSwitcher upper_stack_switch;
  [GtkChild]
  private Hdy.ViewSwitcherBar lower_stack_switch;

  // Non-UI-Elements of AboutDialog
  private GLib.Settings window_settings;
  private string website_link = "https://ibboard.co.uk/cawbird/";
  private string issues_link = "https://github.com/IBBoard/cawbird/issues";

  public AboutDialog () {
    this.window_settings = new GLib.Settings ("uk.co.ibboard.cawbird.window.dialog");
    load_geometry();
  }

  [GtkCallback]
  private void ui_action_website_button () {
    try {
      Gtk.show_uri_on_window(this, website_link, Gdk.CURRENT_TIME);
    } catch (GLib.Error e) {
      error("Could not call \"%s\" because of the following error: %s", website_link, e.message);
    }
  }

  [GtkCallback]
  private void ui_action_issue_button () {
    try {
      Gtk.show_uri_on_window(this, issues_link, Gdk.CURRENT_TIME);
    } catch (GLib.Error e) {
      error("Could not call \"%s\" because of the following error: %s", website_link, e.message);
    }
  }

  [GtkCallback]
  private void ui_adaptive_change () {
    var child = header_squeezer.get_visible_child();
    lower_stack_switch.set_reveal(child != upper_stack_switch);
  }

  [GtkCallback]
  private bool window_action_close () {
    save_geometry();
    return Gdk.EVENT_PROPAGATE;
  }

  private void load_geometry () {
    int width, height;
    window_settings.get ("window-size", "(ii)", out width, out height);
    this.resize (width, height);
  }

  private void save_geometry () {
    int width, height;
    this.get_size (out width, out height);
    window_settings.set ("window-size", "(ii)", width, height);
  }
}
