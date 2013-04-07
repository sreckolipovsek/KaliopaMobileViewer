<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Collections.Specialized" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="OSGeo.MapGuide" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Security.Principal" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>

<%
	//
	// jQuery Mapguide Layer Tree ASP.NET Connector
	//
	//
	// Copyright Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
	// srecko.lipovsek@kaliopa.si
	// December 2012
	// 
    
    var sessionId = Server.UrlDecode(Request.Form["sessionId"]).ToString();
    var mapName = Server.UrlDecode(Request.Form["mapName"]).ToString();

    if (string.IsNullOrEmpty(sessionId))
    {
        return;
    }
    if (string.IsNullOrEmpty(mapName))
    {
        return;
    }

    MapGuideApi.MgInitializeWebTier(Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");
    MgUserInformation userInfo = new MgUserInformation(sessionId);
    MgSiteConnection site = new MgSiteConnection();
    site.Open(userInfo);
    MgResourceService resourceService = (MgResourceService)site.CreateService(MgServiceType.ResourceService);
    MgMap map = new MgMap();
    map.Open(resourceService, mapName);

    List<MgLayerGroup> grps = null;
           
	string dir = "";
    if (Request.Form["dir"] == null || Request.Form["dir"].Length <= 0)
    {
        //root
        grps = map.GetLayerGroups().Where(t => t.Group == null).ToList();
    }
    else
    {
        //child
        dir = Server.UrlDecode(Request.Form["dir"]).ToString().Replace("/", "");
        grps = map.GetLayerGroups().Where(t => t.Group != null && t.Group.GetObjectId() == dir).ToList();
    }
	
	//System.IO.DirectoryInfo di = new System.IO.DirectoryInfo(dir);
	Response.Write("<ul class=\"jqueryFileTree\" style=\"display: none;\">\n");
    foreach (var di_child in grps)
    {
        string checkedIcon = "images/lc_checked.png";
        if (!di_child.Visible)
        {
            checkedIcon = "images/lc_unchecked.png";
        }
        string oid = di_child.GetObjectId();
        Response.Write("\t<li class=\"directory collapsed\"><a href=\"#\" rel=\"" + oid + "/\"><img id=\"Chk_" + oid + "\" onclick=\"ChangeVisibility(1,'" + oid + "');\" border=0 src=\"" + checkedIcon + "\" />" + di_child.LegendLabel + "</a></li>\n");
    }
	
    var lyrs = map.GetLayers().Where(t => t.Group.GetObjectId() == dir).ToList();
	
    foreach (var fi in lyrs)
	{
	   // legend image
       // string url = "http://" + Request.ServerVariables["SERVER_NAME"] + "/mapguide/mapagent/mapagent.fcgi" + "?OPERATION=GETLEGENDIMAGE&SESSION=" + sessionId +
       // "&VERSION=1.0.0&SCALE=" + map.ViewScale + "&LAYERDEFINITION=" + Server.UrlEncode(fi.GetLayerDefinition().ToString()) +
       // "&THEMECATEGORY=" + (0) + "&TYPE=" + (-1) + "&CLIENTAGENT=" + "Ajax%20Viewer";

        string checkedIcon = "images/lc_checked.png";
        if (!fi.Visible)
        {
            checkedIcon = "images/lc_unchecked.png";
        }
        
        string oid = fi.GetObjectId();
        Response.Write("\t<li><a href=\"#\" rel=\"" + oid + "\"><img id=\"Chk_" + oid + "\" onclick=\"ChangeVisibility(0,'" + oid + "');\" border=0 src=\"" + checkedIcon + "\" />" + /*"<img border=0 src=\"" + url + "\" />" +*/ fi.LegendLabel + "</a></li>\n");		
	}
	Response.Write("</ul>");
 %>
