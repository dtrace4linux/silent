silent.pl - utility to stop processes when iconized
Usage: silent.pl [app1 app2]

  This tool was created to help reduce fan noise on an old laptop.
  Having apps like Firefox running, even when in the background,
  consumes CPU, generates heat, and makes the fan spin.

  Detecting if all the windows of the application are minimized, means
  we can send a SIGSTOP to the process, and drop CPU to zero. Hopefully
  even reducing thermals and fan noise.

  The script polls the listed applications, and sends a SIGSTOP if
  all the processes of the app are iconized, and sends SIGCONT, when
  any are uniconised.

  By default, the list of apps to check include firefox, chrome, bittorrent.
  But you can put the process names on the command line to customize.
  (The process names should be something that matches both "ps", and
  "xwininfo" output - typically the basename of the application is
  sufficient).

Example:

  Status is logged periodically, or when a process state changes.

  $ silent.pl
  silent.pl
  20201217 10:12:24 S firefox      hidden  12593 29700 29904 29948 29979 30023
  20201217 10:12:24 S torrent      hidden  5695
  20201217 10:12:28 R firefox      open    12593 29700 29904 29948 29979 30023
  20201217 10:12:37 S firefox      hidden  12593 29700 29904 29948 29979 30023

  Here we see "S" for "stopped" ("R" for running). The numbers after "hidden"
  are the PID's of the processes. (Firefox/chrome will use a number of
  process slots, to support the tabbed mode of operation - this tool will
  stop all of these).

Switches:

Author:

  paul.d.fox@gmail.com
  https://github.com/dtrace4linux/silent

