Multigrapher Server Specification
=================================

Introduction
------------

Multigrapher servers are very simple, and consist of two parts: a Bonjour
service and a HTTP server.

HTTP Server
-----------

Multigrapher data is served over HTTP. The URL to the web server is either
entered via the Custom Source mechanism, or discovered via Bonjour.

The HTTP server should return a CSV file when a client GETs the root,
conforming to the following format:

* First row: **ShortName**,**LongName**,**SegmentType**,**Color**
* Subsequent rows: Data (format depends on SegmentType)

**ShortName** is displayed to the user in the source chooser.

**LongName** is displayed to the user in the main grid view.

**SegmentType** can be one of "graph" or "text", for a line graph or direct
textual representation, respectively. Other segment types will be
implemented in future versions.

**Color** is the color that the data should be presented in.
Acceptable choices are currently "red", "orange", "blue", or "green".
More color choices will be implemented in future versions.

Data
----

**SegmentType == "graph"**

Data can be in one of two formats:

    y1
    y2
    y3
    y4

or

    x1,y1
    x2,y2
    x3,y3
    x4,y4

If in the first format, data is assumed to be monotonic.

If a row contains only the string "--", a vertical bar is placed at that
location in the resulting graph.

**SegmentType == "text"**

Data is free-form. Text is currently drawn at 48pts, regardless of content.

Bonjour Service
---------------

The HTTP server is made discoverable via Bonjour, by broadcasting the
availability of a service of type "\_multigrapher.\_tcp", and the
hostname and port corresponding to the HTTP server itself.
