#!/bin/bash

source /etc/profile || failed 'Failed to update to valid source.';

emerge-webrsync || failed 'Failed installing portage snapshot.';

emerge --sync --quiet || failed 'Failed updating the portage tree.';

# Search for the gnome subprofile number
gnome_profile=$(eselect profile list | sed -n 's/\[\([0-9]*\)\].*\/desktop\/gnome/\1/p') || failed 'Failed displaying eselect list';
# Select that profile
eselect profile set $gnome_profile
