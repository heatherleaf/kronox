#!/usr/bin/env python
# Created By: Virgil Dupras
# Created On: 2009-12-30
# Copyright 2012 Hardcoded Software (http://www.hardcoded.net)
# 
# This file is part of KronoX.
#  
# KronoX is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# KronoX is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with KronoX.  If not, see <http://www.gnu.org/licenses/>.

# This script works with Python 2.6+ and Python 3

from __future__ import print_function

import os
import os.path as op
import tempfile
import plistlib
from optparse import OptionParser
from subprocess import Popen

def parse_args():
    usage = "usage: %prog [options]"
    parser = OptionParser(usage=usage)
    parser.add_option('--sign', dest='sign_identity',
        help="Sign app under specified identity before packaging (OS X only)")
    (options, args) = parser.parse_args()
    return options

# Taken from https://bitbucket.org/hsoft/hscommon/src/1fc26d329d42/build.py
def print_and_do(cmd):
    print(cmd)
    p = Popen(cmd, shell=True)
    p.wait()

def build_dmg(app_path, dest_path):
    print(repr(op.join(app_path, 'Contents', 'Info.plist')))
    plist = plistlib.readPlist(op.join(app_path, 'Contents', 'Info.plist'))
    workpath = tempfile.mkdtemp()
    dmgpath = op.join(workpath, plist['CFBundleName'])
    os.mkdir(dmgpath)
    print_and_do('cp -R "%s" "%s"' % (app_path, dmgpath))
    print_and_do('ln -s /Applications "%s"' % op.join(dmgpath, 'Applications'))
    dmgname = '%s_osx_%s.dmg' % (plist['CFBundleName'].lower().replace(' ', '_'), plist['CFBundleVersion'].replace('.', '_'))
    print('Building %s' % dmgname)
    # UDBZ = bzip compression. UDZO (zip compression) was used before, but it compresses much less.
    print_and_do('hdiutil create "%s" -format UDBZ -nocrossdev -srcdir "%s"' % (op.join(dest_path, dmgname), dmgpath))
    print('Build Complete')

def main():
    args = parse_args()
    app_path = 'KronoX.app'
    if args.sign_identity:
        sign_identity = "Developer ID Application: {0}".format(args.sign_identity)
        print_and_do('codesign --force --sign "{0}" "{1}"'.format(sign_identity, app_path))
    else:
        print("WARNING: packaging an unsigned application")
    build_dmg(app_path, '.')

if __name__ == '__main__':
    main()
