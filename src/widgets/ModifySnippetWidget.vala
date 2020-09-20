/* ModifySnippetWidget.vala
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

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/widget/modify-snippet-widget.ui")]
#if OLD_HANDY
class ModifySnippetWidget : Gtk.Window {
#else
class ModifySnippetWidget : Gtk.Box {
#endif
  // UI-Elements of ModifySnippetWidget
  [GtkChild]
  private Gtk.Entry keyword_entry;
  [GtkChild]
  private Gtk.Entry replacement_entry;
  [GtkChild]
  private Gtk.Button header_confirm;
  [GtkChild]
  private Hdy.ActionRow delete_row;

  // Non-UI-Elements of ModifySnippetWidget
  private string old_key;

  // Signals of ModifySnippetWidget
  public signal void modify_done (string? new_keyword = null, string? new_replacement = null, bool remove = false);
#if OLD_HANDY
  private GLib.Settings window_settings;
#endif

  public ModifySnippetWidget (string? keyword = null, string? replacement = null) {
#if OLD_HANDY
    this.window_settings = new GLib.Settings ("uk.co.ibboard.cawbird.window.dialog");
#endif
    old_key = keyword;
    if (keyword != null) {
      keyword_entry.text = keyword;
    }
    else {
      delete_row.set_visible(false);
    }
    if (replacement != null) {
      replacement_entry.text = replacement;
    }
    if (keyword != null && replacement != null) {
      header_confirm.set_sensitive(true);
    }
#if OLD_HANDY
    load_geometry();
    this.set_modal(true);
#endif
  }

  [GtkCallback]
  private void ui_action_header_cancel () {
    modify_done();
#if OLD_HANDY
    save_geometry();
    this.destroy();
#endif
  }

  [GtkCallback]
  private void ui_action_header_confirm () {
    string new_keyword     = this.keyword_entry.text;
    string new_replacement = this.replacement_entry.text;

    if (this.old_key != null) {
      Cawbird.snippet_manager.set_snippet (old_key, new_keyword, new_replacement);
    } else {
      Cawbird.snippet_manager.insert_snippet (new_keyword, new_replacement);
    }

    modify_done(new_keyword, new_replacement);
#if OLD_HANDY
    save_geometry();
    this.destroy();
#endif
  }

  [GtkCallback]
  private void ui_action_entry_changed () {
    bool allow_confirm = true;
    if (keyword_entry.text == "") {
      keyword_entry.secondary_icon_name = "dialog-warning-symbolic";
      keyword_entry.secondary_icon_tooltip_text = _("Keyword can't be empty");
      allow_confirm = false;
    }
    if (replacement_entry.text == "") {
      replacement_entry.secondary_icon_name = "dialog-warning-symbolic";
      replacement_entry.secondary_icon_tooltip_text = _("Replacement can't be empty");
      allow_confirm = false;
    }
    if (keyword_entry.text.contains (" ")
     || keyword_entry.text.contains ("\t")) {
      keyword_entry.secondary_icon_name = "dialog-warning-symbolic";
      keyword_entry.secondary_icon_tooltip_text = _("Keyword may not contain whitespace");
      allow_confirm = false;
    }
    if (Cawbird.snippet_manager.get_snippet (keyword_entry.text) != null
     && this.old_key != keyword_entry.text) {
      keyword_entry.secondary_icon_name = "dialog-warning-symbolic";
      keyword_entry.secondary_icon_tooltip_text = _("Snippet already exists");
      allow_confirm = false;
    }
    if (allow_confirm) {
      keyword_entry.secondary_icon_name = "";
      keyword_entry.secondary_icon_tooltip_text = "";
      replacement_entry.secondary_icon_name = "";
      replacement_entry.secondary_icon_tooltip_text = "";
    }
    header_confirm.set_sensitive(allow_confirm);
  }

  [GtkCallback]
  private void ui_action_delete_button () {
    assert (this.old_key != null);
    Cawbird.snippet_manager.remove_snippet (this.old_key);
    modify_done(null, null, true);
#if OLD_HANDY
    save_geometry();
    this.destroy();
#endif
  }

#if OLD_HANDY
  private void load_geometry () {
    int x, y, width, height;
    window_settings.get ("window-size", "(ii)", out width, out height);
    this.resize (width, height);
  }

  private void save_geometry () {
    int x, y, width, height;
    this.get_size (out width, out height);
    window_settings.set ("window-size", "(ii)", width, height);
  }
#endif
}
