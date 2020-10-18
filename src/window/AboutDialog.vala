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
class AboutDialog : Hdy.Window {
  // UI-Elements of AboutDialog
  [GtkChild]
  private Gtk.Grid link_grid;
  [GtkChild]
  private Gtk.Button website_button;
  [GtkChild]
  private Gtk.Button issue_button;
  [GtkChild]
  private Gtk.Separator link_info_separator;
  [GtkChild]
  private Gtk.Label app_name_label;
  [GtkChild]
  private Gtk.Label app_name_info;
  [GtkChild]
  private Gtk.Label version_label;
  [GtkChild]
  private Gtk.Label version_info;

  // Non-UI-Elements of AboutDialog
  private GLib.Settings window_settings;
  private string website_link = "https://ibboard.co.uk/cawbird/";
  private string issues_link = "https://github.com/IBBoard/cawbird/issues";
  private bool small_ui_mode = false;

  public AboutDialog () {
    this.window_settings = new GLib.Settings ("uk.co.ibboard.cawbird.window.dialog");
    load_geometry();
  }

  [GtkCallback]
  private void ui_action_website_button () {
    try {
      GLib.AppInfo.launch_default_for_uri(website_link, null);
    } catch (GLib.Error e) {
      error("Could not call \"%s\" because of the following error: %s", website_link, e.message);
    }
  }

  [GtkCallback]
  private void ui_action_issue_button () {
    try {
      GLib.AppInfo.launch_default_for_uri(issues_link, null);
    } catch (GLib.Error e) {
      error("Could not call \"%s\" because of the following error: %s", website_link, e.message);
    }
  }

  // Swaps positions of items on the grid to have an responsive grid
  [GtkCallback]
  private void ui_adaptive_change () {
    // Determine current size mode
    int width, height;
    bool current_ui_mode;
    this.get_size (out width, out height);
    if (width <= 450) {
      current_ui_mode = true;
    } else {
      current_ui_mode = false;
    }

    // Don't do anything if nothing changed
    if (current_ui_mode == small_ui_mode) {
      return;
    }
    small_ui_mode = current_ui_mode;
    rearrange_grid ();
  }

  private void rearrange_grid () {
    // Remove elements from grid
    link_grid.remove(website_button);
    link_grid.remove(issue_button);
    link_grid.remove(link_info_separator);
    link_grid.remove(app_name_label);
    link_grid.remove(app_name_info);
    link_grid.remove(version_label);
    link_grid.remove(version_info);

    // Add elements back to grid with updated position
    if (small_ui_mode) {
      link_grid.attach(website_button,      0, 0, 4, 1);
      link_grid.attach(issue_button,        0, 1, 4, 1);
      link_grid.attach(link_info_separator, 0, 2, 4, 1);
      link_grid.attach(app_name_label,      0, 3, 1, 1);
      link_grid.attach(app_name_info,       1, 3, 3, 1);
      link_grid.attach(version_label,       0, 4, 1, 1);
      link_grid.attach(version_info,        1, 4, 3, 1);
    } else {
      link_grid.attach(website_button,      0, 0, 2, 2);
      link_grid.attach(issue_button,        2, 0, 2, 2);
      link_grid.attach(link_info_separator, 0, 2, 4, 1);
      link_grid.attach(app_name_label,      0, 3, 1, 2);
      link_grid.attach(app_name_info,       1, 3, 1, 2);
      link_grid.attach(version_label,       2, 3, 1, 2);
      link_grid.attach(version_info,        3, 3, 1, 2);
    }
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
    rearrange_grid ();
  }

  private void save_geometry () {
    int width, height;
    this.get_size (out width, out height);
    window_settings.set ("window-size", "(ii)", width, height);
  }
}
