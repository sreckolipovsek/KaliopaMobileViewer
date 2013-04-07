using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using OSGeo.MapGuide;
using System.Collections;
using System.Text;
using System.Data.SqlClient;
using System.Configuration;
using System.Data;

// Copyright Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
// srecko.lipovsek@kaliopa.si
// December 2012 

public partial class m_Intersect : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            string sessionId = GetRequestParameters(Request)["SESSION"];
            string mapName = GetRequestParameters(Request)["MAPNAME"];
            string locale = GetRequestParameters(Request)["LOCALE"];

            if (string.IsNullOrEmpty(sessionId))
            {
                Response.Clear();
                Response.End();
                return;
            }

            if (string.IsNullOrEmpty(mapName))
            {
                Response.Clear();
                Response.End();
                return;
            }

            MgResourceService resourceSrvc = GetMgResurceService(sessionId);
            MgFeatureService featureSrvc = GetMgFeatureService(sessionId);

            MgMap map = new MgMap();
            map.Open(resourceSrvc, mapName);
            
            string layernames = GetRequestParameters(Request)["LAYERNAMES"];
            string GEOMETRY = GetRequestParameters(Request)["GEOMETRY"];
            string selVar = GetRequestParameters(Request)["SELECTIONVARIANT"];
            string type = GetRequestParameters(Request)["tp"];
            string inputSel = GetRequestParameters(Request)["SELECTION"];

            bool hasInputGeom = false;
            if (!string.IsNullOrEmpty(GEOMETRY))
            {
                hasInputGeom = true;
            }

            //selection ima prednost pred podano geometrijo ...
            MgWktReaderWriter wktrw = new MgWktReaderWriter();
            if (!string.IsNullOrEmpty(inputSel))
            {
                MgGeometry inputGeom = MultiGeometryFromSelection(featureSrvc, map, inputSel);
                GEOMETRY = wktrw.Write(inputGeom);
            }

            MgAgfReaderWriter agfRW = new MgAgfReaderWriter();

            int nLayer = 0;
            // pobrišem in zgradim na novo samo tiste, ki imajo zadetke ...
            int nSloj = 0;
            string filter = "";
            StringBuilder sbOut = new StringBuilder();
            sbOut.Append("<table width=\"100%\" class=\"results\">");
            sbOut.Append("<tr><td class='header'></td><td class='header'>" + "Layer" + "</td><td class='header' align=\"center\">" + "Select" + "</td><td class='header' align=\"center\">" + "Report" + "</td></tr>");

            MgSelection selAll = new MgSelection(map);

            foreach (MgLayer layer in map.GetLayers())
            {
                if (type != "2")
                {
                    if (!layer.IsVisible())
                    {
                        goto nextlay;
                    }
                }

                if (layer.LegendLabel == "")
                {
                    goto nextlay;
                }

                try
                {
                    nLayer++;

                    filter = String.Format("{0} {1} GeomFromText('{2}')", layer.GetFeatureGeometryName(), selVar, GEOMETRY);

                    //preveriti še filter na Layerju. Ker ne gre drugače, je potrebno pogledati v XML
                    MgResourceIdentifier layerDefResId = layer.GetLayerDefinition();
                    MgByteReader byteReader = resourceSrvc.GetResourceContent(layerDefResId);

                    System.Xml.XmlDocument doc = new System.Xml.XmlDocument();
                    String xmlLayerDef = byteReader.ToString();
                    doc.LoadXml(xmlLayerDef);

                    KALI.MGE.Objects.KALILayerDefinition.LayerDefinition ld = KALI.MGE.Objects.KALILayerDefinition.LayerDefinition.Parse(xmlLayerDef);

                    if (!string.IsNullOrEmpty(ld.VectorLayerDefinition.Filter))
                    {
                        filter += " AND (" + ld.VectorLayerDefinition.Filter + ")";
                    }

                    //query the features
                    MgFeatureQueryOptions opts = new MgFeatureQueryOptions();
                    opts.SetFilter(filter);
                    String featureClassName = layer.GetFeatureClassName();
                    MgResourceIdentifier srcId = new MgResourceIdentifier(layer.GetFeatureSourceId());

                    MgFeatureReader features = featureSrvc.SelectFeatures(srcId, featureClassName, opts);

                    bool hasResult = features.ReadNext();

                    if (hasResult)
                    {
                        nSloj++;

                        int n = 0;

                        MgClassDefinition classDef = features.GetClassDefinition();

                        MgPropertyDefinitionCollection classDefProps = classDef.GetIdentityProperties();
                        ArrayList idPropNames = new ArrayList(classDefProps.GetCount());
                        for (int j = 0; j < classDefProps.GetCount(); j++)
                        {
                            MgPropertyDefinition idProp = classDefProps.GetItem(j);
                            idPropNames.Add(idProp.GetName());
                        }
                                                
                        MgSelection sel = new MgSelection(map);
                        do
                        {
                            // Generate XML to selection this feature
                            MgPropertyCollection idProps = new MgPropertyCollection();
                            foreach (string id in idPropNames)
                            {
                                int idPropType = features.GetPropertyType(id);
                                switch (idPropType)
                                {
                                    case MgPropertyType.Int32:
                                        idProps.Add(new MgInt32Property(id, features.GetInt32(id)));
                                        break;
                                    case MgPropertyType.String:
                                        idProps.Add(new MgStringProperty(id, features.GetString(id)));
                                        break;
                                    case MgPropertyType.Int64:
                                        idProps.Add(new MgInt64Property(id, features.GetInt64(id)));
                                        break;
                                    case MgPropertyType.Double:
                                        idProps.Add(new MgDoubleProperty(id, features.GetDouble(id)));
                                        break;
                                    case MgPropertyType.Single:
                                        idProps.Add(new MgSingleProperty(id, features.GetSingle(id)));
                                        break;
                                    case MgPropertyType.DateTime:
                                        idProps.Add(new MgDateTimeProperty(id, features.GetDateTime(id)));
                                        break;
                                    default:
                                        //throw new SearchError(String.Format(MgLocalizer.GetString("SEARCHTYYPENOTSUP", locale), new Object[] { idPropType.ToString() }), searchError);
                                        break;
                                }
                            }

                            sel.AddFeatureIds(layer, featureClassName, idProps);
                            selAll.AddFeatureIds(layer, featureClassName, idProps);

                            n++;

                            //if (n > 1000) break;
                        } while (features.ReadNext());

                        features.Close();
                        features.Dispose();

                        string selText = EscapeForHtml(sel.ToXml());
                        string seljs = "<div class=\"allLay\" onclick=\"parent.SetSelectionXML('" + selText + "');\"><img width=\"16\" height=\"16\" style=\"border:0\" src=\"images/mActionZoomToSelected.png\"/></div>";
                        string seljs3 = "<div class=\"allLay\" onclick=\"parent.MultiGridShow('" + selText + "');\"><img width=\"16\" height=\"16\" style=\"border:0\" src=\"images/mActionOpenTable.png\"/></div>";

                        string linfo = "<b>" + layer.LegendLabel + "</b><br />" + n.ToString() + " " + "Hits";
                        sbOut.Append("<tr><td class=\"results\">" + nSloj.ToString() + "</td><td class=\"results\">" + linfo + "</td><td align=\"center\" class=\"results\">" + seljs + "</td><td align=\"center\" class=\"results\">" + seljs3 + "</td></tr>");                        
                    }
                }
                catch (Exception)
                {
                    continue;
                }

            nextlay:
                continue;
            }

            sbOut.Append("</table>");

            string selAllText = EscapeForHtml(selAll.ToXml());
            string seljsAll = "<div class=\"allLay\" onclick=\"parent.SetSelectionXML('" + selAllText + "');\"><img width=\"16\" height=\"16\" style=\"border:0\" src=\"images/mActionZoomToSelected.png\"/>" + "Select All" + "</div>";
            string seljsAll3 = "<div class=\"allLay\" onclick=\"parent.MultiGridShow('" + selAllText + "');\"><img width=\"16\" height=\"16\" style=\"border:0\" src=\"images/mActionOpenTable.png\"/>" + "Report All" + "</div>";

            sbOut.Append(string.Format("<br /><table width=\"100%\" class=\"results\"><tr><td class=\"results\">{0}</td><td class=\"results\">{1}</td></tr></table>", seljsAll, seljsAll3));


            featureSrvc.Dispose();
            resourceSrvc.Dispose();

            if (nSloj > 0)
            {
                litPrebodi.Text = sbOut.ToString();
            }
            else
            {
                litPrebodiTitle.Visible = false;
                litPrebodi.Text = "<b>" + "None layer lies below the selected item/area!" + "</b>";
            }
            
            MgGeometry inGeom = wktrw.Read(GEOMETRY);
			
			double rw = map.ViewScale / Math.Sqrt(inGeom.Area);

            //koordinate
            if (hasInputGeom & rw > 400)
            {
                string output = "";

                output = pointTransformAndWriteZ(GEOMETRY, map);

                litKoordinate.Text = output;
                litKoordinateTitle.Text = "Coordinates of selected points:";
            }            
        }
    }

    string pointTransformAndWriteZ(string geom, MgMap map)
    {
        double[] x = new double[1];
        double[] y = new double[1];
        double[] z = new double[1];

        MgWktReaderWriter wktrwdmr = new MgWktReaderWriter();
        MgPoint cntr = wktrwdmr.Read(geom).Centroid;

        x[0] = cntr.Coordinate.X;
        y[0] = cntr.Coordinate.Y;
        z[0] = 0;

        StringBuilder output = new StringBuilder();
        output.Append("<table width=\"100%\" class=\"results\">");

        //WGS preko MG API
        MgCoordinateSystemFactory fact = new MgCoordinateSystemFactory();
        string wktFrom = map.GetMapSRS();

        string wktTo = "GEOGCS[\"LL84\",DATUM[\"WGS84\",SPHEROID[\"WGS84\",6378137.000,298.25722293]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.01745329251994]]";

        MgCoordinateSystem CSSource = fact.Create(wktFrom);
        MgCoordinateSystem CSTarget = fact.Create(wktTo);
        MgCoordinateSystemTransform coordTransform = fact.GetTransform(CSSource, CSTarget);

        MgGeometryFactory geomFact = new MgGeometryFactory();

        // GK                                
        //samo prvo višino zaenkrat, dokler ni enačbe za Z                               
        output.Append(String.Format("<tr><td class='header'><b>Map koordinates:</b></td><td class=\"results\"><table><tr><td><b>Y:</b></td><td>{0}</td></tr><tr><td><b>X:</b></td><td>{1}</td></tr></table></td></tr>", string.Format("{0:0.0}", x[0]), string.Format("{0:0.0}", y[0])));

        int i = 0;

        //transformacija preko MG koordinatnega sistema
        foreach (double pointX in x)
        {
            MgCoordinate coord = geomFact.CreateCoordinateXY(x[i], y[i]);
            coord = coordTransform.Transform(coord);

            x[i] = coord.X;
            y[i] = coord.Y;

            i++;
        }

        double[] xwgs = x;
        double[] ywgs = y;
        output.Append(String.Format("<tr><td class='header'><b>WGS84:</b></td><td class=\"results\"><table><tr><td><b>Lon:</b></td><td>{0}</td></tr><tr><td><b>Lat:</b></td><td>{1}</td></tr></table></td></tr>", string.Format("{0:0.000000}", xwgs[0]), string.Format("{0:0.000000}", ywgs[0])));
                
        output.Append("</table>");

        return output.ToString();
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

        MgFeatureService resourceService = (MgFeatureService)site.CreateService(MgServiceType.FeatureService);
        return resourceService;
    }

    System.Collections.Specialized.NameValueCollection GetRequestParameters(HttpRequest req)
    {
        if ("POST" == req.HttpMethod)
        {
            return req.Form;
        }
        else
        {
            return req.QueryString;
        }
    }

    MgGeometry MultiGeometryFromSelection(MgFeatureService featureSrvc, MgMap map, String selText)
    {
        MgSelection sel = new MgSelection(map);
        sel.FromXml(selText);
        MgReadOnlyLayerCollection selLayers = sel.GetLayers();
        if (selLayers == null)
            return null;
        MgGeometryCollection geomColl = new MgGeometryCollection();
        MgAgfReaderWriter agfRW = new MgAgfReaderWriter();
        bool polyOnly = true;

        for (int i = 0; i < selLayers.GetCount(); i++)
        {
            MgLayer layer = (MgLayer)selLayers.GetItem(i);

            // TODO:  How to get selectionSize?
            //int selectionSize = 20;
            string filter = sel.GenerateFilter(layer, layer.GetFeatureClassName());

            if (filter == "")
                continue;

            MgFeatureQueryOptions query = new MgFeatureQueryOptions();
            query.SetFilter(filter);
            MgResourceIdentifier featureSource = new MgResourceIdentifier(layer.GetFeatureSourceId());
            MgFeatureReader features = featureSrvc.SelectFeatures(featureSource, layer.GetFeatureClassName(), query);

            if (features != null)
            {
                MgClassDefinition classDef = features.GetClassDefinition();
                String geomPropName = classDef.GetDefaultGeometryPropertyName();
                int j = 0;
                //bool isPoly = true;
                while (features.ReadNext())
                {
                    MgByteReader geomReader = features.GetGeometry(geomPropName);
                    MgGeometry geom = agfRW.Read(geomReader);
                    if (j++ == 0)
                    {
                        int type = geom.GetGeometryType();
                        if (type == MgGeometryType.MultiPolygon || type == MgGeometryType.CurvePolygon || type == MgGeometryType.MultiCurvePolygon)
                        {
                            //isPoly = false;
                            polyOnly = false;
                        }
                        else if (type != MgGeometryType.Polygon)
                        {
                            break;
                        }
                    }
                    geomColl.Add(geom);
                }
                features.Close();
                features.Dispose();
            }

        }

        if (geomColl.GetCount() == 0)
        {
            return null;
        }

        MgGeometryFactory gf = new MgGeometryFactory();
        if (polyOnly)
        {
            MgPolygonCollection polyColl = new MgPolygonCollection();
            for (int j = 0; j < geomColl.GetCount(); j++)
            {
                polyColl.Add((MgPolygon)geomColl.GetItem(j));
            }
            return gf.CreateMultiPolygon(polyColl);
        }
        else
        {
            return gf.CreateMultiGeometry(geomColl);
        }
    }
}