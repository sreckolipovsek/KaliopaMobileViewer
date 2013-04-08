Kaliopa Mobile Viewer for OSGeo Mapguide
========================================

Copyright (C) 2002-2013 by Kaliopa d.o.o. (www.kaliopa.si), Ljubljana, Slovenia.

Kaliopa Mobile Viewer is free software; you can redistribute it and/or
modify it under the terms of version 2.1 of the GNU Lesser
General Public License as published by the Free Software Foundation.

This part of code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Used libraries:
  - jQuery and jQuery UI
  - jQuery File Tree Plugin
  - OpenLayers 2.12
  - AjaxControlToolkit

Setup instructions:
  - Workrs with ASP.NET  
  - Put content to Mapguide Web Extension Folder ($\mapguide\Web\www\)  
  - Copy Mapguide .NET DLL-s (from $\mapguide\Web\www\mapviewernet\bin\) to $\KaliopaMobileViewer\bin\  
  - In IIS Create virtual directory and Convert it to Application  
  - Use it like mapviewerajax (call it with WEBLAYOUT Query String parameter)  
  
Functions:
  - Optimized for Mobile devices and works also in classic browsers
  - Functions:
    - Select on map by point, line, polygon
    - Measure
    - Intersct trought point
    - Mobile Layer Tree
    - Legend Image
    - Show report of selected objects
    - Go to Coordinate
    - ...

More info:
  http://gis.iobcina.si/gisapp/KaliopaMobileviewer

YouToube video:
  http://www.youtube.com/watch?v=8LvKkv-kq0U

Demo site:
  http://gis.iobcina.si/gisapp/m/Default.aspx?a=sheboygan

Full version:
  http://gis.iobcina.si/gisapp/m/Default.aspx?a=bled&locale=EN
