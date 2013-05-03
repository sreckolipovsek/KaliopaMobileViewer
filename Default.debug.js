// This part of code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
// Wrriten by Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
// srecko.lipovsek@kaliopa.si
// December 2012 

//global variables
var selection = new Selection();
var map;
var GPSWatch = null;
var GPSWatchTrack = false;
var GPStm;
var mgLayer;
var mgLayerSel;
var vector;
var vectorSel;
var selGeometry;
var mapInitComplete = false;
var toolbar;
var fgfText;
var maxR;
var selectInfo = false;
var shouldClearSearch = true;
var skipEvent = false;
var popup;
var dialogOpen = false;
var stopResize = false;
var loadingShown = false;

//Test
//GPSSet(false, true);
//GPSSet(true, true);
//GPSSet(false, false);
function GPSLocateMe() {
    vector.removeAllFeatures();
    ShowLoading();
    GPSSet(false, true);
}

function GPSSet(watch, on) {
    if (navigator.geolocation == null || navigator.geolocation.watchPosition == null) {
        alert(l_GPSError);
        return;
    }

    GPSWatchTrack = watch;

    if (on) {
        if (GPSWatch == null) {
            GPStm = new Date().getTime();
            GPSWatch = navigator.geolocation.watchPosition(GPSOk_highAccuracy, GPSError_highAccuracy, { maximumAge: 3000, timeout: 10000, enableHighAccuracy: true });
        }
    }
    else {
        GPSClearWatch();
    }
}

function GPSOk_highAccuracy(e) {
    if (!GPSWatchTrack) { //če je zahtevek po trenutni lokaciji ...	
        GPSClearWatch();
    }
    vector.removeAllFeatures();
    PageMethods.TransformWgs2GK(e.coords.latitude, e.coords.longitude, e.coords.accuracy, sessionId, mapName, OnSuccessTransformWgs2GK, OnFailTransformWgs2GK);
    HideLoading();
}

function GPSOk_lowAccuracy(e) {
    if (!GPSWatchTrack) {
        GPSClearWatch();
    }
    vector.removeAllFeatures();
    PageMethods.TransformWgs2GK(e.coords.latitude, e.coords.longitude, e.coords.accuracy, sessionId, mapName, OnSuccessTransformWgs2GK, OnFailTransformWgs2GK);
    HideLoading();
}

function GPSError_highAccuracy(err) {
    switch (err.code) {
        case err.PERMISSION_DENIED:
            HideLoading();
            GPSClearWatch();
            alert(l_GPSPerrmissionDenied);
            break;
        case err.POSITION_UNAVAILABLE:
            HideLoading();
            GPSClearWatch();
            alert(l_GPSNotAvailable);
            break;
        case err.TIMEOUT:
            GPSClearWatch();
            GPSWatch = navigator.geolocation.watchPosition(
				   GPSOk_lowAccuracy,
				   GPSError_lowAccuracy,
				   { maximumAge: 3000, timeout: 10000, enableHighAccuracy: false }); //poskusim še low acuracy ... lokacija na podlagi IP naslova
            break;
        case err.UNKNOWN_ERROR:
            HideLoading();
            GPSClearWatch();
            alert(l_GPSUnknown);
            break;
    }
}

function GPSError_lowAccuracy(err) {
    HideLoading();
    GPSClearWatch();
    switch (err.code) {
        case err.PERMISSION_DENIED:
            alert(l_GPSPerrmissionDenied);
            break;
        case err.POSITION_UNAVAILABLE:
            alert(l_GPSNotAvailable);
            break;
        case err.TIMEOUT:
            alert(l_GPSTimeout);
            break;
        case err.UNKNOWN_ERROR:
            alert(l_GPSUnknown);
            break;
    }
}

function GPSClearWatch() {
    if (GPSWatch != null) {
        navigator.geolocation.clearWatch(GPSWatch);
        GPSWatch = null;
    }
}

var style = {
    fillColor: '#000',
    fillOpacity: 0.1,
    strokeWidth: 0
};


var styles = new OpenLayers.StyleMap({
    "default": new OpenLayers.Style(null, {
        rules: [
			new OpenLayers.Rule({
			    symbolizer: {
			        "Point": {
			            pointRadius: 7,
			            graphicName: "square",
			            fillColor: "white",
			            fillOpacity: 0.25,
			            strokeWidth: 2,
			            strokeOpacity: 1,
			            strokeColor: "#3333aa"
			        },
			        "Line": {
			            strokeWidth: 3,
			            strokeOpacity: 1,
			            strokeColor: "#6666aa"
			        },
			        "Polygon": {
			            strokeWidth: 2,
			            strokeOpacity: 1,
			            fillColor: "#9999aa",
			            strokeColor: "#6666aa"
			        }
			    }
			})
		]
    }),
    "select": new OpenLayers.Style(null, {
        rules: [
			new OpenLayers.Rule({
			    symbolizer: {
			        "Point": {
			            pointRadius: 7,
			            graphicName: "square",
			            fillColor: "white",
			            fillOpacity: 0.25,
			            strokeWidth: 3,
			            strokeOpacity: 1,
			            strokeColor: "#0000ff"
			        },
			        "Line": {
			            strokeWidth: 3,
			            strokeOpacity: 1,
			            strokeColor: "#0000ff"
			        },
			        "Polygon": {
			            strokeWidth: 3,
			            strokeOpacity: 1,
			            fillColor: "#0000ff",
			            strokeColor: "#0000ff"
			        }
			    }
			})
		]
    }),
    "temporary": new OpenLayers.Style(null, {
        rules: [
			new OpenLayers.Rule({
			    symbolizer: {
			        "Point": {
			            graphicName: "square",
			            pointRadius: 7,
			            fillColor: "white",
			            fillOpacity: 0.25,
			            strokeWidth: 3,
			            strokeColor: "#0000ff"
			        },
			        "Line": {
			            strokeWidth: 3,
			            strokeOpacity: 1,
			            strokeColor: "#0000ff"
			        },
			        "Polygon": {
			            strokeWidth: 2,
			            strokeOpacity: 1,
			            strokeColor: "#0000ff",
			            fillColor: "#0000ff"
			        }
			    }
			})
		]
    })
});

function GotoView(x, y, s, a, b) {
    var cntL = new OpenLayers.LonLat(x, y);
    map.setCenter(cntL, 1);
    map.zoomToScale(s, true);
}

function ActivateControl(id) {
    //aktiviram izbiro točke
    toolbar.controls[id].activate();
    //ostale deaktiviram
    for (var i = 0; i < toolbar.controls.length; i++) {
        if (id != i) {
            toolbar.controls[i].deactivate();
        }
    }
}

(function ($) {
    $.fn.extend({
        center: function () {
            return this.each(function () {
                var top = ($(window).height() - $(this).outerHeight()) / 2;
                var left = ($(window).width() - $(this).outerWidth()) / 2;
                $(this).css({ position: 'absolute', zIndex: 2100, margin: 0, top: (top > 0 ? top : 0) + 'px', left: (left > 0 ? left : 0) + 'px' });
            });
        }
    });
})(jQuery);

$(document).ready(function () {
    //zamenjava sličic na tabih ob click ...
    $("#tabs").bind("tabsselect", function (event, ui) {
        $('#tabs ul li a').each(function (index) {
            if (this.children[0].src.indexOf("-selected.png") != -1)
                this.children[0].src = this.children[0].src.replace("-selected.png", ".png");
        });
        if (ui.tab.children[0].src.indexOf("-selected.png") == -1)
            ui.tab.children[0].src = ui.tab.children[0].src.replace(".png", "-selected.png");
    });

    var nPageH = $(window).height();
    $("#map").css('height', (nPageH - 75) + 'px');
    $("#home").css('height', (nPageH - 95) + 'px');
    $("#settings").css('height', (nPageH - 75) + 'px');
    $("#search").css('height', (nPageH - 75) + 'px');

    $("#tabs").tabs(
		{
		    select: function (e, ui) {
		        var thistab = ui.index;
		        if (thistab == 1 && !mapInitComplete) {
		            // Get hidden tabs content 
		            var $cache = $(".ui-tabs-hide");

		            // Make them visible 
		            $cache.removeClass("ui-tabs-hide");

		            mapInit();
		            mapInitComplete = true;

		            // Re-hide the tabs content 
		            $cache.addClass("ui-tabs-hide");

		        }
		    }
		}
	);
    $("#tabs").css('height', '100%');

    Resize();

    $('#btScale').click(function () {
        GoToScale();
    });

    //geolocation
    $('#locate').click(function () {
        checkMapInit();
        $('#tabs').tabs('select', 1);
        vector.removeAllFeatures();
        ShowLoading();
        GPSSet(false, true);
    });
    $('#track').click(function () {
        checkMapInit();
        $('#tabs').tabs('select', 1);
        vector.removeAllFeatures();
        //geolocate.deactivate();
        if (GPSWatch == null) {
            $('#track')[0].src = "images/sledi.png";
            ShowLoading();
            GPSSet(true, true);
        }
        else {
            $('#track')[0].src = "images/nesledi.png";
            HideLoading();
            GPSSet(false, false);
        }
    });
    //$('#track').attr('checked', false);

    //esc button, enter button
    $(document).keyup(function (e) {
        //clear
        if (e.keyCode == 27) {
            for (var i = 1; i < toolbar.controls.length; i++) { //pazi, od 1. naprej, ker je 0-ta navigacija !!!
                control = toolbar.controls[i];
                control.cancel();
            }
            ActivateControl(0);
            selectInfo = false;
            //clear selection
            ClearSelection();
        }
        //search ...
        if (e.keyCode == 13) {
            var curTab = $('.ui-tabs-selected').index();
            if (curTab == 3) {
                SearchMe();
            }
        }
    });

    //animate show
    $("#outer").show("slow", function () {
        if (initMapOnLoad) {
            checkMapInit();
            $('#tabs').tabs('select', 1);
        }
    });

    //erase content after first click ...
    $("#inputField").click(function () {
        if (shouldClearSearch) {
            $("#inputField").val("");
            $("#clearBtn").show("slow");
        }
        shouldClearSearch = false;
    });

    $("#inputField").change(function () {
        if ($("#inputField").val() == "") {
            $("#clearBtn").hide("slow");
        }
        else {
            $("#clearBtn").show("slow");
        }
    });

    //clear button
    $("#clearBtn").click(function () {
        $("#inputField").val("");
        $("#clearBtn").hide("slow");
    });

    $('.checkall').click(function () {
        $(this).parents('fieldset:eq(0)').find(':checkbox').attr('checked', this.checked);
    });

});

function checkMapInit() {
    if (!mapInitComplete) {
        // Get hidden tabs content 
        var $cache = $(".ui-tabs-hide");

        // Make them visible 
        $cache.removeClass("ui-tabs-hide");

        mapInit();
        mapInitComplete = true;

        // Re-hide the tabs content 
        $cache.addClass("ui-tabs-hide");
    }
}

function mapInit() {

    //map init

    //Adjust the scale assumptions for MapGuide layers
    //Tiled layers MUST use a DPI value of 96, untiled layers can use a 
    //different DPI value which will be passed to the server as a parameter.
    //Tiled and untiled layers must adjust the OL INCHES_PER_UNIT values
    //for any degree-based projections.

    // var metersPerUnit = 1; //value returned from mapguide
    var inPerUnit = OpenLayers.INCHES_PER_UNIT.m * metersPerUnit;
    OpenLayers.INCHES_PER_UNIT["dd"] = inPerUnit;
    OpenLayers.INCHES_PER_UNIT["degrees"] = inPerUnit;
    OpenLayers.DOTS_PER_INCH = DPI;

    var extent = new OpenLayers.Bounds(llX, llY, urX, urY);
    var centerLonLat = new OpenLayers.LonLat(cX, cY);

    var mapOptions;

    //global variable in default.aspx
    if (isMobile) {
        //mobile options
        mapOptions =
			    {
			        controls: [
                            //new OpenLayers.Control.LayerSwitcher({ roundedCornerColor: "#D71920" }),
                            new OpenLayers.Control.Scale(),
                            new OpenLayers.Control.TouchNavigation({
                                dragPanOptions: {
                                    enableKinetic: true
                                }
                            }),
			        //new OpenLayers.Control.Permalink({anchor: true}),
							new OpenLayers.Control.Zoom({
							    zoomInId: "customZoomIn",
							    zoomOutId: "customZoomOut"
							})

			        //,
			        //new OpenLayers.Control.OverviewMap()
					     ],
			        units: unitsType,
			        maxResolution: "auto",
			        //minResolution: 0.5,
			        maxExtent: extent,
			        theme: null,
			        panRatio: 1.1
			    }
    }
    else {
        //clasic options ...
        mapOptions =
			    {
			        controls: [
                            //new OpenLayers.Control.LayerSwitcher({ roundedCornerColor: "#D71920" }),
                            new OpenLayers.Control.Scale(),
                            new OpenLayers.Control.Navigation({
                                dragPanOptions: {
                                    enableKinetic: true
                                }
                            }),
			        //new OpenLayers.Control.Permalink({anchor: true}),
                            new OpenLayers.Control.Zoom({
                                zoomInId: "customZoomIn",
                                zoomOutId: "customZoomOut"
                            }),
			        //new OpenLayers.Control.PanPanel(),
			        // new OpenLayers.Control.ZoomBox(),
                            new OpenLayers.Control.KeyboardDefaults()//,
			        //new OpenLayers.Control.OverviewMap()
					     ],
			        units: unitsType,
			        maxResolution: "auto",
			        //minResolution: 0.5,
			        maxExtent: extent,
			        theme: null,
			        panRatio: 1.1
			    }
    }

    map = new OpenLayers.Map('map', mapOptions);
    map.updateSize();

    //wms rasters
    initWms();
    for (var i = 0; i < wmsLayArr1.length; i++) {
        map.addLayer(wmsLayArr1[i]);
    }

    var options = {
        isBaseLayer: (wmsLayArr1.length > 0 ? false : true),
        useOverlay: true,
        useAsyncOverlay: true,
        buffer: 0,
        singleTile: true,
        units: unitsType,
        transitionEffect: 'resize',
        ratio: 1.1
    };

    var optionsSel = {
        isBaseLayer: false,
        useOverlay: true,
        useAsyncOverlay: true,
        buffer: 0,
        singleTile: true,
        units: unitsType,
        transitionEffect: 'resize',
        ratio: 1.1
    };

    var params = {
        mapName: mapName,
        session: sessionId,
        selectioncolor: selectionColor,
        behavior: 2,
        locale: locale,
        version: "2.1.0",
        CLIENTAGENT: clientAgent,
        format: 'PNG',
        showGroups: '',
        hideGroups: '',
        showLayers: '',
        hideLayers: ''
    };

    var params_selection = {
        mapName: mapName,
        session: sessionId,
        SELECTIONCOLOR: selectionColor,
        behavior: 5,
        locale: locale,
        version: "2.1.0",
        CLIENTAGENT: clientAgent,
        format: 'PNG'
    };

    //mapguide map image
    mgLayer = new OpenLayers.Layer.MapGuide(appDesc, webAgent, params, options);

    //loading indicator
    // mgLayer.events.register("loadstart", mgLayer, function () {
    // $("#mapLoading").center();
    // $("#mapLoading").slideToggle("slow");
    // });

    // mgLayer.events.register("loadend", mgLayer, function () {
    // $("#mapLoading").slideToggle("slow");
    // });

    map.addLayer(mgLayer);

    //mapguide selection overlay
    mgLayerSel = new OpenLayers.Layer.MapGuide(appDesc + l_mgSelLayerName, webAgent, params_selection, optionsSel);
    map.addLayer(mgLayerSel);

    //geolocation
    vector = new OpenLayers.Layer.Vector(l_geolocation);
    map.addLayer(vector);

    // create a vector layer for drawing
    vectorSel = new OpenLayers.Layer.Vector(l_selectionLName, {
        styleMap: new OpenLayers.StyleMap({
            temporary: OpenLayers.Util.applyDefaults({
                pointRadius: 7
            }, OpenLayers.Feature.Vector.style.temporary)
        })
    });

    vectorSel.events.on({
        beforefeatureadded: function (event) {
            selGeometry = event.feature.geometry;
            if (!selectInfo) {
                if (selGeometry.CLASS_NAME == "OpenLayers.Geometry.Polygon") {
                    RequestPolygonSelection(selGeometry);
                }
                else if (selGeometry.CLASS_NAME == "OpenLayers.Geometry.LineString") {
                    RequestLineSelection(selGeometry);
                }
                else if (selGeometry.CLASS_NAME == "OpenLayers.Geometry.Point") {
                    RequestPointSelection(selGeometry.x - map.resolution * 4, selGeometry.y - map.resolution * 4, selGeometry.x + map.resolution * 4, selGeometry.y + map.resolution * 4);
                }
            }
            else { //intersect trought point ...
                var infoGeomWkt = MakeWktPolygon(selGeometry.x - map.resolution * 4, selGeometry.y - map.resolution * 4, selGeometry.x + map.resolution * 4, selGeometry.y + map.resolution * 4);

                var pageUrl = IntersectPageUrl;

                var paramss = new Array(
			        "SESSION", sessionId,
			        "MAPNAME", mapName,
			        "a", appName,
			        "GEOMETRY", infoGeomWkt,
                    "tp", 1,
                    "SELECTIONVARIANT", "INTERSECTS",
                    "CLIENTAGENT", encodeURIComponent(clientAgent),
			        "LOCALE", locale,
			        "SEQ", Math.random());

                document.getElementById("infoHolder").innerHTML = "";
                $('#infoHolder').append('<iframe id="infoframe" name="infoframe" src="" height="100%" width="100%" allowtransparency="true" frameborder="no" scrolling="auto"></iframe>');
                $('#infoHolder').dialog({ title: l_tockaInfo, modal: false, width: (350), height: (600), position: ['right', 60], zIndex: 2100 });
                Submit(pageUrl, paramss, "infoframe");

                vectorSel.removeAllFeatures();
                ActivateControl(0);
                selectInfo = false;
            }
        }
    });

    map.addLayer(vectorSel);

    // style the sketch fancy
    var sketchSymbolizers = {
        "Point": {
            pointRadius: 4,
            graphicName: "square",
            fillColor: "white",
            fillOpacity: 1,
            strokeWidth: 1,
            strokeOpacity: 1,
            strokeColor: "#333333"
        },
        "Line": {
            strokeWidth: 3,
            strokeOpacity: 1,
            strokeColor: "Red",
            strokeDashstyle: "dash"
        },
        "Polygon": {
            strokeWidth: 2,
            strokeOpacity: 1,
            strokeColor: "Red",
            fillColor: "white",
            fillOpacity: 0.3
        }
    };
    var styleM = new OpenLayers.Style();
    styleM.addRules([
                new OpenLayers.Rule({ symbolizer: sketchSymbolizers })
            ]);
    var styleMap = new OpenLayers.StyleMap({ "default": styleM });

    // OpenLayers' EditingToolbar internally creates a Navigation control, we
    // want a TouchNavigation control here so we create our own editing toolbar
    toolbar = new OpenLayers.Control.Panel({
        displayClass: 'myolControlEditingToolbar'
    });

    toolbar.addControls([
                 new OpenLayers.Control({
                     displayClass: 'myolControlNavigation'
                 }),
                 new OpenLayers.Control.DrawFeature(vectorSel, OpenLayers.Handler.Point, {
                     displayClass: 'myolControlDrawFeaturePoint'
                 }),
                 new OpenLayers.Control.DrawFeature(vectorSel, OpenLayers.Handler.Path, {
                     displayClass: 'myolControlDrawFeatureLine'
                 }),
                 new OpenLayers.Control.DrawFeature(vectorSel, OpenLayers.Handler.Polygon, {
                     displayClass: 'myolControlDrawFeaturePolygon'
                 }),
    //tale mora biti vsaj na 4. mestu, ker jo koda naprej kliče po id-ju ...
                 new OpenLayers.Control.Measure(
                    OpenLayers.Handler.Path, {
                        persist: true,
                        displayClass: 'myolControlMeasureLine',
                        handlerOptions: {
                            layerOptions: { styleMap: styleMap }
                        }
                    }
                ),
                new OpenLayers.Control.Measure(
                    OpenLayers.Handler.Polygon, {
                        persist: true,
                        displayClass: 'myolControlMeasurePolygon',
                        handlerOptions: {
                            layerOptions: { styleMap: styleMap }
                        }
                    }
                )
                ]);

    map.addControl(toolbar);

    var toolbar2 = new OpenLayers.Control.Panel({
        displayClass: 'myolControlEditingToolbar2'
    });

    var button2 = new OpenLayers.Control.Button({ displayClass: 'olControlButton2', trigger: MakeLegend, title: l_vsebineOnOff });
    var button3 = new OpenLayers.Control.Button({ displayClass: 'olControlButton3', trigger: PrintLegend1, title: l_legenda });
    var button4 = new OpenLayers.Control.Button({ displayClass: 'olControlButton4', trigger: GPSLocateMe, title: l_GPSTitle });

    toolbar2.addControls([button2, button3, button4]);
    map.addControl(toolbar2);
    toolbar.controls[0].activate();

    var control;
    for (var i = 4; i < toolbar.controls.length; i++) { //pazi, od 4. naprej !!!
        control = toolbar.controls[i];
        control.setImmediate(true);
        control.events.on({
            "measure": handleMeasurements,
            "measurepartial": handleMeasurementsPartial
        });
        //map.addControl(control);
    }

    //measure       
    map.events.on({
        "zoomend": handleMapZoomEnd
    });

    map.setCenter(centerLonLat, 1);
    map.zoomToExtent(extent);


    map.addControl(new OpenLayers.Control.Permalink({ anchor: true }));
    //map init
}

function handleMapZoomEnd(event) {
    $('#merilo').val(parseFloat(map.getScale()).toFixed(0));
}

function handleMeasurements(event) {
    handleMeasurementsGP(event, false);
}

function handleMeasurementsPartial(event) {
    handleMeasurementsGP(event, true);
}

function handleMeasurementsGP(event, partial) {
    var geometry = event.geometry;
    var units = event.units;
    var order = event.order;
    var measure = event.measure;

    var out = "";
    if (order == 1) {
        out += l_measurerazdalja + measure.toFixed(3) + " " + units;
    } else {
        out += l_measurepovrsina + measure.toFixed(3) + " " + units + "2";
    }

    if (!partial) {
        alert(out);
    }
}

//window.onresize = Resize;
function Resize() {
    if (navigator.userAgent.match(/Android/i)) {
        window.scrollTo(0, 0); // reset in case prev not scrolled  
        var nPageH = $(document).height();
        $("#map").css('height', (nPageH - 10) + 'px');
        $("#home").css('height', (nPageH - 10) + 'px');
        $("#settings").css('height', (nPageH - 10) + 'px');
        $("#search").css('height', (nPageH - 10) + 'px');

        var nViewH = window.outerHeight;
        if (nViewH > nPageH) {
            nViewH = nViewH / window.devicePixelRatio;
            $('BODY').css('height', nViewH + 'px');
            $("#map").css('height', (nViewH - 10) + 'px');

        }
        window.scrollTo(0, 1);
        if (mapInitComplete) {
            map.updateSize();
        }
    }
    else {
        var nPageH = $(window).height();
        $("#map").css('height', (nPageH - 75) + 'px');
        $("#home").css('height', (nPageH - 95) + 'px');
        $("#settings").css('height', (nPageH - 75) + 'px');
        $("#search").css('height', (nPageH - 75) + 'px');
        if (mapInitComplete) {
            map.updateSize();
        }
    }
    //            if($.browser.msie | $.browser.mozilla){
    //                var nPageH = $(document).height();
    //                $('#map').css('height', (nPageH - 100) + 'px');
    //                map.updateSize();
    //            }

    // Get rid of address bar on iphone/ipod
    //            if (!(/(iphone|ipod)/.test(navigator.userAgent.toLowerCase()))) {
    //                window.scrollTo(0,0);
    //                document.body.style.height = '100%';
    //                if (document.body.parentNode) {
    //                    document.body.parentNode.style.height = '100%';
    //                }
    //                map.updateSize();
    //            }
}

function MakeLegend() {
    checkMapInit();
    $('#tabs').tabs('select', 1);
    $('#layerBrowser').layerTree({ mgSessionId: sessionId, mgMapName: mapName, script: LayerTreeConnectorUrl }, function (file) {
    });
    $('#layerBrowserHolder').dialog({ title: l_vsebineOnOff, modal: false, autoResize: true, position: ['right', 60], zIndex: 2100 });
}

function ChangeVisibility(nodeType, objectId) {
    var shG = "";
    var chk = "#Chk_" + objectId;
    var src = $(chk).attr("src");
    var show = false;
    if (src.indexOf('lc_unchecked') != -1) {
        show = true;
    }
    if (!show) {
        src = src.replace("lc_checked", "lc_unchecked");
    }
    else {
        src = src.replace("lc_unchecked", "lc_checked");
    }
    $(chk).attr("src", src);

    //reset
    mgLayer.params.showGroups = '';
    mgLayer.params.hideGroups = '';
    mgLayer.params.showLayers = '';
    mgLayer.params.hideLayers = '';

    if (nodeType == 1) {
        if (show) {
            mgLayer.params.showGroups = objectId;
        }
        else {
            mgLayer.params.hideGroups = objectId;
        }
    }
    if (nodeType == 0) {
        if (show) {
            mgLayer.params.showLayers = objectId;
        }
        else {
            mgLayer.params.hideLayers = objectId;
        }
    }

    mgLayer.redraw(true);
    return false;
}

function ShowLoading() {
    if (!loadingShown) {
        $("#mapLoading").center();
        $("#mapLoading").slideToggle("slow");
    }
    loadingShown = true;
}

function HideLoading() {
    if (loadingShown) {
        $("#mapLoading").slideToggle("slow");
    }
    loadingShown = false;
}
//all visible layers
function PrintLegend1() {
    checkMapInit();
    $('#tabs').tabs('select', 1);
    var pageUrl = PrintLegendUrl + "?SESSION=" + sessionId + "&MAPNAME=" + mapName + "&LOCALE=" + locale + "&SEQ=" + Math.random();
    document.getElementById("legendHolder").innerHTML = "";
    $('#legendHolder').append('<img src="' + pageUrl + '" />');
    $('#legendHolder').dialog({ title: l_legenda, modal: false, autoResize: true, position: ['right', 60], zIndex: 2100 });
}

var pulsate = function (feature) {
    var point = feature.geometry.getCentroid(),
                bounds = feature.geometry.getBounds(),
                radius = Math.abs((bounds.right - bounds.left) / 2),
                count = 0,
                grow = 'up';

    var resize = function () {
        if (count > 16) {
            clearInterval(window.resizeInterval);
        }
        var interval = radius * 0.03;
        var ratio = interval / radius;
        switch (count) {
            case 4:
            case 12:
                grow = 'down'; break;
            case 8:
                grow = 'up'; break;
        }
        if (grow !== 'up') {
            ratio = -Math.abs(ratio);
        }
        feature.geometry.resize(1 + ratio, point);
        vector.drawFeature(feature);
        count++;
    };
    window.resizeInterval = window.setInterval(resize, 50, point, radius);
};

function OnChangeTransformWgs2GK(result) {

    var spl = result.split(';');

    var circle = new OpenLayers.Feature.Vector(
                OpenLayers.Geometry.Polygon.createRegularPolygon(
                    new OpenLayers.Geometry.Point(spl[0], spl[1]),
                    spl[2] / 2,
                    40,
                    0
                ),
                {},
                style
            );
    vector.addFeatures([
                new OpenLayers.Feature.Vector(
                    new OpenLayers.Geometry.Point(spl[0], spl[1]),
                    {},
                    {
                        graphicName: 'cross',
                        strokeColor: '#f00',
                        strokeWidth: 2,
                        fillOpacity: 0,
                        pointRadius: 10
                    }
                ),
                circle
            ]);

    if (firstGeolocation) {
        map.zoomToExtent(vector.getDataExtent());
        pulsate(circle);
        firstGeolocation = false;
        this.bind = true;
    }
}

function MakeWktPolygon(x1, y1, x2, y2) {
    return "POLYGON((" + x1 + " " + y1 + ", " + x2 + " " + y1 + ", " + x2 + " " + y2 + ", " + x1 + " " + y2 + ", " + x1 + " " + y1 + "))";
}

function RequestPointSelection(x1, y1, x2, y2) {
    fgfText = MakeWktPolygon(x1, y1, x2, y2);
    maxR = 1;
    SetSelection2(false);
}

function RequestPolygonSelection(geome) {
    fgfText = "POLYGON((";
    for (var i = 0; i < geome.getVertices().length; i++) {
        if (i > 0)
            fgfText += ", ";
        fgfText += geome.getVertices()[i].x + " " + geome.getVertices()[i].y + " ";
    }
    fgfText += ", ";
    fgfText += geome.getVertices()[0].x + " " + geome.getVertices()[0].y + " ";
    fgfText += "))";
    maxR = 0;
    SetSelection2(true);
}

function RequestLineSelection(geome) {
    fgfText = "LINESTRING (";
    for (var i = 0; i < geome.getVertices().length; i++) {
        if (i > 0)
            fgfText += ", ";
        fgfText += geome.getVertices()[i].x + " " + geome.getVertices()[i].y;
    }
    fgfText += ")";
    maxR = 0;
    SetSelection2(true);
}

function QueryFeatureInfo(geom, visl, maxfeatures) {
    if (visl == "") return;
    var reqParams = "OPERATION=QUERYMAPFEATURES&VERSION=1.0.0&PERSIST=1&MAPNAME=" + encodeURIComponent(mapName) + "&SESSION=" + sessionId + "&SEQ=" + Math.random();
    reqParams += "&LAYERNAMES=" + encodeURIComponent(visl) + "&GEOMETRY=" + geom + "&SELECTIONVARIANT=INTERSECTS" + "&CLIENTAGENT=" + encodeURIComponent(clientAgent);
    if (maxfeatures != 0) {
        reqParams += "&MAXFEATURES=" + maxfeatures;
    }
    var selRequest = GetRequestHandler();
    selRequest.open("POST", webAgent, false);
    selRequest.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    selRequest.send(reqParams);

    if (selRequest.status == 200 && selRequest.responseXML) {
        ProcessFeatureInfo(selRequest.responseXML.documentElement, maxfeatures);
    }
    vectorSel.removeAllFeatures();
    vectorSel.redraw(true);
    mgLayerSel.redraw(true);
}

function ProcessFeatureInfo(xmlIn, maxfeatures) {
    selection = new Selection();
    var props = xmlIn.getElementsByTagName("Property");
    var ttipElt = xmlIn.getElementsByTagName("Tooltip")[0];

    var layers = xmlIn.getElementsByTagName("Layer");
    for (var i = 0; i < layers.length; i++) {
        var layerId = layers[i].getAttribute("id");

        var classElt = layers[i].getElementsByTagName("Class")[0];
        var className = classElt.getAttribute("id");

        var newLayer = new SelLayer(className);
        selection.layers.setItem(layerId, newLayer);

        var features = classElt.getElementsByTagName("ID");
        for (var j = 0; j < features.length; j++) {
            var id = features[j].childNodes[0].nodeValue;
            newLayer.featIds.setItem(id, newLayer);
            selection.count++;
        }

        if (newLayer.featIds.length == 0)
            selection.layers.removeItem(layerId);
    }

    var outHtml = "<table>";
    if (maxfeatures == 1) {
        if (ttipElt != null && ttipElt.childNodes.length > 0) {
            var ttinfo = ttipElt.childNodes[0].nodeValue;
            ttinfo = ttinfo.replace(/\\n/g, "<br>&nbsp;");
            outHtml += '<tr><td class="smallFont" colspan="2">' + ttinfo + '</td></tr>';
        }
        else if (props != null && props.length > 0) {
            for (var i = 0; i < props.length; i++) {
                var name = props[i].getAttribute("name");
                var value = props[i].getAttribute("value");
                outHtml += '<tr><td class="smallFont">' + name + '</td><td class="smallFont">' + value + '</td></tr>';
                if (i > 5) break;
            }
        }
    }

    outHtml += '<tr><td class="smallFont" colspan="2">';
    outHtml += '<b><a style="font-size:8pt;" id="mgshow" href=\"javascript:MultiGridShow();\"><img style="border:0" src="images/mActionOpenTable.png"/>' + l_izpis + '</a></b><br/>';
    outHtml += '<b><a style="font-size:8pt;" id="mggosel" href=\"javascript:ZoomSelection();\"><img style="border:0" src="images/mActionZoomToSelected.png"/>' + l_pojdi + '</a></b>';

    outHtml += '</td></tr>';
    outHtml += "</table>";

    try {
        if (selGeometry) {
            if (!dialogOpen) {
                var feature = selGeometry;
                if (popup) {
                    popup.hide();
                    selGeometry = null;
                }
                popup = new OpenLayers.Popup.FramedCloud("chicken",
                                        feature.getBounds().getCenterLonLat(),
                                        new OpenLayers.Size(10, 10),
                                        outHtml,
                                        null, true, onPopupClose
                        );

                feature.popup = popup;
                map.addPopup(popup);
            }
            else {
                if (popup) {
                    popup.hide();
                    selGeometry = null;
                }
                var paramss = new Array(
                                "Session", sessionId,
                                "mapName", mapName,
                                "a", appName,
						        "selection", selectionToXml(),
						        "WEBLAYOUT", webLayout,
						        "LOCALE", locale,
						        "SEQ", Math.random());
                var pageUrl = ReportUrl;
                Submit(pageUrl, paramss, "outputframe");
            }
        }
    }
    catch (e) { }
}

function GoToCoordinateCommand() {
    checkMapInit();
    $('#tabs').tabs('select', 1);
    $("#winGotToX").val(map.getCenter().lon.toFixed(2));
    $("#winGotToY").val(map.getCenter().lat.toFixed(2));
    $("#goToCoordinateHolder").tabs();
    $('#goToCoordinateHolderDialog').dialog({ title: l_goToCoordinate, modal: false, autoResize: true, position: ['right', 60], zIndex: 2100 });
    PageMethods.TransformGK2Wgs(map.getCenter().lon, map.getCenter().lat, sessionId, mapName, OnSuccesssTransformGK2WgsCoord, onFailTransformGK2WgsCoord);
}

function formatDecimal(dc) {
    var separator = CurrentDecimalSeparator;
    return dc.toString().replace('.', separator);
}

function OnSuccesssTransformGK2WgsCoord(result) {
    var spl = result.split(';');
    $("#winGotToLat").val((spl[1] * 1).toFixed(6));
    $("#winGotToLon").val((spl[0] * 1).toFixed(6));
}

function onFailTransformGK2WgsCoord(e) {
    alert(e._message);
}

function PointInfoCommand() {
    checkMapInit();
    $('#tabs').tabs('select', 1);
    ActivateControl(1);
    alert(l_DrawPoint);
    selectInfo = true;
}

function GoTo() {
    if (!IsNumeric(document.getElementById("winGotToX").value)) {
        alert("!");
        document.getElementById("winGotToX").value = "";
        document.getElementById("winGotToX").focus;
        return;
    }

    if (!IsNumeric(document.getElementById("winGotToY").value)) {
        alert("!");
        document.getElementById("winGotToY").value = "";
        document.getElementById("winGotToY").focus;
        return;
    }

    var x = stringToDouble(document.getElementById("winGotToX").value);
    var y = stringToDouble(document.getElementById("winGotToY").value);

    ShowLocation(x, y, 200);
}

function IsNumeric(sText) {
    var ValidChars = "0123456789.";
    var IsNumber = true;
    var Char;

    if (sText.length == 0) return false;

    for (i = 0; i < sText.length && IsNumber == true; i++) {
        Char = sText.charAt(i);
        if (ValidChars.indexOf(Char) == -1) {
            sNumber = false;
        }
    }
    return IsNumber;
}

function stringToDouble(str) {
    return str.replace(/,/g, '.') * 1;
}

function GoToLatLon() {
    if (!IsNumeric(document.getElementById("winGotToLat").value)) {
        alert("!");
        document.getElementById("winGotToLat").value = "";
        document.getElementById("winGotToLat").focus;
        return;
    }

    if (!IsNumeric(document.getElementById("winGotToLon").value)) {
        alert("!");
        document.getElementById("winGotToLon").value = "";
        document.getElementById("winGotToLon").focus;
        return;
    }

    var lat = stringToDouble(document.getElementById("winGotToLat").value);
    var lon = stringToDouble(document.getElementById("winGotToLon").value);

    PageMethods.TransformWgs2GK(lat, lon, 200, sessionId, mapName, OnSuccessTransformWgs2GK, OnFailTransformWgs2GK);
}

function OnSuccessTransformWgs2GK(result) {
    var spl = result.split(';');
    var x = spl[0] * 1;
    var y = spl[1] * 1;
    var acc = spl[2] * 1;
    ShowLocation(x, y, acc);
}

function ShowLocation(x, y, accuracy) {

    if (x < llX) {
        alert(l_LocationOutside);
        return;
    }

    if (x > urX) {
        alert(l_LocationOutside);
        return;
    }

    if (y < llY) {
        alert(l_LocationOutside);
        return;
    }

    if (y > urY) {
        alert(l_LocationOutside);
        return;
    }

    vector.removeAllFeatures();
    var circle = new OpenLayers.Feature.Vector(
                OpenLayers.Geometry.Polygon.createRegularPolygon(
                    new OpenLayers.Geometry.Point(x, y),
                    accuracy / 2,
                    40,
                    0
                ),
                {},
                style
            );
    vector.addFeatures([
                new OpenLayers.Feature.Vector(
                    new OpenLayers.Geometry.Point(x, y),
                    {},
                    {
                        graphicName: 'cross',
                        strokeColor: '#f00',
                        strokeWidth: 2,
                        fillOpacity: 0,
                        pointRadius: 10
                    }
                ),
                circle
            ]);
    var mb = map.getExtent();
    var vb = vector.getDataExtent();
    var mw = mb.getWidth();
    var vw = vb.getWidth();

    var zm = false;
    //če se bound lokacije ne seka z boundom trenutnega pogleda ...
    if (!mb.intersectsBounds(vb)) {
        if (vw < 30) {
            vb = vb.scale(3);
        }
        map.zoomToExtent(vb);
        zm = true;
    }

    if (!zm) {
        //če je razmerje širine bounda lokacije z boundom pogleda večje kot 20, potem je zoom na lokacijo ...
        if (mw / vw > 20) {
            if (vw < 30) {
                vb = vb.scale(3);
            }
            map.zoomToExtent(vb);
            zm = true;
        }
    }

    //če center lokacije leži izven trenutnega pogleda ...
    if (!zm) {
        if (!mb.containsLonLat(vb.getCenterLonLat())) {
            if (vw < 30) {
                vb = vb.scale(3);
            }
            map.zoomToExtent(vb);
            zm = true;
        }
    }

    pulsate(circle);
}

function OnFailTransformWgs2GK(e) {
    alert(e._message);
}

function SetSelectionXML(xmlSet) {
    xmlOut = SetSelection(xmlSet, true);
    mgLayerSel.redraw(true);
    if (window.DOMParser) {
        parser = new DOMParser();
        xmlDoc = parser.parseFromString(xmlSet, "text/xml");
    }
    else // Internet Explorer
    {
        xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
        xmlDoc.async = false;
        xmlDoc.loadXML(xmlSet);
    }
    ProcessFeatureInfo(xmlDoc.documentElement, 0);
}

function GetRequestHandler() {
    var xmlhttp = null;
    if (window.XMLHttpRequest)
        xmlhttp = new XMLHttpRequest();
    else if (window.ActiveXObject) {
        if (new ActiveXObject("Microsoft.XMLHTTP"))
            xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
        else
            xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
    }
    return xmlhttp;
}

function calWebService(url, postData) {
    var xmlhttp = GetRequestHandler();
    url = url + (url.indexOf('?') == -1 ? "?rnd=" : "&rnd=") + Math.random(); // to be ensure non-cached version
    xmlhttp.open("POST", url, false);
    xmlhttp.setRequestHeader("Content-Type", "application/json");
    xmlhttp.send(postData);
    var responseText = xmlhttp.responseText;
    var jsonData;
    jsonData = eval("(" + responseText + ')');
    return jsonData;
}

function showWindow(pageUrl, paramss) {
    document.getElementById("reportHolder").innerHTML = "";
    $('#reportHolder').append('<iframe id="outputframe" name="outputframe" src="" height="100%" width="100%" allowtransparency="true" frameborder="no" scrolling="auto"></iframe>');
    var ww = $(window).width();
    var hh = $(window).height();
    if (!isMobile) {
        $('#reportHolder').dialog({ title: l_IzpisTitle, modal: false, autoResize: true, position: ['left', 'bottom'], width: (ww - 10), height: (hh / 2), zIndex: 2100, close: onDialogClose });
        dialogOpen = true;
        Submit(pageUrl, paramss, "outputframe");
    }
    else {
        Submit(pageUrl, paramss, "_blank");
    }
}

function onDialogClose() {
    dialogOpen = false;
}

function MultiGridShow(selxml) {
    if (selection.count == 0 && !selxml) {
        alert(l_selectAlert);
        return;
    }

    if (!selxml) {
        selxml = selectionToXml();
    }

    var paramss = new Array(
                                "sessionId", sessionId,
                                "mapName", mapName,
                                "a", appName,
						        "selection", selxml,
						        "WEBLAYOUT", webLayout,
						        "LOCALE", locale,
						        "SEQ", Math.random());
    var pageUrl = ReportUrl;
    showWindow(pageUrl, paramss);
}

function selectionToXml() {
    var xmlSelection = "";
    if (selection.count > 0) {
        xmlSelection = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<FeatureSet>\n";
        for (var layerId in selection.layers.items) {
            xmlSelection += "<Layer id=\"" + layerId + "\">\n";
            var layer = selection.layers.getItem(layerId);
            xmlSelection += "<Class id=\"" + layer.className + "\">\n";
            for (var id in layer.featIds.items)
                xmlSelection += "<ID>" + id + "</ID>\n";
            xmlSelection += "</Class>\n</Layer>\n";
        }
        xmlSelection += "</FeatureSet>\n";
    }

    return xmlSelection;
}

function onPopupClose(evt) {
    ClearSelection();
}

function ClearSelection() {
    if (!mapInitComplete) return;

    vectorSel.removeAllFeatures();
    vector.removeAllFeatures();

    if (popup) {
        popup.hide();
        selGeometry = null;
    }

    selection = new Selection();
    SetSelection("", false);
    mgLayerSel.redraw(true);
    $('#tabs').tabs('select', 1);
}

function SetSelection(selText, requery) {
    var reqParams = "SESSION=" + sessionId + "&MAPNAME=" + encodeURIComponent(mapName) + "&SEQ=" + Math.random() + "&SELECTION=" + encodeURIComponent(selText) + "&QUERYINFO=" + (requery ? "1" : "0");
    reqHandler = GetRequestHandler();
    reqHandler.open("POST", SetSelectionUrl, false);
    reqHandler.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    reqHandler.send(reqParams);
    if (requery)
        return reqHandler.responseXML;
}

function SetSelection2(showDialog) {
    PageMethods.GetVisSelLayers(sessionId, mapName, OnSetSelectionComplete, OnSetSelectionError, showDialog);
}

function OnSetSelectionComplete(result, showDialog) {
    var content = $('#sellyrsHolder')[0];
    content.innerHTML = "";
    var lyrs = eval(result);
    var allLayers = new Array();
    for (var i = 0; i < lyrs.layers.length; i++) {
        var lyr = lyrs.layers[i];
        content.innerHTML += '<input checked type="checkbox" id="' + lyr.name + '" name="' + lyr.name + '" value="' + lyr.name + '"' + '/>';
        content.innerHTML += '<label for="' + lyr.name + '">' + lyr.legend + '</label><br />';
        allLayers.push(lyr.name);
    }

    if (showDialog && lyrs.layers.length > 1) {
        $("#checkall").attr('checked', true);

        $("#selectlayers-form").dialog({
            autoResize: true,
            modal: true,
            buttons: {
                "OK": function () {
                    $(this).dialog("close");

                    var selected = new Array();
                    $('#sellyrsHolder input:checked').each(function () {
                        var nm = $(this).attr('name');
                        if (nm != "") {
                            selected.push(nm);
                        }
                    });

                    if (selected.length > 0) {
                        QueryFeatureInfo(fgfText, selected.join(), maxR);
                    }
                    else {
                        vectorSel.removeAllFeatures();
                        vectorSel.redraw(true);
                    }
                },
                Cancel: function () {
                    $(this).dialog("close");
                    vectorSel.removeAllFeatures();
                    vectorSel.redraw(true);
                }
            },
            close: function () {
            }
        });
    }
    else {
        QueryFeatureInfo(fgfText, allLayers.join(), maxR);
    }
}

function OnSetSelectionError(result) {
    vectorSel.removeAllFeatures();
    vectorSel.redraw(true);
    alert(l_SelectionError);
}

function ZoomSelection() {
    if (selection.count == 0)
        return;

    var reqParams = "OPERATION=GETFEATURESETENVELOPE&VERSION=1.0.0&SESSION=" + sessionId + "&MAPNAME=" + encodeURIComponent(mapName) + "&SEQ=" + Math.random();
    reqParams += "&FEATURESET=" + encodeURIComponent(selectionToXml()) + "&CLIENTAGENT=" + encodeURIComponent(clientAgent);

    dr = GetRequestHandler();
    dr.open("POST", webAgent, false);
    dr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    dr.send(reqParams);

    if (dr.status == 200) {
        var env = ParseEnvelope(dr.responseXML.documentElement);
        if (env != null) {
            var extentSel = new OpenLayers.Bounds(env.lowerLeft.X, env.lowerLeft.Y, env.upperRight.X, env.upperRight.Y);
            var sc = (env.upperRight.X - env.lowerLeft.X);
            if (sc < 10) {
                var cntL = new OpenLayers.LonLat(env.lowerLeft.X + (env.upperRight.X - env.lowerLeft.X) / 2, env.lowerLeft.Y + (env.upperRight.Y - env.lowerLeft.Y) / 2);
                map.setCenter(cntL, 1);
                map.zoomToScale(1000, true);
            }
            else {
                map.zoomToExtent(extentSel);
            }
        }
    }
}

function ParseEnvelope(xmlRoot) {
    try {
        if (xmlRoot.tagName != "Envelope")
            return null;

        var env = new Envelope();
        var xs = xmlRoot.getElementsByTagName("X");
        var ys = xmlRoot.getElementsByTagName("Y");
        env.lowerLeft.X = parseFloat(xs[0].childNodes[0].nodeValue);
        env.lowerLeft.Y = parseFloat(ys[0].childNodes[0].nodeValue);
        env.upperRight.X = parseFloat(xs[1].childNodes[0].nodeValue);
        env.upperRight.Y = parseFloat(ys[1].childNodes[0].nodeValue);
        return env;
    }
    catch (ex) { }
    return null;
}

function Submit(url, params, target) {
    document.getElementById("Params").innerHTML = "";
    form = document.getElementById("Frm");
    form.target = target;
    if (url.indexOf('?') == -1) {
        url = url + '?chromefix=' + Math.random();
    }
    else {
        url = url + '&chromefix=' + Math.random();
    }
    form.action = url;
    if (params) {
        pfields = "";
        for (i = 0; i < params.length; i += 2)
            pfields += "<input id='f" + i + "' type='hidden' name='" + params[i] + "' value=''>\n";
        document.getElementById("Params").innerHTML = pfields;
        for (i = 1; i < params.length; i += 2)
            document.getElementById("f" + (i - 1)).value = params[i];
    }
    form.submit();
}

function GoToScale() {
    var sc = $('#merilo').val();
    checkMapInit();
    $('#tabs').tabs('select', 1);
    map.zoomToScale(sc, true);
}

//classes
function Envelope() {
    this.lowerLeft = new Point(0, 0);
    this.upperRight = new Point(0, 0);
}

function Point(x, y) {
    this.X = x;
    this.Y = y;
}

function Selection() {
    this.layers = new Hashtable();
    this.count = 0;
}

function SelLayer(className) {
    this.className = className;
    this.featIds = new Hashtable();
}

function Hashtable() {
    this.length = 0;
    this.items = new Array();
    for (var i = 0; i < arguments.length; i += 2) {
        if (typeof (arguments[i + 1]) != 'undefined') {
            this.items[arguments[i]] = arguments[i + 1];
            this.length++;
        }
    }

    this.removeItem = function (in_key) {
        var tmp_value;
        if (typeof (this.items[in_key]) != 'undefined') {
            this.length--;
            var tmp_value = this.items[in_key];
            delete this.items[in_key];
        }
        return tmp_value;
    }

    this.getItem = function (in_key) {
        return this.items[in_key];
    }

    this.setItem = function (in_key, in_value) {
        if (typeof (in_value) != 'undefined') {
            if (typeof (this.items[in_key]) == 'undefined')
                this.length++;
            this.items[in_key] = in_value;
        }
        return in_value;
    }

    this.hasItem = function (in_key) {
        return typeof (this.items[in_key]) != 'undefined';
    }
}