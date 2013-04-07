<%@ WebHandler Language="C#" Class="PrintLegend" Debug="true" %>

// Copyright Kaliopa d.o.o., Ljubljana, Slovenia, Srečko Lipovšek
// srecko.lipovsek@kaliopa.si
// December 2012
// 

using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Drawing;
using OSGeo.MapGuide;
using System.Net;
using System.Data;
using System.IO;
using System.Drawing.Imaging;
using System.Data.SqlClient;
using System.Configuration;
using System.Globalization;
using System.Xml;

public class PrintLegend : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        string sessionId = GetRequestParameters(context.Request)["SESSION"];
        string webLayout = GetRequestParameters(context.Request)["WEBLAYOUT"];
        string mapName = GetRequestParameters(context.Request)["MAPNAME"];
        string layerReq = GetRequestParameters(context.Request)["LAYER"];
        string q = GetRequestParameters(context.Request)["q"]; // all layers ?

        if (string.IsNullOrEmpty(sessionId))
        {
            return;
        }

        if (string.IsNullOrEmpty(webLayout) && string.IsNullOrEmpty(mapName))
        {
            return;
        }

        MgResourceService resourceService = GetMgResurceService(sessionId);
        MgMappingService mapingService = GetMgMapingService(sessionId);

        MgMap map = GetCurrentMgMap(resourceService, webLayout, mapName);

        Bitmap bp = new Bitmap(300, 800);
        bp.SetResolution(300f, 300f);
        Graphics g = Graphics.FromImage(bp);
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
        g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
        g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
        g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
        g.Clear(Color.White);

        PrintLegendImage ptLp = new PrintLegendImage();

        if (string.IsNullOrEmpty(layerReq))
        {
            if (!string.IsNullOrEmpty(q))
            {
                //all layers in map
                MgLayerCollection coll = map.GetLayers();
                bp = ptLp.GenLegend(context, sessionId, resourceService, map, bp, coll.ToArray(), mapingService);
            }
            else
            {
                //visible layers
                List<MgLayerBase> coll = new List<MgLayerBase>();
                foreach (MgLayerBase item in map.GetLayers())
                {
                    if (item.IsVisible())
                    {
                        coll.Add(item);
                    }
                }
                bp = ptLp.GenLegend(context, sessionId, resourceService, map, bp, coll.ToArray(), mapingService);
            }
        }
        else
        {
            //one layer ...
            List<MgLayerBase> coll = new List<MgLayerBase>();
            coll.Add(map.GetLayers().GetItem(layerReq));
            bp = ptLp.GenLegend(context, sessionId, resourceService, map, bp, coll.ToArray(), mapingService);
        }

        resourceService.Dispose();

        //write it to output           
        System.IO.MemoryStream strOut = new System.IO.MemoryStream();
        bp.Save(strOut, ImageFormat.Png);
        //obvezen dispose
        bp.Dispose();

        byte[] byteArray = strOut.ToArray();
        strOut.Flush();
        strOut.Close();

        context.Response.Expires = -1;

        context.Response.ContentType = "image/png";
        context.Response.AppendHeader("Content-Disposition", "attachment;Filename=Legend.png");
        context.Response.OutputStream.Write(byteArray, 0, byteArray.Length);
        context.Response.OutputStream.Flush();
        context.Response.OutputStream.Close();
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

    private MgResourceService GetMgResurceService(string sessionId)
    {
        MapGuideApi.MgInitializeWebTier(HttpContext.Current.Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");
        MgUserInformation userInfo = new MgUserInformation(sessionId);
        MgSiteConnection site = new MgSiteConnection();
        site.Open(userInfo);

        MgResourceService resourceService = (MgResourceService)site.CreateService(MgServiceType.ResourceService);
        return resourceService;
    }

    private MgRenderingService GetMgRenderingService(string sessionId)
    {
        MapGuideApi.MgInitializeWebTier(HttpContext.Current.Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");
        MgUserInformation userInfo = new MgUserInformation(sessionId);
        MgSiteConnection site = new MgSiteConnection();
        site.Open(userInfo);

        MgRenderingService resourceService = (MgRenderingService)site.CreateService(MgServiceType.RenderingService);
        return resourceService;
    }

    private MgMappingService GetMgMapingService(string sessionId)
    {
        MapGuideApi.MgInitializeWebTier(HttpContext.Current.Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../webconfig.ini");
        MgUserInformation userInfo = new MgUserInformation(sessionId);
        MgSiteConnection site = new MgSiteConnection();
        site.Open(userInfo);

        MgMappingService mappingService = (MgMappingService)site.CreateService(MgServiceType.MappingService);
        return mappingService;
    }

    private MgMap GetCurrentMgMap(MgResourceService resourceService, string webLayout, string mapName)
    {
        if (!string.IsNullOrEmpty(mapName))
        {
            MgMap map2 = new MgMap();
            map2.Open(resourceService, mapName);
            return map2;
        }

        MgMap map = new MgMap();

        MgResourceIdentifier res = new MgResourceIdentifier(webLayout);

        if (res.ResourceType == MgResourceType.WebLayout)
        {
            MgWebLayout layout = new MgWebLayout(resourceService, res);
            MgResourceIdentifier res1 = new MgResourceIdentifier(layout.GetMapDefinition());

        start:

            // poskušam tako dolgo, da se map inicializira ...
            bool loaded = false;

            try
            {
                do
                {
                    map.Open(resourceService, res1.Name);
                    loaded = true;
                } while (loaded == false);
            }
            catch (Exception ex)
            {
                loaded = false;
                goto start;
            }
        }
        return map;
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
}


/// <summary>
/// Summary description for PrintLegend
/// </summary>
public class PrintLegendImage
{
    public PrintLegendImage()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public Bitmap GenLegend(HttpContext context, string sessionId, MgResourceService resourceService, MgMap map, Bitmap bp, MgLayerBase[] coll, MgMappingService mapingService)
    {
        int y = 4;
        int x = 4;

        int maxY = y;

        foreach (MgLayerBase layer in coll)
        {
            MgResourceIdentifier s = layer.LayerDefinition;
            if (layer.DisplayInLegend)
            {
                MgByteReader layerByteReader = resourceService.GetResourceContent(layer.GetLayerDefinition());
                String layerDefString = layerByteReader.ToString();
                XmlDocument doc = new XmlDocument();
                doc.LoadXml(layerDefString);

                int type = 0;
                XmlNodeList scaleRanges = doc.GetElementsByTagName("VectorScaleRange");
                if (scaleRanges.Count == 0)
                {
                    scaleRanges = doc.GetElementsByTagName("GridScaleRange");
                    if (scaleRanges.Count == 0)
                    {
                        scaleRanges = doc.GetElementsByTagName("DrawingLayerDefinition");
                        if (scaleRanges.Count == 0)
                            continue;
                        type = 2;
                    }
                    else
                        type = 1;
                }

                String[] typeStyles = new String[] { "PointTypeStyle", "LineTypeStyle", "AreaTypeStyle", "CompositeTypeStyle" };
                String[] ruleNames = new String[] { "PointRule", "LineRule", "AreaRule", "CompositeRule", "ColorRule" };

                for (int sc = 0; sc < scaleRanges.Count; sc++)
                {
                    XmlElement scaleRange = (XmlElement)scaleRanges[sc];
                    XmlNodeList minElt = scaleRange.GetElementsByTagName("MinScale");
                    XmlNodeList maxElt = scaleRange.GetElementsByTagName("MaxScale");
                    double minScale, maxScale;
                    minScale = 0;
                    maxScale = 1000000000000.0;   // as MDF's VectorScaleRange::MAX_MAP_SCALE
                    if (minElt.Count > 0)
                        minScale = double.Parse(minElt[0].ChildNodes[0].Value);
                    if (maxElt.Count > 0)
                        maxScale = double.Parse(maxElt[0].ChildNodes[0].Value);

                    if (type != 0)
                        break;

                    if (minScale < map.ViewScale && map.ViewScale < maxScale)
                    {
                        for (int ts = 0; ts < typeStyles.Length; ts++)
                        {
                            XmlNodeList typeStyle = scaleRange.GetElementsByTagName(typeStyles[ts]);
                            int catIndex = 0;
                            for (int st = 0; st < typeStyle.Count; st++)
                            {

                                XmlNodeList rules = ((XmlElement)typeStyle[st]).GetElementsByTagName(ruleNames[ts]);
                                Bitmap ptImg;

                                //Če bo po risanju y večji od bp.Height gremo v novo vrsto
                                if (bp.Height < y + 18 * 2 /*|| bp.Height < y + rules.Count * 18 + 28*/)
                                {
                                    Bitmap tmpImg = bp;
                                    bp = new Bitmap(bp.Width + 320, bp.Height);
                                    bp.SetResolution(300f, 300f);
                                    Graphics g = Graphics.FromImage(bp);
                                    g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                                    g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
                                    g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                                    g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
                                    g.Clear(Color.White);
                                    g.DrawImage(tmpImg, 0, 0);
                                    tmpImg.Dispose();

                                    y = 4;
                                    x += 320;
                                }

                                if (rules.Count > 1)
                                {
                                    ptImg = new Bitmap(HttpContext.Current.Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../stdicons/lc_theme.gif");
                                    ptImg.SetResolution(300f, 300f);

                                    y = DrawLegend(ptImg, layer.LegendLabel, bp, x, y, FontStyle.Bold, 12);
                                    ptImg.Dispose();
                                    y += 16;
                                }

                                for (int r = 0; r < rules.Count; r++)
                                {
                                    XmlElement rule = (XmlElement)rules[r];
                                    XmlNodeList label = rule.GetElementsByTagName("LegendLabel");

                                    string labelText = "";
                                    if (label != null && label.Count > 0 && label[0].ChildNodes.Count > 0)
                                        labelText = label[0].ChildNodes[0].Value;
                                    else
                                    {
                                        labelText = layer.LegendLabel;
                                    }

                                    int themecat = r - 1;
                                    if (rules.Count > 1)
                                    {
                                        themecat = r;
                                    }

                                    int testY = y;
                                    if (labelText.Length > 30)
                                    {
                                        string[] textTab = labelText.Split();
                                        string temp = "";
                                        foreach (string sa in textTab)
                                        {
                                            temp += sa + " ";
                                            if (temp.Length > 30)
                                            {
                                                temp = "";
                                                testY += 12;
                                            }
                                        }
                                    }

                                    if (bp.Height < y + 18 | bp.Height < testY + 18 /*|| bp.Height < y + rules.Count * 18 + 28*/)
                                    {
                                        Bitmap tmpImg = bp;
                                        bp = new Bitmap(bp.Width + 320, bp.Height);
                                        bp.SetResolution(300f, 300f);
                                        Graphics g = Graphics.FromImage(bp);
                                        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                                        g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
                                        g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                                        g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
                                        g.Clear(Color.White);
                                        g.DrawImage(tmpImg, 0, 0);
                                        tmpImg.Dispose();

                                        if (testY + 18 > maxY)
                                        {
                                            maxY = testY + 18;
                                        }

                                        y = 4;
                                        x += 320;
                                    }

                                    // string url = "http://" + context.Request.ServerVariables["SERVER_NAME"] + "/mapguide/mapagent/mapagent.fcgi" + "?OPERATION=GETLEGENDIMAGE&SESSION=" + sessionId +
                                    //"&VERSION=1.0.0&SCALE=" + map.ViewScale + "&LAYERDEFINITION=" + context.Server.UrlEncode(layer.GetLayerDefinition().ToString()) +
                                    //"&THEMECATEGORY=" + (themecat) + "&TYPE=" + (-1) + "&CLIENTAGENT=" + "Ajax%20Viewer";

                                    /*
                                     Parameters:
	                                        resource 	(MgResourceIdentifier) Input MgResourceIdentifier object identifying the layer definition resource. 
	                                        scale 	(double) Input The scale at which the symbolization is requested. 
	                                        width 	(int) Input The requested image width in pixels. 
	                                        height 	(int) Input The requested image height in pixels. 
	                                        format 	(String/string) Input Image format, from MgImageFormats. Example: PNG, JPG, PNG8, etc ? 
	                                        geomType 	(int) Input The type of symbolization required: 1=Point, 2=Line, 3=Area, 4=Composite 
	                                        themeCategory 	(int) Input The value indicating which theme category swatch to return. Used when there is a theme defined at this scale. An exception will be thrown if a requested them category doesn't exist.
                                    */

                                    int geomType = 1;
                                    if (typeStyles[ts].ToUpper().Contains("POINT"))
                                    {
                                        geomType = 1;
                                    }
                                    if (typeStyles[ts].ToUpper().Contains("LINE"))
                                    {
                                        geomType = 2;
                                    }
                                    if (typeStyles[ts].ToUpper().Contains("AREA"))
                                    {
                                        geomType = 3;
                                    }
                                    if (typeStyles[ts].ToUpper().Contains("COMPOSITE"))
                                    {
                                        geomType = 4;
                                    }

                                    catIndex++;
                                    try
                                    {
                                        MgByteReader imgL = mapingService.GenerateLegendImage(layer.LayerDefinition, map.ViewScale, 16, 16, "PNG8", geomType, themecat);

                                        int lng = (int)imgL.GetLength();

                                        MemoryStream memBuff = new MemoryStream();
                                        byte[] byteBuffer = new byte[lng];

                                        int intBytes = imgL.Read(byteBuffer, lng);

                                        while (intBytes > 0)
                                        {
                                            memBuff.Write(byteBuffer, 0, intBytes);
                                            intBytes = imgL.Read(byteBuffer, lng);
                                        }

                                        ptImg = new Bitmap(memBuff);
                                        ptImg.SetResolution(300f, 300f);
                                    }
                                    catch
                                    {
                                        ptImg = new Bitmap(HttpContext.Current.Request.ServerVariables["APPL_PHYSICAL_PATH"] + "../stdicons/lc_theme.gif");
                                        ptImg.SetResolution(300f, 300f);
                                    }

                                    if (rules.Count > 1)
                                    {
                                        y = DrawLegend(ptImg, labelText, bp, x + 20, y, FontStyle.Regular, 10);
                                        ptImg.Dispose();
                                        y += 17;
                                    }
                                    else
                                    {
                                        y = DrawLegend(ptImg, labelText, bp, x, y, FontStyle.Bold, 12);
                                        ptImg.Dispose();
                                        y += 18;
                                    }

                                    if (y > maxY)
                                    {
                                        maxY = y;
                                    }
                                }

                                if (y > maxY)
                                {
                                    maxY = y;
                                }
                            }
                        }
                    }
                }
            }
        }

        //Če bo po risanju maxY manjši od bp.Height odrežem sliko ...
        if (bp.Height > maxY && x < 350)
        {
            Bitmap tmpImg = bp;
            bp = new Bitmap(bp.Width, maxY);
            bp.SetResolution(300f, 300f);
            Graphics g = Graphics.FromImage(bp);
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
            g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
            g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
            g.Clear(Color.White);

            g.DrawImage(tmpImg, 0, 0);
            tmpImg.Dispose();
        }

        return bp;
    }

    private int DrawLegend(Bitmap img, string text, Bitmap bp, int x, int y, FontStyle fs, int fontSize)
    {
        Graphics g = Graphics.FromImage(bp);
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
        g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.High;
        g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
        //g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;

        g.DrawImage(img, x, y);
        if (text.Length > 30)
        {
            string[] textTab = text.Split();
            string temp = "";
            foreach (string s in textTab)
            {
                temp += s + " ";
                if (temp.Length > 30)
                {
                    g.DrawString(temp, new Font("Tahoma", fontSize, fs, GraphicsUnit.Pixel), SystemBrushes.WindowText, new Point(x + 20, y));
                    temp = "";
                    y += 12;
                }
            }
            if (!temp.Trim().Equals(""))
                g.DrawString(temp, new Font("Tahoma", fontSize, fs, GraphicsUnit.Pixel), SystemBrushes.WindowText, new Point(x + 20, y));
            else y -= 12;
        }
        else
        {
            g.DrawString(text, new Font("Tahoma", fontSize, fs, GraphicsUnit.Pixel), SystemBrushes.WindowText, new Point(x + 20, y));
        }
        return y;
    }

    public static int mmToPixMg(double mm, int dpi)
    {
        return Convert.ToInt32(mm / 25.4 * dpi);
    }
}