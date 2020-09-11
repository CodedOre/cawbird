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

#if OLD_HANDY
[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/list/snippet-row.ui")]
#else
[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/list/snippet-row.ui")]
#endif
class SnippetRow : Hdy.ActionRow {
  private SettingsDialog settings;
  public string keyword {
    get { return this.get_subtitle(); }
    set { this.set_subtitle(value); }
  }
  public string replacement {
    get { return this.get_title(); }
    set { this.set_title(value); }
  }

  public SnippetRow (string keyword, string replacement, SettingsDialog settings) {
    this.set_subtitle(keyword);
    this.set_title(replacement);
    this.settings = settings;
  }

  [GtkCallback]
  private void ui_action_row_clicked () {
    print("Down to deeper level!");
  }
}
