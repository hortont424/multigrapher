Multigrapher
============

License
-------

Multigrapher is licensed under the two-clause BSD license, which can be
found in full in License.md.

Introduction
------------

Imagine collecting data from all around your life and streaming it to one
central place, where it can be displayed with beauty and understood with
ease. Multigrapher provides both a beautiful Cocoa front-end for collecting
and displaying data from across your home network *and* a framework for
writing data servers in Python.

Servers
-------

Multigrapher can connect to any number of specially-crafted servers, each
of which can be running on any device on your local network.

Multigrapher only ships with example servers, which provide uninteresting
data. It's up to you (or others!) to create servers for data which will
pertain directly to your life.

Eventually, there will be a library of servers such that a non-programmer
can set up a useful instance of Multigrapher, but that is not the case
at the moment. Be patient, or learn Python!

If you have an existing application you'd like to use with Multigrapher
and don't want to use Python, it's very easy to publish a service. The
Multigrapher service specification can be found in Server.md.