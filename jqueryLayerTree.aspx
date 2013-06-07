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
	// This part of code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
	//
	// Wrriten by Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
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

    List<MgLayerBase> lyrs = null;

    if (string.IsNullOrEmpty(dir))
    {
        lyrs = map.GetLayers().Where(t => t.Group == null).ToList(); //root layers
    }
    else
    {
        lyrs = map.GetLayers().Where(t => t.Group.GetObjectId() == dir).ToList(); //layers inside groups ...
    }
    
    Response.Write("<ul class=\"jqueryFileTree\" style=\"display: none;\">\n");
    foreach (var fi in lyrs)
    {
        // legend image
        string url = "http://" + Request.ServerVariables["SERVER_NAME"] + "/mapguide/mapagent/mapagent.fcgi" + "?OPERATION=GETLEGENDIMAGE&SESSION=" + sessionId +
        "&VERSION=1.0.0&SCALE=" + map.ViewScale + "&LAYERDEFINITION=" + Server.UrlEncode(fi.GetLayerDefinition().ToString()) +
        "&THEMECATEGORY=" + (0) + "&TYPE=" + (-1) + "&CLIENTAGENT=" + "Mobile%20Ajax%20Viewer";

        string checkedIcon = "images/lc_checked.png";
        if (!fi.Visible)
        {
            checkedIcon = "images/lc_unchecked.png";
        }

        MgByteReader layersData = resourceService.GetResourceContent(fi.GetLayerDefinition());

        //is layer visible at current scale?
        if (IsLayerVisibleAtScaleRange(layersData.ToString(), map.ViewScale))
        {
            string oid = fi.GetObjectId();
            
            //with legend image
            Response.Write("\t<li><a href=\"#\" rel=\"" + oid + "\"><img id=\"Chk_" + oid + "\" onclick=\"ChangeVisibility(0,'" + oid + "');\" border=0 src=\"" + checkedIcon + "\" />" + "<img border=0 src=\"" + url + "\" />" + fi.LegendLabel + "</a></li>\n");
            
            //without legend image
            //Response.Write("\t<li><a href=\"#\" rel=\"" + oid + "\"><img id=\"Chk_" + oid + "\" onclick=\"ChangeVisibility(0,'" + oid + "');\" border=0 src=\"" + checkedIcon + "\" />" + fi.LegendLabel + "</a></li>\n");
        }
    }
	
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
        
	Response.Write("</ul>");
 %>

<script runat="server">
    bool IsLayerVisibleAtScaleRange(string layerData, double viewScale)
    {
        try
        {
            System.Xml.XmlDocument doc = new System.Xml.XmlDocument();
            doc.LoadXml(layerData);

            System.Xml.XmlNodeList scaleRanges = doc.GetElementsByTagName("VectorScaleRange");
            if(scaleRanges.Count == 0)
            {
                scaleRanges = doc.GetElementsByTagName("GridScaleRange");
                if(scaleRanges.Count == 0) {
                    scaleRanges = doc.GetElementsByTagName("DrawingLayerDefinition");
                    if(scaleRanges.Count == 0)
                        return true;
                }
            }

            NumberFormatInfo nfi = System.Threading.Thread.CurrentThread.CurrentCulture.NumberFormat;
            char decimalSeparator = nfi.NumberDecimalSeparator.ToCharArray()[0];
            string CurrentDecimalSeparator = decimalSeparator.ToString();    
        
            String[] typeStyles = new String[]{"PointTypeStyle", "LineTypeStyle", "AreaTypeStyle", "CompositeTypeStyle"};
            String[] ruleNames = new String[]{"PointRule", "LineRule", "AreaRule", "CompositeRule"};

            for (int sc = 0; sc < scaleRanges.Count; sc++)
            {
                System.Xml.XmlElement scaleRange = (System.Xml.XmlElement)scaleRanges[sc];
                System.Xml.XmlNodeList minElt = scaleRange.GetElementsByTagName("MinScale");
                System.Xml.XmlNodeList maxElt = scaleRange.GetElementsByTagName("MaxScale");
                String minScale, maxScale;
                minScale = "0";
                maxScale = "1000000000000.0";   // as MDF's VectorScaleRange::MAX_MAP_SCALE
                if (minElt.Count > 0)
                    minScale = minElt[0].ChildNodes[0].Value.Replace(",", CurrentDecimalSeparator).Replace(".", CurrentDecimalSeparator);
                if (maxElt.Count > 0)
                    maxScale = maxElt[0].ChildNodes[0].Value.Replace(",", CurrentDecimalSeparator).Replace(".", CurrentDecimalSeparator);

                if (viewScale >= double.Parse(minScale) && viewScale < double.Parse(maxScale))
                {
                    return true;                
                }
            }
            return false;
        }
        catch (Exception)
        {
            return true;
        }
    }
</script>