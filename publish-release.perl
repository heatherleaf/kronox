#!/usr/bin/perl

# Script for publishing a new release
# Very non-generic, will probably only work for me...

$user = 'peter.ljunglof@heatherleaf.se';
$plist = `pwd`;
chomp $plist;
$plist .= "/Info";
$key = "CFBundleVersion";

print "Current SVN status:\n";
system("svn status");
print "Are you sure you want to commit these changes? ";
$yes = <>;
die "Ok, try again next time" unless $yes =~ /^y(es)?$/i;

$current = `defaults read $plist $key`;
print "Current version number is: $current\n";
print "Which is the new version number? ";
$new = <>;
chomp $new;
die "Not a number, or less than $current" unless $new > $current;

print "New version number: $new\n";
print "Are you sure? ";
$yes = <>;
die "Ok, try again next time" unless $yes =~ /^y(es)?$/i;

print "Have you updated the ChangeLog.txt for version $new? ";
$yes = <>;
die "Ok, try again next time" unless $yes =~ /^y(es)?$/i;

print "\n--> Committing SVN for version $new\n";
system("defaults write $plist $key '$new'");
system("svn commit -m 'Release $new'");

print "\n--> Building the release\n";
system("xcodebuild -configuration Release") 
  ==0 or die "XCode building failed";

print "\n--> Creating DMG: build/KronoX-$new.dmg\n";
system("rm -r build/Release/KronoX.app.dSYM");
system("cp COPYING.txt build/Release/");
system("hdiutil create build/KronoX-$new.dmg " . 
       "-srcfolder build/Release -volname KronoX-$new")
  ==0 or die "Failed to create DMG";

print "\n--> Uploading DMG to Google code\n";
system("python googlecode_upload.py " .
       "--summary 'KronoX, version $new' " . 
       "--project kronox --user $user --labels Featured " .
       "build/KronoX-$new.dmg") 
  ==0 or die "Uploading failed";

print "\n--> Creating SVN tag kronox-$new\n";
system("svn cp . https://kronox.googlecode.com/svn/tags/kronox-$new " .
       "--username $user")
  ==0 or die "Failed to create SVN tag";



