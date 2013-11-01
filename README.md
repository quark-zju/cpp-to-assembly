C/C++ to assembly visualizer
===============

C/C++ to assembly visualizer calls the command `gcc -c -Wa,-ahldn -g file.cpp`, then visualizes the interleaved C/C++ and assembly code on a fancy HTML web interface.

Check [original project](https://github.com/ynh/cpp-to-assembly).

Difference from original project
--------------------------------
This fork is intended to be used in a customized environment. 

1. Moved to a subdir `/c2asm`.
2. Compressed javascripts into one file. Same to CSS.
3. Changed various places to make it safer. For example, use [lrun](https://github.com/quark-zju/lrun) to limit memory usage.

Licence
-------
GPL 3 or later

http://gplv3.fsf.org/ 
