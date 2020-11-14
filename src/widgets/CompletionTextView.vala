/*  This file is part of Cawbird, a Gtk+ linux Twitter client forked from Corebird.
 *  Copyright (C) 2013 Timm Bäder (Corebird)
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

class CompletionTextView : Gtk.TextView {
  private const string NO_SPELL_CHECK = "gtksourceview:context-classes:no-spell-check";
  private const string[] TEXT_TAGS = {
    "link",
    "mention",
    "hashtag",
    "snippet"
  };
  private Gtk.Window completion_window;
  private string? current_word = null;
  private GLib.Cancellable? completion_cancellable = null;

  private bool _default_listbox = true;
  public Gtk.ListBox completion_listbox {
    set {
      _default_listbox = false;
      Cb.Utils.unbind_non_gobject_model (completion_list, completion_model);
      completion_list.row_activated.disconnect(insert_user_completion);
      this.completion_list = value;
      Cb.Utils.bind_non_gobject_model (completion_list, completion_model, create_completion_row);
      completion_list.row_activated.connect(insert_user_completion);
    }
  }

  private Gtk.ListBox completion_list;
  private Cb.UserCompletionModel completion_model;

  public signal void show_completion ();
  public signal void hide_completion ();
  public signal void update_completion (string query);

  private unowned Account account;

  construct {
    completion_window = new Gtk.Window (Gtk.WindowType.POPUP);
    completion_window.set_type_hint (Gdk.WindowTypeHint.COMBO);
    completion_window.focus_out_event.connect (completion_window_focus_out_cb);
    completion_window.set_screen (this.get_screen ());

    completion_list = new Gtk.ListBox ();
    completion_model = new Cb.UserCompletionModel ();
    Cb.Utils.bind_non_gobject_model (completion_list, completion_model, create_completion_row);
    var placeholder_label = new Gtk.Label (_("No users found"));
    placeholder_label.get_style_context ().add_class ("dim-label");
    placeholder_label.show ();
    completion_list.set_placeholder (placeholder_label);

    var scroller = new Gtk.ScrolledWindow (null, null);
    scroller.add (completion_list);
    var frame = new Gtk.Frame (null);
    frame.add (scroller);
    completion_window.add (frame);

    this.focus_out_event.connect (completion_window_focus_out_cb);

    /* Your theme uses a wildcard for :link, right? */
    var style_context = this.get_style_context ();
    style_context.save ();
    style_context.set_state (Gtk.StateFlags.LINK);
    Gdk.RGBA link_color = style_context.get_color (style_context.get_state ());
    style_context.restore ();

    if (link_color.red ==   1.0 &&
        link_color.green == 1.0 &&
        link_color.blue ==  1.0 &&
        link_color.alpha == 1.0) {
      /* Unset, fall back to Adwaita's default */
      link_color = {
        0.16470,
        0.462735,
        0.77647,
        1.0
      };
    }

    Gdk.RGBA snippet_color = { 0.0, 0.65, 0.0627, 1.0};

    this.buffer.create_tag (TEXT_TAGS[0],
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag (TEXT_TAGS[1],
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag (TEXT_TAGS[2],
                            "foreground_rgba",
                            link_color, null);
    this.buffer.create_tag (TEXT_TAGS[3],
                            "foreground_rgba",
                            snippet_color, null);
    /* gspell marker */
    this.buffer.create_tag (NO_SPELL_CHECK, null);

    this.buffer.notify["cursor-position"].connect (update_completion_listbox);
    this.buffer.changed.connect (buffer_changed_cb);
    this.key_press_event.connect (key_press_event_cb);

    /* Set them here so they are consistent everywhere */
    this.right_margin  = 6;
    this.left_margin   = 6;
    this.top_margin    = 6;
    this.bottom_margin = 6;

#if SPELLCHECK
    var gspell_view = Gspell.TextView.get_from_gtk_text_view (this);
    gspell_view.set_inline_spell_checking (true);
    gspell_view.set_enable_language_menu (true);

    var gspell_buffer = Gspell.TextBuffer.get_from_gtk_text_buffer (this.buffer);
    var checker = new Gspell.Checker (Gspell.Language.get_default ());
    gspell_buffer.set_spell_checker (checker);
#endif
  }

  public void set_account (Account account) {
    this.account = account;
  }

  private bool insert_snippet () {
    Gtk.TextIter cursor_word_start;
    Gtk.TextIter cursor_word_end;
    string cursor_word = Utils.get_cursor_word (this.buffer, out cursor_word_start, out cursor_word_end);

    string? snippet = Cawbird.snippet_manager.get_snippet (cursor_word.strip ());

    if (snippet == null) {
      debug ("No snippet for cursor_word '%s' found.", cursor_word);
      return false;
    }

    Gtk.TextIter start_word_iter;

    this.buffer.freeze_notify ();
    this.buffer.delete_range (cursor_word_start, cursor_word_end);

    Gtk.TextMark cursor_mark = this.buffer.get_insert ();
    this.buffer.get_iter_at_mark (out start_word_iter, cursor_mark);

    this.buffer.insert_text (ref start_word_iter, snippet, snippet.length);
    this.buffer.thaw_notify ();

    return true;
  }

  private inline bool snippets_configured () {
    return Cawbird.snippet_manager.n_snippets () > 0;
  }

  private void select_completion_row (Gtk.ListBoxRow? row) {
    if (row == null)
      return;

    assert (row.get_parent () == completion_list);

    Gtk.Allocation alloc;
    row.get_allocation (out alloc);

    completion_list.select_row (row);

    Gtk.Viewport viewport = completion_list.get_parent () as Gtk.Viewport;

    if (viewport == null)
      return;

    Gtk.ScrolledWindow scroller = viewport.get_parent () as Gtk.ScrolledWindow;

    if (scroller != null) {
      Gtk.Adjustment adjustment = scroller.get_vadjustment ();

      adjustment.clamp_page (alloc.y, alloc.y + alloc.height);
    }
  }

  private bool key_press_event_cb (Gdk.EventKey evt) {

    if (evt.keyval == Gdk.Key.Tab && snippets_configured ()) {
      return insert_snippet ();
    }

    /* If we are not in 'completion mode' atm, just back out. */
    if (!completion_list.get_mapped ())
      return Gdk.EVENT_PROPAGATE;


    int n_results = (int)completion_model.get_n_items ();

    switch (evt.keyval) {
      case Gdk.Key.Down:
        if (n_results == 0)
          return Gdk.EVENT_PROPAGATE;

        var current_match = completion_list.get_selected_row().get_index();
        current_match = (current_match + 1) % n_results;
        var row = completion_list.get_row_at_index (current_match);
        if (_default_listbox) {
          row.grab_focus ();
        }
        select_completion_row (row);

        return Gdk.EVENT_STOP;

      case Gdk.Key.Up:
        var current_match = completion_list.get_selected_row().get_index();
        current_match --;
        if (current_match < 0) current_match = n_results - 1;
        var row = completion_list.get_row_at_index (current_match);
        if (_default_listbox) {
          row.grab_focus ();
        }
        select_completion_row (row);

        return Gdk.EVENT_STOP;

      case Gdk.Key.Return:
        if (n_results == 0)
          return Gdk.EVENT_PROPAGATE;
        insert_user_completion();
        return Gdk.EVENT_STOP;

      case Gdk.Key.Escape:
        hide_completion_window ();
        return Gdk.EVENT_STOP;

      default:
        return Gdk.EVENT_PROPAGATE;
    }
  }

  private void insert_user_completion () {
    var row = completion_list.get_selected_row();
    var list_had_focus = row.has_focus;
    assert (row is UserCompletionRow);
    string compl = ((UserCompletionRow)row).get_screen_name ();
    this.buffer.freeze_notify ();
    Gtk.TextIter start_word_iter;
    Gtk.TextIter end_word_iter;
    Utils.get_cursor_mention_word (this.buffer, out start_word_iter, out end_word_iter);
    var start_offset = start_word_iter.get_offset();
    this.buffer.delete_range (start_word_iter, end_word_iter);
    this.buffer.get_iter_at_offset(out start_word_iter, start_offset);
    var next_char = start_word_iter.get_char();

    if (next_char == 0 || !next_char.ispunct()) {
      this.buffer.insert_text (ref start_word_iter, compl + " ", compl.length + 1);
    }
    else {
      this.buffer.insert_text (ref start_word_iter, compl, compl.length);
    }
    this.buffer.thaw_notify ();
    hide_completion_window ();
    if (list_had_focus) {
      this.grab_focus();
    }
  }

  private void buffer_changed_cb () {
    Gtk.TextIter? start_iter;
    Gtk.TextIter? end_iter;
    this.buffer.get_start_iter (out start_iter);
    this.buffer.get_end_iter (out end_iter);
    var tag_table = this.buffer.get_tag_table ();

    /* We can't use gtk_text_buffer_remove_all_tags because that will also
       remove the ones added by gspell */
    for (int i = 0; i < TEXT_TAGS.length; i ++)
      this.buffer.remove_tag (tag_table.lookup (TEXT_TAGS[i]), start_iter, end_iter);

    string text = this.buffer.get_text (start_iter, end_iter, true);
    size_t text_length;
    var entities = Tl.extract_entities_and_text (text, out text_length);
    foreach  (unowned Tl.Entity e in entities) {
      Gtk.TextIter? e_start_iter;
      Gtk.TextIter? e_end_iter;

      this.buffer.get_iter_at_offset (out e_start_iter, (int)e.start_character_index);
      this.buffer.get_iter_at_offset (out e_end_iter, (int)(e.start_character_index + e.length_in_characters));

      switch (e.type) {
        case Tl.EntityType.HASHTAG:
          buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
          buffer.apply_tag_by_name ("hashtag", e_start_iter, e_end_iter);
          break;
        case Tl.EntityType.MENTION:
          buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
          buffer.apply_tag_by_name ("mention", e_start_iter, e_end_iter);
          break;
        case Tl.EntityType.LINK:
          buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
          buffer.apply_tag_by_name ("link", e_start_iter, e_end_iter);
          break;

        case Tl.EntityType.TEXT:
          if (Cawbird.snippet_manager.has_snippet_n (e.start, e.length_in_bytes)) {
            buffer.apply_tag_by_name (NO_SPELL_CHECK, e_start_iter, e_end_iter);
            buffer.apply_tag_by_name ("snippet", e_start_iter, e_end_iter);
          }
          break;

        default:
          break;
      }
    }

    if (buffer.text.length == 0)
      hide_completion_window ();
  }

  private void show_completion_window () {
    if (!this.get_mapped ())
      return;

    completion_model.clear ();

    if (!_default_listbox) {
      this.show_completion ();
      return;
    }

    int x, y;
    Gtk.Allocation alloc;
    this.get_allocation (out alloc);
    var window = this.get_window (Gtk.TextWindowType.WIDGET);
    window.get_origin (out x, out y);
    Gdk.Display default_display = Gdk.Display.get_default();
    Gdk.Monitor current_monitor = default_display.get_monitor_at_window(window);
    Gdk.Rectangle workarea = current_monitor.get_workarea();
    int completion_height = 100;

    // If it will fit below the text box then put it below, else put it above.
    // This stops the completion being shown off-screen.
    if (y + alloc.height + completion_height <= workarea.height) {
      y += alloc.height;
    }
    else {
      y -= completion_height;
    }

    /* +2 for the size and -1 for x since we account for the
       frame size around the text view */
    completion_window.set_attached_to (this);
    completion_window.set_transient_for ((Gtk.Window) this.get_toplevel ());
    completion_window.move (x - 1, y);
    completion_window.resize (alloc.width + 2, completion_height);
    completion_window.show_all ();
  }

  private void hide_completion_window () {
    this.current_word = null;

    if (!_default_listbox) {
      hide_completion ();
      return;
    }

    completion_window.hide ();
  }

  private bool completion_window_focus_out_cb () {
    if (_default_listbox) {
      hide_completion_window ();
    }

    return false;
  }


  private void update_completion_listbox () {
    string cur_word = Utils.get_cursor_mention_word (this.buffer, null, null);
    int n_chars = cur_word.char_count ();

    if (n_chars < 2 || cur_word[0] != '@'
        || this.buffer.has_selection) {
      hide_completion_window ();
      return;
    }

    // Strip off the @
    cur_word = cur_word.substring (1);

    if (cur_word != this.current_word) {
      if (this.completion_cancellable != null) {
        debug ("Cancelling earlier completion call...");
        this.completion_cancellable.cancel ();
      }

      /* Clears the model */
      show_completion_window ();

      /* Query users from local cache */
      Cb.UserInfo[] corpus;
      account.user_counter.query_by_prefix (account.db.get_sqlite_db (),
                                            cur_word, 10,
                                            out corpus);
      completion_model.insert_infos (corpus);

      bool corpus_was_empty = (corpus.length == 0);
      if (corpus.length > 0) {
        select_completion_row (completion_list.get_row_at_index (0));
      }
      corpus = null; /* Make sure we won't use it again */


      bool has_alnum = false;
      unichar c;
      for (int i = 0; cur_word.get_next_char (ref i, out c);) {
        if (c.isalnum()) {
          debug("Found alnum at %d: %s\n", i, c.to_string ());
          has_alnum = true;
          break;
        }
      }

      // Only query the API if there are alphanumeric characters, because Twitter won't search "@_"
      if (has_alnum) {
        /* Now also query users from the Twitter server, in case our local cache doesn't have anything
          worthwhile */
        this.completion_cancellable = new GLib.Cancellable ();
        var cur_word_query = "\"%s\"".printf(cur_word.replace("\\", "\\\\").replace("\"", "\\\""));
        Cb.Utils.query_users_async.begin (account.proxy, cur_word_query, completion_cancellable, (obj, res) => {
          Cb.UserIdentity[] users;
          try {
            users = Cb.Utils.query_users_async.end (res);
          } catch (GLib.Error e) {
            if (!(e is GLib.IOError.CANCELLED))
              warning ("User completion call error: %s", e.message);

            return;
          }

          completion_model.insert_items (users);
          if (users.length > 0 && corpus_was_empty) {
            select_completion_row (completion_list.get_row_at_index (0));
          }
        });
      }

      this.current_word = cur_word;

      completion_list.show_all ();
    }
  }

  private Gtk.Widget create_completion_row (void *id_ptr) {
    // *shrug*
    Cb.UserIdentity *id = (Cb.UserIdentity*) id_ptr;
    var row = new UserCompletionRow (id->id, id->user_name, id->screen_name, id->verified, id->protected_account);

    row.show ();
    return row;
  }

  ~CompletionTextView () {
    Cb.Utils.unbind_non_gobject_model (completion_list, completion_model);
  }
}

class UserCompletionRow : Gtk.ListBoxRow {
  private static Cairo.Surface verified_surface;
  private static Cairo.Surface protected_account_surface;
  private Gtk.Label user_name_label;
  private Gtk.Label screen_name_label;

  static construct {
    try {
      verified_surface = Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/uk/co/ibboard/cawbird/data/verified-small.png"),
          1, null);
      protected_account_surface = Gdk.cairo_surface_create_from_pixbuf (
          new Gdk.Pixbuf.from_resource ("/uk/co/ibboard/cawbird/data/protected-account-small.png"),
          1, null);
    } catch (GLib.Error e) {
      error (e.message);
    }
  }

  public UserCompletionRow (int64 id, string user_name, string screen_name, bool verified, bool protected_account) {
    user_name_label = new Gtk.Label (user_name);
    screen_name_label = new Gtk.Label ("@" + screen_name);

    this.activatable = true;

    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    user_name_label.set_valign (Gtk.Align.BASELINE);
    user_name_label.set_ellipsize (Pango.EllipsizeMode.END);
    box.add (user_name_label);
    screen_name_label.set_valign (Gtk.Align.BASELINE);
    screen_name_label.get_style_context ().add_class ("dim-label");
    box.add (screen_name_label);

    if (verified) {
      var verified_image= new Gtk.Image.from_surface (verified_surface);
      box.add (verified_image);
    }

    if (protected_account) {
      var protected_account_image = new Gtk.Image.from_surface (protected_account_surface);
      box.add (protected_account_image);
    }

    box.margin = 2;
    this.add (box);
    this.show_all ();
  }

  public string get_screen_name () {
    return screen_name_label.get_label ();
  }

}
