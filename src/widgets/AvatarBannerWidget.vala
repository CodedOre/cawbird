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

[GtkTemplate (ui = "/uk/co/ibboard/cawbird/ui/widget/avatar-banner-widget.ui")]
class AvatarBannerWidget : Gtk.Bin {
  // UI-Elements of AvatarBannerWidget
  [GtkChild]
  private PixbufButton avatar_widget;
  [GtkChild]
  private PixbufButton banner_widget;

  public AvatarBannerWidget () {
  }

  public void set_account (Account account) {
  }
}
