<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Intersect.aspx.cs" Inherits="m_Intersect"
    ValidateRequest="false" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <title></title>
    <style type="text/css">
        td.Title
        {
            font-family: Tahoma;
            font-weight: bold;
            font-size: 11pt;
        }
        td.SubTitle
        {
            font-family: Tahoma;
            font-weight: bold;
            font-size: 9pt;
            background-color: #DCDCDC;
            color: black;
            height: 20px;
        }
        .results
        {
            border-color: black;
            border-width: 1px 1px 1px 1px;
            border-style: solid;
            border-collapse: collapse;
        }
        .header
        {
            border-color: black;
            border-width: 1px 1px 1px 1px;
            border-style: solid;
            border-collapse: collapse;
            background-color: #DCDCDC;
            font-weight: bold;
        }
        body, html
        {
            font-family: Tahoma;
            font-size: 9pt;
        }
        div.allLay
        {
            font-family: Tahoma;
            font-size: 9pt;
            position: relative;
            font-weight: bold;
            text-decoration: underline;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div id="contentdiv">
        <form id="form1" runat="server">
        <div>
            <asp:Panel ID="pnl1" runat="server">
                <table class="RegText" width="100%">
                    <tr>
                        <td class="Title">
                            The data under the indicated point/range
                        </td>
                    </tr>
                    <tr>
                        <td class="SubTitle">
                            Under the indicated point lie groups of data on which you can obtain more detailed information
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <br />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <b><asp:Literal ID="litPrebodiTitle" runat="server" Text="The list of contents below the selected point/range:"></asp:Literal></b>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Literal ID="litPrebodi" runat="server"></asp:Literal>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <br />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <b><asp:Literal ID="litKoordinateTitle" runat="server"></asp:Literal></b>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Literal ID="litKoordinate" runat="server"></asp:Literal>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <br />
                        </td>
                    </tr>
                    
                </table>
            </asp:Panel>
        </div>
        </form>
    </div>
</body>
</html>
