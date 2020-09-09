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

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/settings-dialog.ui")]
class SettingsDialog : Hdy.PreferencesWindow {
  // UI-Elements of InterfacePage
  [GtkChild]
  private Gtk.Switch dark_ui_switch;

  public SettingsDialog () {
    // Bind switches to the corresponding settings
    Settings.get ().bind ("use-dark-theme", dark_ui_switch, "active", SettingsBindFlags.DEFAULT);
    dark_ui_switch.notify["active"].connect (() => {
      Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = Settings.use_dark_theme();
    });
  }
}
