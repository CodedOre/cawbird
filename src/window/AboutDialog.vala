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
  private string website_link = "https://ibboard.co.uk/cawbird/";
  private string issues_link = "https://github.com/IBBoard/cawbird/issues";

  [GtkCallback]
  private void ui_action_website_button () {
    Gtk.show_uri_on_window(this, website_link, Gdk.CURRENT_TIME);
  }

  [GtkCallback]
  private void ui_action_issue_button () {
    Gtk.show_uri_on_window(this, issues_link, Gdk.CURRENT_TIME);
  }

  [GtkCallback]
  private void ui_adaptive_change () {
    var child = header_squeezer.get_visible_child();
    lower_stack_switch.set_reveal(child != upper_stack_switch);
  }
}
