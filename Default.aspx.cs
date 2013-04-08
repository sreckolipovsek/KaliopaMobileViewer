using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Web.Security;
using OSGeo.MapGuide;
using System.Configuration;
using System.Collections.Generic;
using System.Web.Configuration;
using System.Text.RegularExpressions;
using System.Text;
using System.Linq;
using System.Collections.Specialized;

// This part of code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
// Wrriten by Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
// srecko.lipovsek@kaliopa.si
// December 2012 

public partial class m_OpenLayers : System.Web.UI.Page
{       
    [System.Web.Services.WebMethod()]
    [System.Web.Script.Services.ScriptMethod()]
    public static string TransformWgs2GK(double lat, double lon, double accuracy, string ss, string mpN) //Transform WGS84 to Map koordinate system
    {
        MgMap map = new MgMap();
        MgResourceService resourceSrvc = GetMgResurceService(ss);
        map.Open(resourceSrvc, mpN);

        //Create coordinate system factory
        MgCoordinateSystemFactory fact = new MgCoordinateSystemFactory();
        string wktTo = map.GetMapSRS();
        string wktFrom = "GEOGCS[\"LL84\",DATUM[\"WGS84\",SPHEROID[\"WGS84\",6378137.000,298.25722293]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.01745329251994]]";

        MgCoordinateSystem coordinateSystemSource = fact.Create(wktFrom);
        MgCoordinateSystem coordinateSystemTarget = fact.Create(wktTo);

        MgGeometryFactory geomFact = new MgGeometryFactory();

        MgCoordinateSystemTransform coordTransform = fact.GetTransform(coordinateSystemSource, coordinateSystemTarget);

        MgCoordinate coord = coordTransform.Transform(lon, lat);

        return coord.X.ToString().Replace(',', '.') + ";" + coord.Y.ToString().Replace(',', '.') + ";" + accuracy.ToString().Replace(',', '.');
    }

    [System.Web.Services.WebMethod()]
    [System.Web.Script.Services.ScriptMethod()]
    public static string TransformGK2Wgs(double x, double y, string ss, string mpN) //Transform from Map to WGS 84 Coordtnate System 
    {
        MgMap map = new MgMap();
        MgResourceService resourceSrvc = GetMgResurceService(ss);
        map.Open(resourceSrvc, mpN);

        //Create coordinate system factory
        MgCoordinateSystemFactory fact = new MgCoordinateSystemFactory();
        string  wktFrom = map.GetMapSRS();
        string wktTo = "GEOGCS[\"LL84\",DATUM[\"WGS84\",SPHEROID[\"WGS84\",6378137.000,298.25722293]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.01745329251994]]";

        MgCoordinateSystem coordinateSystemSource = fact.Create(wktFrom);
        MgCoordinateSystem coordinateSystemTarget = fact.Create(wktTo);

        MgGeometryFactory geomFact = new MgGeometryFactory();

        MgCoordinateSystemTransform coordTransform = fact.GetTransform(coordinateSystemSource, coordinateSystemTarget);

        MgCoordinate coord = coordTransform.Transform(x, y);

        return coord.X.ToString().Replace(',', '.') + ";" + coord.Y.ToString().Replace(',', '.');
    }

    [System.Web.Services.WebMethod()]
    [System.Web.Script.Services.ScriptMethod()]
    public static string GetVisSelLayers(string ss, string mpN){
        MgMap map = new MgMap();
        MgResourceService resourceSrvc = GetMgResurceService(ss);
        map.Open(resourceSrvc, mpN);
        StringBuilder sb = new StringBuilder();
        foreach (MgLayerBase item in map.GetLayers())
        {
            if (item.IsVisible() && item.Selectable)
            {
                sb.Append(item.Name + ",");
            }
        }
        return sb.ToString().Substring(0, sb.ToString().Length - 1);
    }
    
    private static MgResourceService GetMgResurceService(string sessionId)
    {
        // Initialize web tier with the site configuration file.  The config
		// file should be in the same directory as this script.
		// MapGuideApi.MgInitializeWebTier(Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");
	
        MgUserInformation userInfo = new MgUserInformation(sessionId);
        MgSiteConnection site = new MgSiteConnection();
        site.Open(userInfo);

        MgResourceService resourceService = (MgResourceService)site.CreateService(MgServiceType.ResourceService);
        return resourceService;
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        
    }

    protected void Page_PreRender(object sender, EventArgs e)
    {
        
    }
    
}