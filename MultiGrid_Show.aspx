<%@ Page Language="C#" ValidateRequest="false" EnableSessionState="True" EnableViewState="true"
    CodeFile="MultiGrid_Show.aspx.cs" Inherits="MultiGrid_Show" %>

<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Collections.Specialized" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="OSGeo.MapGuide" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<html>
<head>
    <title>Report</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <style type="text/css" media="screen">
        body
        {
            margin: 3;
            padding: 3;
            padding-right: 0px;
            padding-left: 0px;
            padding-bottom: 0px;
            padding-top: 0px;
            font-family: Verdana, Tahoma, Arial;
            font-size: 10px;
            background-color: white;
        }
        .main
        {
            font-size: 10px;
            color: black;
            background-color: white;
        }
        .main2
        {
            font-size: 10px;
            color: black;
            background-color: #BBBBBB;
        }
        .header
        {
            font-size: 10px;
            color: white;
            font-family: Verdana;
            background-color: #585858;
        }
        .results
        {
            border-right: 0px;
            border-top: 0px;
            border-left: 0px;
            border-bottom: 0px;
        }
    </style>
    <style type="text/css" media="print">
        .noprint
        {
            display: none;
            visibility: hidden;
        }
        .results
        {
            border-color: black;
            border-width: 1px 1px 1px 1px;
            border-style: solid;
            border-collapse: collapse;
        }
        .results td, .Header
        {
            border-color: black;
            border-width: 1px 1px 1px 1px;
            border-style: solid;
            border-collapse: collapse;
        }
    </style>
    <script type="text/javascript" language="javascript">
        var StaraBarva = '#e3e3e3';
        function getTR(myElement) {
            if (myElement.tagName == 'TR') {
                return document.all(myElement.sourceIndex);
            }
            else {
                return getTR(myElement.parentElement);
            }
        }
        function LineOn(e) {

            if (window.event) e = window.event;
            var srcEl = e.srcElement ? e.srcElement : e.target;

            var tr = getTR(srcEl);
            StaraBarva = tr.bgColor;
            for (var j = 0; j < tr.cells.length; j++) {
                tr.cells(j).style.backgroundColor = '#e3e3e3';
            }
        }
        function LineOff(e) {
            if (window.event) e = window.event;
            var srcEl = e.srcElement ? e.srcElement : e.target;
            var tr = getTR(srcEl);
            for (var j = 0; j < tr.cells.length; j++) {
                tr.cells(j).style.backgroundColor = StaraBarva;
            }
        }

        var sessionId = '<%= Request["sessionId"] %>';
        var mapName = '<%= Request["mapName"] %>';
        var webLayout = '<%= Request["WEBLAYOUT"] %>';
        var locale = '<%= Request["locale"] %>';
                		
    </script>
</head>
<body>
    <%
	
	// This part of code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
	// Wrriten by Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
	// srecko.lipovsek@kaliopa.si
	// December 2012
	//  
	
        Response.Cache.SetCacheability(HttpCacheability.NoCache);

        string sessionId = Request["sessionId"];
        string mapName = Request["mapName"];
        string selection = Request["selection"];

        if (string.IsNullOrEmpty(sessionId)) return; //required parameter
        if (string.IsNullOrEmpty(mapName)) return; //required parameter

        string zoomTempl = ""; //template for button zoom ...
        string selectTempl = ""; //template for button select ...

        Response.Write("<table>");

        //Response.Write("<tr class=\"noprint\"><td><hr /></td></tr>");

        if (string.IsNullOrEmpty(selection))
        {
            //other ways to get selection ...
        }
        else
        {
            selection = Server.HtmlDecode(selection);
        }

        if (!string.IsNullOrEmpty(selection))
        {
            MgResourceService resourceSrvc = GetMgResurceService(sessionId);
            MgFeatureService featureService = GetMgFeatureService(sessionId);

            MgMap map = new MgMap();
            map.Open(resourceSrvc, mapName);

            MgSelection sel = new MgSelection(map, selection);

            foreach (MgLayerBase layer in sel.GetLayers())
            {
                Response.Write("<tr><td style=\"font-size: 9pt\" valign=\"middle\"><b>" + layer.LegendLabel + "</b></td></tr>");
                Response.Write(
                    "<tr><td><table class=\"results\" align=\"left\" CELLPADDING=\"2\"  CELLSPACING=\"2\">");

                try
                {
                    string filter = sel.GenerateFilter(layer, layer.GetFeatureClassName());
                    MgResourceIdentifier resId = new MgResourceIdentifier(layer.GetFeatureSourceId());
                    MgFeatureQueryOptions query = new MgFeatureQueryOptions();
                    query.SetFilter(filter);
                    MgDataPropertyDefinition idProperty = GetIdProperty(featureService, layer);

                    List<string> featIds = new List<string>();
                    MgFeatureReader reader = featureService.SelectFeatures(resId, layer.GetFeatureClassName(), query);
                    string geom = layer.GetFeatureGeometryName().ToLower();

                    Response.Write("<tr><th class=\"header\"></th><th class=\"header\"></th><th class=\"header\"></th>");
                    for (int i = 0; i < reader.GetPropertyCount(); i++)
                    {
                        if (reader.GetPropertyName(i).ToLower() != idProperty.Name.ToLower() &&
                            reader.GetPropertyName(i).ToLower() != geom)
                        {
                            Response.Write("<th valign=\"middle\" class=\"header\">" + reader.GetPropertyName(i) +
                                           "</th>");
                        }
                    }
                    Response.Write("</tr>");
                    Response.Flush();

                    int autonumber = 1;

                    while (reader.ReadNext())
                    {
                        string clas = "main";
                        if (autonumber % 2 == 0) clas = "main2";

                        Response.Write("<tr onmouseover=\"LineOn(event)\" onmouseout=\"LineOff(event)\">");
                        Response.Write("<td align=center class=" + clas + "><b>" + autonumber.ToString() +
                                       "</b></td>");

                        Response.Write("<td align=center class=" + clas + "><b>" + string.Format(zoomTempl, layer.Name, GetPropertyValue(reader, idProperty.Name)) + "</b></td>");
                        Response.Write("<td align=center class=" + clas + "><b>" + string.Format(selectTempl, layer.Name, GetPropertyValue(reader, idProperty.Name)) + "</b></td>");

                        autonumber++;

                        for (int i = 0; i < reader.GetPropertyCount(); i++)
                        {
                            if (reader.GetPropertyName(i).ToLower() != idProperty.Name.ToLower() &&
                                reader.GetPropertyName(i).ToLower() != geom)
                            {
                                string val = GetPropertyValue(reader, reader.GetPropertyName(i)).ToString();

                                if (val.IndexOf("http") != -1 || val.IndexOf("www") != -1)
                                {
                                    val = "<a href=\"" + val + "\" target=_blank>" + val + "</a>";
                                }

                                Response.Write("<td align=left class=" + clas + ">" + val.Replace("\\n", "<br />") + "</td>");
                            }
                        }
                        Response.Write("</tr>");
                        Response.Flush();
                    }

                    reader.Close();
                    reader.Dispose();
                }
                catch (Exception)
                {
                }

                Response.Write("</table></td></td>");
                Response.Write("<tr><td>&nbsp;</td></tr>");
                Response.Flush();
            }
        }

        Response.Write("</table>");        
        
    %>
    <form method="post" id="Frm" target="" action="" enctype="application/x-www-form-urlencoded">
    <div id="Params">
    </div>
    </form>
    <input id="selection" name="selection" type="hidden" value="<%= string.IsNullOrEmpty(Request["selection"]) ? "" : Server.HtmlEncode(Request["selection"].ToString()) %>" />
</body>
</html>
<script runat="server">
         
    public static MgClassDefinition GetClassDefinition(MgFeatureService featureService, MgLayerBase layer)
    {
        String featureSourceId = layer.GetFeatureSourceId();
        MgResourceIdentifier featureSourceResId = new MgResourceIdentifier(featureSourceId);
        String featureClassName = layer.GetFeatureClassName();

        String[] schemaClass = featureClassName.Split(new char[] { ':' });
        String schemaName = "";
        String className = "";
        if (schemaClass.Count() == 2)
        {
            schemaName = schemaClass[0];
            className = schemaClass[1];
        }
        else
        {
            schemaName = "";
            className = schemaClass[0];
        }
        return featureService.GetClassDefinition(featureSourceResId, schemaName, className);
    }

    public MgDataPropertyDefinition GetIdProperty(MgFeatureService service, MgLayerBase layer)
    {
        MgClassDefinition classDef = GetClassDefinition(service, layer);
        return classDef.GetIdentityProperties()[0] as MgDataPropertyDefinition;
    }

    public object GetPropertyValue(MgFeatureReader reader, string propName)
    {
        object value = null;
        int propType = reader.GetPropertyType(propName);
        try
        {
            switch (propType)
            {
                case MgPropertyType.Boolean:
                    value = Boolean.Parse(reader.GetBoolean(propName).ToString());
                    break;
                case MgPropertyType.Byte:
                    value = Byte.Parse(reader.GetByte(propName).ToString());
                    break;
                case MgPropertyType.Single:
                    value = Single.Parse(reader.GetSingle(propName).ToString());
                    break;
                case MgPropertyType.Double:
                    value = Double.Parse(reader.GetDouble(propName).ToString());
                    break;
                case MgPropertyType.Int16:
                    value = Int16.Parse(reader.GetInt16(propName).ToString());
                    break;
                case MgPropertyType.Int32:
                    value = Int32.Parse(reader.GetInt32(propName).ToString());
                    break;
                case MgPropertyType.Int64:
                    value = Int64.Parse(reader.GetInt64(propName).ToString());
                    break;
                case MgPropertyType.String:
                    value = reader.GetString(propName).ToString();
                    break;
                case MgPropertyType.Geometry:
                    value = reader.GetGeometry(propName);
                    break;
                case MgPropertyType.DateTime:
                    value = reader.GetDateTime(propName).ToString();
                    break;
                default:
                    value = "";
                    break;
            }
        }
        catch (Exception)
        {
            return "";
        }
        return value;
    }

    private MgResourceService GetMgResurceService(string sessionId)
    {
        MapGuideApi.MgInitializeWebTier(Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");
        MgUserInformation userInfo = new MgUserInformation(sessionId);
        MgSiteConnection site = new MgSiteConnection();
        site.Open(userInfo);

        MgResourceService resourceService = (MgResourceService)site.CreateService(MgServiceType.ResourceService);
        return resourceService;
    }

    private MgFeatureService GetMgFeatureService(string sessionId)
    {
        MapGuideApi.MgInitializeWebTier(Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");
        MgUserInformation userInfo = new MgUserInformation(sessionId);
        MgSiteConnection site = new MgSiteConnection();
        site.Open(userInfo);

        MgFeatureService featureService = (MgFeatureService)site.CreateService(MgServiceType.FeatureService);
        return featureService;
    }
    
</script>
