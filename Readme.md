

## Changes

### Functionality
1. Changed Cmd-O and Cmd-N keybord shortcuts from spreadhseet to NC models.
1. Added xyz coordinate axis labels in geometry view (Output/Views/Geometry/GeometryView.m).
1. Added keyboard arrow controls for geometry view (Output/Views/Geometry/GeometryView.m, Output/NECOutput.*).

### Internal
1. Made it compile with XCode 10.
1. Fixed a lot of errors and warnings about [ NSApp delegate ] by replacing this by (ApplicationDelegate*)[ NSApp delegate ].

