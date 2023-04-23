EDDN in Godot
=============

My first [Godot](https://godotengine.org/) experiment.

Connects to a [websocket server](https://eddn-realtime.space/) and
plots [EDDN](https://github.com/EDCD/EDDN) events in the galaxy.

Coding styles and spelling still WIP.

The server connection sometimes stops receiving events.
Press Backspace to reconnect.

Sprites and galaxy plane from the [Canonn Map](https://map.canonn.tech/)
([Github](https://github.com/canonn-science/CanonnED3D-Map)).
Websocket server code [here](https://github.com/HansAcker/EDDN-RealTime/tree/master/eddnws).

Camera movement with joystick axes or WASD/RF/QE/YC.
Home to get home. Del to remove all stars.

Press "1" to watch Robigo Runners, "3" to see Colonia, etc.
Press Ctrl + 0/1/2/3 to save a preset.

[![EDDN in Godot](https://img.youtube.com/vi/S_Mk0Nnx4aM/0.jpg)](https://www.youtube.com/watch?v=S_Mk0Nnx4aM "EDDN in Godot")


Performance TODO:
Adding thousands of sprites and labels to the scene is not the problem, the sprite texture transparency is.
