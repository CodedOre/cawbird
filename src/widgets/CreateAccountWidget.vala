/* CreateAccountWidget.vala
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

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/widget/create-account-widget.ui")]
#if OLD_HANDY
class CreateAccountWidget : Gtk.Window {
#else
class CreateAccountWidget : Gtk.Box {
#endif
  // UI-Elements of CreateAccountWidget
  [GtkChild]
  private Hdy.Carousel content_carousel;
  [GtkChild]
  private Gtk.Button header_cancel;
  [GtkChild]
  private Hdy.Clamp overview_page;
  [GtkChild]
  private Hdy.Clamp pin_page;
  [GtkChild]
  private Gtk.Revealer notification_revealer;
  [GtkChild]
  private Gtk.Label notification_label;

  // Non-UI-Elements of CreateAccountWidget
  private Account acc;
#if OLD_HANDY
  private GLib.Settings window_settings;
#endif

  // Signals of CreateAccountWidget
  public signal void widget_closed (Account? account = null);
  private signal void auth_progress ();

  public CreateAccountWidget () {
    this.acc = new Account (0, Account.DUMMY, "name");

  }

  [GtkCallback]
  private void ui_action_request_pin () {
    open_pin_request_site ();
    this.auth_progress.connect(() => {
      content_carousel.scroll_to(pin_page);
      header_cancel.set_label(_("Back"));
    });
  }

  [GtkCallback]
  private void ui_action_create_account () {
    string uri = "https://twitter.com/signup";
    try {
      GLib.AppInfo.launch_default_for_uri(uri, null);
    } catch (GLib.Error e) {
      reveal_notification (_("Could not open %s").printf ("<a href=\"" + uri + "\">" + uri + "</a>"));
      error("Could not call \"%s\" because of the following error: %s", uri, e.message);
    }
  }

  private void reveal_notification (string notification) {
    notification_label.set_label(_(notification));
    notification_revealer.set_reveal_child(true);
  }

  [GtkCallback]
  private void ui_action_notification_close () {
    notification_revealer.set_reveal_child(false);
  }

  [GtkCallback]
  private void ui_action_header_cancel () {
    if (content_carousel.get_position() == 1) {
      content_carousel.scroll_to(overview_page);
      header_cancel.set_label(_("Cancel"));
    } else {
      widget_closed();
#if OLD_HANDY
      save_geometry();
      this.destroy();
#endif
    }
  }

  private void pin_request_cb (Rest.OAuthProxy proxy, Error? error, Object? weak_object) {
    if (error != null) {
      reveal_notification(error.message);
      critical (error.message);
      return;
    }

    string uri = "http://twitter.com/oauth/authorize?oauth_token=" + acc.proxy.get_token();
    debug ("Trying to open %s", uri);

    try {
      GLib.AppInfo.launch_default_for_uri (uri, null);
    } catch (GLib.Error e) {
      reveal_notification (_("Could not open %s").printf ("<a href=\"" + uri + "\">" + uri + "</a>"));
      critical ("Could not open %s", uri);
      critical (e.message);
    }
    auth_progress();
  }

  public void open_pin_request_site () {
    acc.init_proxy (false, true);
    try {
      if (!acc.proxy.request_token_async ("oauth/request_token", "oob", pin_request_cb, this)) {
        reveal_notification(_("Failed to retrieve request token"));
      }
    } catch(GLib.Error e) {
      reveal_notification(e.message);
      critical (e.message);
    }
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
