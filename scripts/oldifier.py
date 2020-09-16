# oldifier.py
#
# Copyright 2020 Frederick Schenk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-or-later

# This scripts purpose is to modify the UI-Files for use with libhandy-0.0

from xml.etree.ElementTree import ElementTree
from shutil import copyfile
import sys, os.path, mimetypes

print("UI-Oldifier loaded!")
if len(sys.argv) < 4:
    print("ERROR: Not enough arguments given!")
    exit(1)

if len(sys.argv) > 4:
    print("ERROR: Too many arguments given!")
    exit(1)

infolder = sys.argv[1]
resources = sys.argv[2]
outfolder = sys.argv[3]

if not os.path.isdir(infolder):
    print("Input folder does not exist!")
    exit(2)

if not os.path.isfile(resources):
    print("Resource File does not exist!")
    exit(2)

allfiles = []
exportfolder = [outfolder]
iterfolder = [infolder]

print("Checking for UI-Files")
while(len(iterfolder) != 0):
    folder = iterfolder.pop(0)
    print(f"\tChecking {folder}")
    for data in os.listdir(folder):
        datapath = f"{folder}/{data}"
        if os.path.isdir(datapath):
            iterfolder.append(datapath)
            exportfolder.append(f"{outfolder}/{datapath}")
        if os.path.isfile(datapath):
            if datapath.endswith(".ui"):
                allfiles.append(datapath)

if len(allfiles) == 0:
    print("ERROR: No UI-Files found in Inputfolder!")
    exit(3)

for outdir in exportfolder:
    if not os.path.isdir(outdir):
        if os.path.isfile(outdir):
            print("ERROR: Output could not be initialized!")
            print("       Please clear the folder!")
            exit(4)
        os.makedirs(outdir)

print("Making changes")
for uifile in allfiles:
    print(f"\tParsing {uifile}")
    work = 0
    tree = ElementTree()
    tree.parse(uifile)
    root = tree.getroot()
    allnodes = root.iter()

    for uiobj in allnodes:
        if uiobj.tag == "object":
            # Add type="action" to childs of HdyActionRow
            if uiobj.attrib["class"] == "HdyActionRow":
                for uipart in list(uiobj):
                    if uipart.tag == "child":
                        if not "type" in uipart.attrib:
                            uipart.attrib["type"] = "action"
                            work += 1
        if uiobj.tag == "template":
            # Add type="action" to childs of HdyActionRow
            if uiobj.attrib["parent"] == "HdyActionRow":
                for uipart in list(uiobj):
                    if uipart.tag == "child":
                        if not "type" in uipart.attrib:
                            uipart.attrib["type"] = "action"
                            work += 1

    print(f"\t\t{work} Changes done!")
    tree.write(f"{outfolder}/{uifile}")

print("Update Resource File")

rsctree = ElementTree()
rsctree.parse(resources)
rscroot = rsctree.getroot()
rscnodes = rscroot.iter()

for node in rscnodes:
    if node.tag == "file":
        for uifile in allfiles:
            if node.text == uifile:
                node.attrib["alias"] = node.text
                node.text = f"{outfolder}/{node.text}"

rsctree.write(f"{outfolder}/{resources}")

print("Work is complete!")