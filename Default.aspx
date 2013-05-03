<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="m_OpenLayers" %>

<!DOCTYPE html>

<%@ Register
    Assembly="AjaxControlToolkit"
    Namespace="AjaxControlToolkit"
    TagPrefix="ajaxToolkit" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Collections.Specialized" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="OSGeo.MapGuide" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>

<script language="C#" runat="server">
	// This part of code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
	// Written by Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
	// srecko.lipovsek@kaliopa.si
	// December 2012
	
	String webLayoutDefinition = "";
	String sessionId = "";
	String orgSessionId = "";
	String username = "";
	String password = "";
	String locale = "";
	String mapName = "";
	
	String llX = ""; 
	String llY = ""; 
	String urX = ""; 
	String urY = ""; 
	String cX = ""; 
	String cY = ""; 
	String CurrentDecimalSeparator = "";	
	String metersPerUnit = "";
	String unitsType;
</script>

<script runat="server">

//Page specific functions
void GetRequestParameters()
{
    if (Request.HttpMethod == "POST")
    {
        GetParameters(Request.Form);
    }
    else
    {
        GetParameters(Request.QueryString);
    }
}
void GetParameters(NameValueCollection parameters)
{
    locale = ValidateLocaleString(GetParameter(parameters, "LOCALE"));
    sessionId = ValidateSessionId(GetParameter(parameters, "SESSION"));
    mapName = (GetParameter(parameters, "MAPNAME"));
    webLayoutDefinition = ValidateResourceId(GetParameter(parameters, "WEBLAYOUT"));
    if (sessionId != null && sessionId.Length > 0)
    {
        orgSessionId = sessionId;
    }
    else
    {
        username = GetParameter(parameters, "USERNAME");
        if (null != username && username.Length > 0)
        {
            password = GetParameter(parameters, "PASSWORD");
            if (null == password)
            {
                password = "";
            }
            return;
        }

        //Check in server variables for username and password
        if (Request.ServerVariables["AUTH_USER"].Length>0)
        {
            username = Request.ServerVariables["AUTH_USER"];

            if (Request.ServerVariables["AUTH_PASSWORD"].Length>0)
            {
                password = Request.ServerVariables["AUTH_PASSWORD"];
            }
            return;
        }

        //Check the Http headers for Authorization header
        //If one exist use base64 decoding to get the username:password pair
        if(null != Request.Headers.Get("Authorization"))
        {
            String usernamePassword =Request.Headers["Authorization"];
            usernamePassword = base64Decode(usernamePassword.Substring(6));
            String [] authPair = usernamePassword.Split(':');
            username = authPair[0];
            password = authPair[1];
            return;
        }
    }
}
//Used to decode the String in the authorization header if necessary
String base64Decode(String data)
{
    try
    {
        System.Text.UTF8Encoding encoder = new System.Text.UTF8Encoding();
        System.Text.Decoder utf8Decode = encoder.GetDecoder();

        byte[] todecode_byte = Convert.FromBase64String(data);

        String result = System.Text.Encoding.UTF8.GetString(todecode_byte, 0, todecode_byte.Length);
        return result;
    }
    catch (Exception e)
    {
        throw new Exception("Error in base64Decode" + e.Message);
    }
}
//End of Page specific functions


//Copy of Common functions
String GetRootVirtualFolder(HttpRequest request)
{
    String path = request.ServerVariables["URL"];
    return path.Substring(0, path.IndexOf('/', 1));
}
void RequestAuthentication(string locale)
{
    String product = "MapGuide";
    Response.AddHeader("WWW-Authenticate", "Basic realm=\"" + product + "\"");
    Response.StatusCode = 401;
    Response.StatusDescription = MgLocalizer.GetString("ACCESSDENIED", locale);
    Response.Write(MgLocalizer.GetString("NEEDLOGIN", locale));
    Response.Flush();
}
String GetClientIp(HttpRequest request)
{
    String result = "";
    String httpClientIp = request.ServerVariables["HTTP_CLIENT_IP"];
    String httpXFF = request.ServerVariables["HTTP_X_FORWARDED_FOR"];
    String remoteAddr = request.ServerVariables["REMOTE_ADDR"];

    if (httpClientIp != null && "" != httpClientIp && String.Compare(httpClientIp, "unknown", true) != 0)
        result = httpClientIp;
    else if (httpXFF != null && "" != httpXFF && String.Compare(httpXFF, "unknown", true) != 0)
        result = httpXFF;
    else if (remoteAddr != null)
        result = remoteAddr;

    return result;
}
String GetClientAgent()
{
    return "OpenLayers Mobile Ajax Viewer";
}
String EscapeForHtml(String str)
{
    str = str.Replace("'", "&#39;");
    str = str.Replace("\"", "&quot;");
    str = str.Replace("<", "&lt;");
    str = str.Replace(">", "&gt;");
    str = str.Replace("\\n", "<br>");
    return str;
}
String GetDefaultLocale()
{
    return "en"; // localizable string
}
String ValidateLocaleString(String proposedLocaleString)
{
    // aa or aa-aa
    String validLocaleString = GetDefaultLocale(); // Default
    if (proposedLocaleString != null && (System.Text.RegularExpressions.Regex.IsMatch(proposedLocaleString, "^[A-Za-z]{2}$") ||
        System.Text.RegularExpressions.Regex.IsMatch(proposedLocaleString, "^[A-Za-z]{2}-[A-Za-z]{2}$")))
    {
        validLocaleString = proposedLocaleString;
    }
    return validLocaleString;
}
String ValidateSessionId(String proposedSessionId)
{
    // 00000000-0000-0000-0000-000000000000_aa_[aaaaaaaaaaaaa]000000000000
    // the [aaaaaaaaaaaaa] is a based64 string and in variant length
    String validSessionId = "";
    if (proposedSessionId != null && System.Text.RegularExpressions.Regex.IsMatch(proposedSessionId,
        "^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}_[A-Za-z]{2}_\\w+[A-Fa-f0-9]{12}$"))
    {
        validSessionId = proposedSessionId;
    }
    return validSessionId;
}
String ValidateResourceId(String proposedResourceId)
{
    String validResourceId = "";
    try
    {
        MgResourceIdentifier resId = new MgResourceIdentifier(proposedResourceId);
        validResourceId = resId.ToString();
    }
    catch (MgException)
    {
        validResourceId = "";
    }
    return validResourceId;
}
String GetParameter(NameValueCollection parameters, String name)
{
    String strval = parameters[name];
    if (null == strval)
        return "";

    return strval.Trim();
}
//End of Copy Common functions

</script>

<%
try
	{	
		MgLocalizer.SetLocalizedFilesPath(Request.ServerVariables["APPL_PHYSICAL_PATH"] + "..\\localized\\");
		
		//Get MG SessionID

		// Initialize a session and register a variable to hold the
		// session id, then initialize the Web Extensions, connect
		// to the site, and create a session.

		// Initialize web tier with the site configuration file.  The config
		// file should be in the same directory as this script.
		MapGuideApi.MgInitializeWebTier(Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");

		//Fetch request parameters for this request
		GetRequestParameters();
		
		//Open connection with the server
		bool createSession = true;

		MgUserInformation cred = new MgUserInformation();
		if (null != sessionId && "" != sessionId)
		{
			cred.SetMgSessionId(sessionId);
			createSession = false;
		}
		else if (null != username)
		{
			cred.SetMgUsernamePassword(username, password);
		}
		else
		{
			RequestAuthentication(locale);
			return;
		}
		
		MgSiteConnection site = new MgSiteConnection();
		cred.SetLocale(locale);

		cred.SetClientIp(GetClientIp(Request));
		cred.SetClientAgent(GetClientAgent());

		site.Open(cred);

        MgSite site1 = site.GetSite();
        sessionId = site1.CreateSession();

        MgUserInformation userInfo2 = new MgUserInformation(sessionId);
        MgSiteConnection site2 = new MgSiteConnection();
        site2.Open(userInfo2);
        MgResourceService resourceService = (MgResourceService)site2.CreateService(MgServiceType.ResourceService);
    
        MgMap map = new MgMap();
    
		if (createSession)
		{		
            //Get an MgWebLayout object
            MgWebLayout wl = null;
            MgResourceService resourceSrvc = site2.CreateService(MgServiceType.ResourceService) as MgResourceService;
            MgResourceIdentifier webLayoutId = new MgResourceIdentifier(webLayoutDefinition);
            wl = new MgWebLayout(resourceSrvc, webLayoutId);

            MgPoint ptCenter = wl.GetCenter();

            String mapDefinition = wl.GetMapDefinition();

            MgResourceIdentifier resId = new MgResourceIdentifier(mapDefinition);
            mapName = resId.GetName();

            map.Create(resourceSrvc, resId, mapName);

            //create an empty selection object and store it in the session repository
            MgSelection sel = new MgSelection(map);
            sel.Save(resourceSrvc, mapName);

            MgResourceIdentifier mapStateId = new MgResourceIdentifier("Session:" + sessionId + "//" + mapName + "." + MgResourceType.Map);
            map.Save(resourceSrvc, mapStateId);
		}
        else
        {
            map.Open(resourceService, mapName);
        }		
		  
		MgEnvelope mapExtent = map.MapExtent;
		String srs = map.GetMapSRS();

		metersPerUnit = "1.0";		
				
		if(srs != null && srs.Length > 0)
		{
			MgCoordinateSystemFactory csFactory = new MgCoordinateSystemFactory();
			MgCoordinateSystem cs = csFactory.Create(srs);
			metersPerUnit = cs.ConvertCoordinateSystemUnitsToMeters(1.0).ToString().Replace(',', '.');
			//must be openlayers styled: Possible values are 'degrees' (or 'dd'), 'm', 'ft', 'km', 'mi', 'inches'. 
			unitsType = cs.GetUnits().ToLower();
			if(unitsType.Contains("deg")) unitsType = "dd";
			if(unitsType.Contains("inc")) unitsType = "inches";
			if(unitsType.Contains("feet")) unitsType = "ft";
			if(unitsType == "meter") unitsType = "m";
		}
		else
		{
			//must be openlayers styled: Possible values are 'degrees' (or 'dd'), 'm', 'ft', 'km', 'mi', 'inches'.  
			unitsType = "m"; //MgLocalizer.GetString("DISTANCEMETERS", locale);
		}
		
		MgCoordinate llExtent = mapExtent.GetLowerLeftCoordinate();
		MgCoordinate urExtent = mapExtent.GetUpperRightCoordinate();

		llX = llExtent.X.ToString().Replace(',', '.');
		llY = llExtent.Y.ToString().Replace(',', '.');
		urX = urExtent.X.ToString().Replace(',', '.');
		urY = urExtent.Y.ToString().Replace(',', '.');

		cX = (llExtent.X + (urExtent.X - llExtent.X) / 2).ToString().Replace(',', '.');
		cY = (llExtent.Y + (urExtent.Y - llExtent.Y) / 2).ToString().Replace(',', '.');   

		NumberFormatInfo nfi = System.Threading.Thread.CurrentThread.CurrentCulture.NumberFormat;
		char decimalSeparator = nfi.NumberDecimalSeparator.ToCharArray()[0];
		CurrentDecimalSeparator = decimalSeparator.ToString();    
	}
    catch (MgUnauthorizedAccessException)
    {
        RequestAuthentication(locale);
        return;
    }
    catch (MgUserNotFoundException)
    {
        RequestAuthentication(locale);
        return;
    }
    catch (MgAuthenticationFailedException e)
    {
        RequestAuthentication(locale);
        return;
    }
    catch (MgException e)
    {
        String errorMsg = EscapeForHtml(e.GetDetails());
        Response.Write(errorMsg);
    }
    catch (Exception ne)
    {
        String errorMsg = EscapeForHtml(ne.ToString());
        Response.Write(errorMsg);
    }	
%>

<script language="C#" runat="server">
    public static bool isMobileBrowser()
    {
        //GETS THE CURRENT USER CONTEXT
        HttpContext context = HttpContext.Current;

        //FIRST TRY BUILT IN ASP.NT CHECK
        if (context.Request.Browser.IsMobileDevice)
        {
            return true;
        }

        string strUserAgent = context.Request.UserAgent.ToString().ToLower();

        if (strUserAgent.ToLower().Contains("iphone") ||
            strUserAgent.ToLower().Contains("ipad") ||
            strUserAgent.ToLower().Contains("android") ||
            strUserAgent.ToLower().Contains("blackberry") ||
            strUserAgent.ToLower().Contains("mobile") ||
            strUserAgent.ToLower().Contains("windows ce") ||
            strUserAgent.ToLower().Contains("opera mini") ||
            strUserAgent.ToLower().Contains("palm"))
        {
            return true;
        }

        return false;
    }
</script>

<html>
<head>
    <title>Kaliopa Mapguide Mobile Viewer</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=1;" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
	
    <link rel="stylesheet" href="jQuery/css/smoothness/jquery-ui-1.8.16.custom.css" />
    <link rel="stylesheet" href="jqueryLayerTree.css" />
    <link rel="stylesheet" href="OpenLayers-2.12/theme/default/style.css" />
    <link rel="stylesheet" href="OpenLayers-2.12/css/style.mobile.css" />
    <link rel="stylesheet" href="default.css" />

	<%--you should combine javascript files for bether performance ... look into ToolkitScriptManager ....
	<script type="text/javascript" src="jQuery/jquery-1.7.2.min.js"></script>
	<script type="text/javascript" src="jQuery/jquery-ui-1.8.16.custom.min.js"></script>
	<script type="text/javascript" src="jQuery/jqueryLayerTree.min.js"></script>
	<script type="text/javascript" src="Default.min.js"></script>
    --%>

    <script type="text/javascript" src="OpenLayers-2.12/OpenLayers.js?mobile"></script>
</head>
<body>
    <form id="Frm2" runat="server">
	    <ajaxToolkit:ToolkitScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true"
		    ScriptMode="Release" CombineScripts="true" CompositeScript-ScriptMode="Release">
            <CompositeScript ScriptMode="Release">
                <Scripts>
                    <asp:ScriptReference Name="MicrosoftAjax.js" />
                    <asp:ScriptReference Name="MicrosoftAjaxWebForms.js" />
                    <asp:ScriptReference Path="jQuery/jquery-1.7.2.min.js" />
                    <asp:ScriptReference Path="jQuery/jquery-ui-1.8.16.custom.min.js" />
                    <asp:ScriptReference Path="jQuery/jqueryLayerTree.min.js" />
                    <asp:ScriptReference Path="Default.min.js" />                            
                </Scripts>
            </CompositeScript>            
	    </ajaxToolkit:ToolkitScriptManager>
    </form>
    <div id="outer" style="display: none;">
        <div id="tabs" style="min-width:305px">
            <ul id="tabsUL">
                <li><a href="#tabs-1">
                    <img src="images/home-selected.png" alt="" /></a></li>
                <li><a href="#tabs-2">
                    <img src="images/map.png" alt="" /></a></li>
                <li><a href="#tabs-3">
                    <img src="images/Settings.png" alt="" /></a></li>
                <li><a href="#tabs-4">
                    <img src="images/Search.png" alt="" /></a></li>
            </ul>
            <div id="tabs-1" align="center">                
                <div style="width: 100%">
                    <table width="100%">
                        <tr>
                            <td class="login-text" align="left">
                                <div style="float: left">
                                    
                                </div>
                            </td>
                            <td align="right">
                                <div class="copyright-text" style="float: right">
                                    <a target="_blank" href="http://www.kaliopa.si">© Kaliopa d.o.o.</a> 2002-2012
                                </div>
                            </td>
                        </tr>
                    </table>
                </div>
                <div id="home" align="center" style="width: 100%">                    
                    <table width="100%">
                        <tr>
                            <td style="text-align: center; vertical-align: bottom; font-size: 8pt;">
                                <span style="vertical-align: bottom">
                                    
                                </span>
                            </td>
                        </tr>
                    </table>
                    <br />
                    <p>
                        <a href="http://www.iobcina.si/" target="_blank">
                            <img src="images/Logo-iobcina.png" alt="" />
                        </a>
                    </p>                                        
                </div>                
            </div>
            <div id="tabs-2">
                <table border="0" cellpadding="0" cellspacing="0" style="width: 100%; height: 100%"
                    width="100%">
                    <tr style="width: 100%; height: 100%">
                        <td style="width: 100%; height: 100%">
                            <div id="map">
								<div id="customZoom">
									<a href="#customZoomIn" id="customZoomIn"></a>
									<a href="#customZoomOut" id="customZoomOut"></a>
								</div>
                            </div>
                        </td>
                    </tr>
                </table>
                <div id="mapLoading">
                    <img id="maploadingGif" src="images/loading.gif" alt="" title="" />Loading ...
                </div>
            </div>
            <div id="tabs-3">
                <div class="copyright-text" style="float: right">
                    <a target="_blank" href="http://www.kaliopa.si">© Kaliopa d.o.o.</a> 2002-2012</div>
                <div id="settings" style="width: 100%">
                    <table width="100%">
                        <tr>
                            <td align="center">
                                <b>
                                    Tasks</b>
                            </td>
                        </tr>
                        <tr>
                            <td align="center">
                                <table style="margin-top: 25px">
                                    <tr>
                                        <td colspan="4" align="center" style="text-align: center">
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                    <span class="table-text" style="text-align: center">
                                                        <img id="locate" src="images/lociraj.png" alt="Locate me"
                                                            title="Locate me" style="cursor: pointer;" /></span></span></span></span></span>
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                    <img src="images/skoci.png" alt="Go to"
                                                        title="Go to" style="cursor: pointer;"
                                                        onclick="GoToCoordinateCommand();" /></span></span></span></span>
                                        </td>
                                        <td colspan="2" align="center" class="table-text" style="text-align: center">
                                            <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                <span class="table-text" style="text-align: center">
                                                    <img id="track" src="images/nesledi.png" width="65px" alt="Track my location"
                                                        title="Track my location" style="cursor: pointer;" /></span></span></span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                    Locate me</span></span></span></span>
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                    <span class="table-text" style="text-align: center">
                                                        Go to</span></span></span></span></span>
                                        </td>
                                        <td colspan="2" align="center" class="table-text" style="text-align: center">
                                            <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                    <span class="table-text" style="text-align: center"><span class="table-text" style="text-align: center">
                                                        Track my location</span></span></span></span></span></span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="4" align="center" style="text-align: center">
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <img src="images/pocisti.png" alt="Clear"
                                                title="Clear" style="cursor: pointer;"
                                                onclick="ClearSelection();" />
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <img src="images/element.png" alt="Display report"
                                                title="Display report" style="cursor: pointer;"
                                                onclick="MultiGridShow();" />
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <img src="images/tocki.png" alt="Info about point"
                                                title="Info about point" style="cursor: pointer;"
                                                onclick="PointInfoCommand() ;" />
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="table-text">
                                            Clear
                                        </td>
                                        <td class="table-text">
                                            Display report
                                        </td>
                                        <td class="table-text">
                                            Info about point
                                        </td>
                                        <td class="table-text">
                                            
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="4" align="center" style="text-align: center">
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <img src="images/onof.png" alt="Layers ON/OFF"
                                                title="Layers ON/OFF" style="cursor: pointer;"
                                                onclick="MakeLegend();" />
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            <img src="images/legenda.png" alt="Legend"
                                                title="Legend" style="cursor: pointer;"
                                                onclick="PrintLegend1();" />
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            
                                        </td>
                                        <td class="table-text" align="center" style="text-align: center">
                                            
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="table-text" style="border-right: thin">
                                            Layers ON/OFF
                                        </td>
                                        <td class="table-text">
                                            Legend
                                        </td>
                                        <td class="table-text">
                                            
                                        </td>
                                        <td class="table-text">
                                            
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="4" align="center" style="text-align: center">
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="4" align="center" style="text-align: center">
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="7" align="center">
                                            <fieldset style="border: 1px solid #91A2AF; margin: 5px; padding: 10px;">
                                                <legend style="color: #91A2AF; font-family: Arial; font-size: 12px">
                                                    Set scale</legend>
                                                <input type="text" name="merilo" id="merilo" value="" />
                                                <img id="btScale" src="images/mActionZoomToLayer.png" alt="Set scale"
                                                    title="Set scale" style="cursor: pointer;
                                                    vertical-align: bottom;" /><br />
                                            </fieldset>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                </div>
            </div>            
            <div id="tabs-4">
                <div class="copyright-text" style="float: right">
                    <a target="_blank" href="http://www.kaliopa.si">© Kaliopa d.o.o.</a> 2002-2012</div>
                <div id="search" style="width: 100%">
					Custom search implementation ....
                </div>
            </div>
        </div>
        <div style="display: none; visibility: hidden; width: 100%; height: 100%">
            <div id="layerBrowserHolder" style="z-index: 2100; width: 100%; height: 100%">
                <div id="layerBrowser" style="width: 100%; height: 100%">
                </div>
            </div>
            <div id="legendHolder" style="z-index: 2100; width: 100%; height: 100%">
            </div>
            <div id="reportHolder" style="z-index: 2100; width: 100%; height: 100%">
            </div>
            <div id="infoHolder" style="z-index: 2100; width: 100%; height: 100%">
            </div>
			
			<div id="selectlayers-form" title="Select Layers">
			  <fieldset>
				<div><input type="checkbox" id="checkall" checked="checked" class="checkall" />
                <label for="checkall">Check/Uncheck all</label></div>
				<hr />
				<div id="sellyrsHolder"></div>
			  </fieldset>
			</div>	
            <div id="goToCoordinateHolderDialog" style="z-index: 2100; width: 100%; height: 100%">
                <div id="goToCoordinateHolder" style="z-index: 2100; width: 100%; height: 100%">
                    <ul>
                        <li><a href="#cootabs-1" class="selected">MAP</a></li>
                        <li><a href="#cootabs-2">WGS84</a></li>
                    </ul>
                    <div id="cootabs-1" align="center" style="font-size: 11pt;">
                        <table id="winGotTo" width="100%">
                            <tr>
                                <td colspan="2" align="left">
                                    <b>
                                        Go to Map coordinate:</b>
                                </td>
                            </tr>
                            <tr>
                                <td align="left">
                                    <b>X:</b>
                                </td>
                                <td align="left">
                                    <input id="winGotToX" type="text" />
                                </td>
                            </tr>
                            <tr>
                                <td align="left">
                                    <b>Y:</b>
                                </td>
                                <td align="left">
                                    <input id="winGotToY" type="text" />
                                </td>
                            </tr>
                            <tr>
                                <td colspan="2" align="right">
                                    <input type="button" value="Go to"
                                        onclick="GoTo()" />
                                </td>
                            </tr>
                        </table>
                    </div>
                    <div id="cootabs-2" align="center" style="font-size: 11pt;">
                        <table id="Table1" width="100%">
                            <tr>
                                <td colspan="2" align="left">
                                    <b>
                                        Go to coordinates WGS84:</b>
                                </td>
                            </tr>
                            <tr>
                                <td align="left">
                                    <b>Lat:</b>
                                </td>
                                <td align="left">
                                    <input id="winGotToLat" type="text" />
                                </td>
                            </tr>
                            <tr>
                                <td align="left">
                                    <b>Lon:</b>
                                </td>
                                <td align="left">
                                    <input id="winGotToLon" type="text" />
                                </td>
                            </tr>
                            <tr>
                                <td colspan="2" align="right">
                                    <input type="button" value="Go to"
                                        onclick="GoToLatLon()" />
                                </td>
                            </tr>
                        </table>
                    </div>
                </div>
            </div>
        </div>
        <form method="post" id="Frm" target="" action="" enctype="application/x-www-form-urlencoded">
        <div id="Params">
        </div>
        </form>        
    </div>
    <script type="text/javascript">
    //<![CDATA[
        //public properties
		var DPI = 96;
		var selectionColor = 'FF5300FF';
		var clientAgent = '<%= GetClientAgent() %>';
		var metersPerUnit = <%= metersPerUnit %>;  //value returned from mapguide !
		//must be openlayers styled: Possible values are 'degrees' (or 'dd'), 'm', 'ft', 'km', 'mi', 'inches'. 
		var unitsType = '<%= unitsType%>'; 

        var appName = "myApp";  
        var appDesc = "myAppDesc";
		
        var sessionId = "<%=sessionId %>";
        var mapName = "<%=mapName %>";
        var webLayout = "<%=webLayoutDefinition %>";
        var locale = "<%=locale %>";
        var llX = <%= llX %>;
        var llY = <%= llY %>;
        var urX = <%= urX %>;
        var urY = <%= urY %>;
        var cX = <%= cX %>;
        var cY = <%= cY %>;
		var CurrentDecimalSeparator = "<%= CurrentDecimalSeparator %>";
		
		var IntersectPageUrl = "Intersect.aspx";
		var LayerTreeConnectorUrl = "jqueryLayerTree.aspx";
		var PrintLegendUrl = "PrintLegend.ashx";
		var ReportUrl = "MultiGrid_Show.aspx";
						
        //set selection url
		var SetSelectionUrl = "<%=GetRootVirtualFolder(Request)%>/mapviewerajax/setselection.aspx";
		
		var isMobile = <%= isMobileBrowser().ToString().ToLower()%>; //used in default.min.js -> load diferent OpenLayers Map settings -> you should get it from ASP.NET function Request.IsMobile or any other one if you plan to use this code in classic browser ...
		
		//path to mapguide.fcgi
        var webAgent = "<%=GetRootVirtualFolder(Request)%>/mapagent/mapagent.fcgi?";
        
		var initMapOnLoad = true; //shoud auto open second tab and load map ... get it from database setting ? ...

        //javascript localization messages
		//should set from localization ...
        var l_mgSelLayerName = "-selection";
        var l_geolocation = "Geolocation";
        var l_selectionLName = "Selection";
        var l_measurerazdalja = "Distance: ";
        var l_measurepovrsina = "Area: ";
        var l_izpis = "Display report";
        var l_pojdi = "Go to object";
        var l_selectAlert = "Select the objects on the map!";
        var l_mapNotInitAlert = "Map has not yet been initialized! \nPlease try again.";
        var l_tockaInfo = "Info about point";
        var l_vsebineOnOff = "Layers ON/OFF";
        var l_legenda = "Layer legend";
        var l_goToCoordinate = "Go to coordinate";
        var l_IzpisTitle = "PRINTOUTS and ANALYSIS";
        var l_GPSTitle = "Locate me";
		var l_GPSError = "Your device does not support geolocation!";
		var l_GPSPerrmissionDenied = "Acces to geolocation was blocked by user.";
		var l_GPSNotAvailable = "Could not get your geolocation. Check if your device support geolocation or you have permission for it.";
		var l_GPSTimeout = "Timeout.";
		var l_GPSUnknown = "Unknown error.";
		var l_SelectionError = "Sorry, unexpected error ocured. Please try again!";
		var l_LocationOutside = "Your location is outside of current map extent!";
        var l_DrawPoint = "Draw POINT on screen.";

        var wmsLayArr1;
        var wmsLayArr2;

        //load base maps from settings in database or set them static ...
        function initWms(){
            wmsLayArr1 = new Array(); //list of base layers
            wmsLayArr2 = new Hashtable(); //list of base layers ids
			
            // add WMS or Google base layer to your map
			// you need to create your own custom build of OpenLayers library and include library that you need ...
			// you can populate this section dynamicly from e.g. database settings ...
			
			// sample for WMS:
			// var layerPK4 = new OpenLayers.Layer.WMS( "Description", "http://wms_link", {layers: 'my_layer_name', format: 'image/jpeg'}, {transitionEffect: 'resize'} );
			// wmsLayArr1.push(layerPK4);
			// wmsLayArr2.setItem(layerPK4.id, 'PK4');
			
			//WARNING:
			//If you are going to use GOOGLE or any other base map you shoud make your own OpenLayers.js build ...
			//Read Readme_kaliopa.txt in OpenLayers-2.12 folder ...
        }
        //]]>
    </script>
</body>
</html>
