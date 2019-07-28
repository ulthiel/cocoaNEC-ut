

## Changes

### Functionality
* Changed Cmd-O and Cmd-N keybord shortcuts from spreadhseet to NC models.
* Added xyz coordinate axis labels in geometry view (Output/Views/Geometry/GeometryView.m).
* Added keyboard arrow controls for geometry view (Output/Views/Geometry/GeometryView.m, Output/NECOutput.*).

### Internal
* Made it compile with XCode 10.
* Fixed a lot of errors and warnings about [ NSApp delegate ] by replacing this by (ApplicationDelegate*)[ NSApp delegate ].

