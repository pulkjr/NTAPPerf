<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <html>
        <head>
          <script>
          </script>
          <style>
            Body{
              Background-Color:#F8F8F8;
            }
            .MainBody Div{
              width: 100%;

              /* Firefox */
              display:-moz-box;
              -moz-box-pack:center;
              -moz-box-align:center;

              /* Safari and Chrome */
              display:-webkit-box;
              -webkit-box-pack:center;
              -webkit-box-align:center;

              /* W3C */
              display:box;
              box-pack:center;
              box-align:center;
            }
            .NTAPPerf div{
            	margin:0;
              padding:0;
            	width:700;
            	border:0 solid #D9D9D9;
              background-color:#FFFFFF;
            }
            .NTAPPerf table{
                border-collapse: collapse;
                    border-spacing: 0;
            	width:700;
            	margin:0;padding:0;
            }

            .NTAPPerf tbody tr:nth-child(odd){
              background-color:#FFFFF;
              BORDER-BOTTOM: #808184 1px solid;
            }
            .NTAPPerf tbody tr:nth-child(even){
              background-color:#E5E5E5;
              BORDER-BOTTOM: #808184 1px solid;
            }

            .NTAPPerf tbody td{
            	vertical-align:middle;
            	border:1px solid #808184;
            	border-width:0px 0px 1px 0px;
            	text-align:left;
            	padding:7px;
            	font-size:10;
            	font-family:Arial;
            	font-weight:normal;
            	color:#000000;
              width:175;
            }
            .NTAPPerf tbody th{
            	vertical-align:middle;
            	border:1px solid #808184;
            	border-width:0px 0px 1px 0px;
              background-color:#FFFFFF;
            	text-align:left;
            	padding:7px;
              height:20px;
            	font-size:11px;
            	font-family:Arial;
            	font-weight:bold;
            	color:#000000;
              width:175;
              text-transform: uppercase;
            }
            .NTAPPerf #Instance{
              background-color:#808184;
              color:E6E7E8;
              font-size:18px;
              font-family:Arial;
              font-weight:bold;
              BORDER-BOTTOM: #D9D9D9 1px solid;
              text-align:left;
              TEXT-INDENT: 10;
            }
            .h1_header{
              display: table;
              margin: 0 auto;
              PADDING-TOP:2px;
              PADDING-BOTTOM:0;
            	FONT-SIZE: 28px;
            	MARGIN-BOTTOM: 0;
            	COLOR: #5196EE;
            	FONT-FAMILY: Arial;
            	WIDTH: 700;
              Height:30px;
            	TEXT-INDENT: 10;
            	BACKGROUND-COLOR: #F2F2F2;
              text-transform: capitalize;

            }
            .h2_header{
              display: table;
              margin: 0 auto;
              FONT-WEIGHT: bold;
              FONT-SIZE: 18pt;
              MARGIN-BOTTOM: 0;

              COLOR: #FFFFFF;
              FONT-FAMILY: Arial;
              WIDTH: 700;
              TEXT-INDENT: 10;
              text-transform: capitalize;
              BACKGROUND-COLOR: #0077BF;
            }
            .footer{
              display: table;
              margin: 0 auto;
              height:50px;
              line-height:50px;
              background-color:#E5E5E5;
              color:#454545;
              POSITION: relative;
              font-size:11px;
            	font-family:Arial;
            	font-weight:normal;
              text-align:left;
              TEXT-INDENT: 10;
              vertical-align:middle;
            }
            .hidden{
              display: none;
            }
          </style>
          <title>NTAPPerf Report</title>
        </head>
        <body onload="removeEmptyTables()">
          <div class="MainBody">
            <div class="h1_header" style="WIDTH: 700;">NTAP Performance Module Report</div>
            <xsl:apply-templates select="Category"/>
            <xsl:apply-templates/>
            <div class="footer" style="WIDTH: 700">
              <span>Developed By: Joseph Pulk</span>
            </div>
          </div>
        </body>
    </html>
  </xsl:template>
  <xsl:template match="Category">
    <div class="h2_header" style="WIDTH: 700"><xsl:value-of select="@Name"/> Details </div>
      <xsl:apply-templates select="Instance"/>
  </xsl:template>
  <xsl:template match="Instance">
    <div class="NTAPPerf">
      <Table>
        <thead>
          <tr id="Instance">
            <td colspan="4">Instance: <xsl:value-of select="@Name"/></td>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th>Counter Name</th>
            <th >Min</th>
            <th >Mean</th>
            <th >Max</th>
          </tr>

          <xsl:apply-templates select="Utilization/Counter"/>
          <xsl:apply-templates select="Saturation/Counter"/>
          <xsl:apply-templates select="Error/Counter"/>
        </tbody>
      </Table>
    </div>

  </xsl:template>
  <xsl:template match="Utilization/Counter">
    <tr>
      <td><xsl:value-of select="@Name"/></td>
      <td><xsl:value-of select="@Min"/></td>
      <td><xsl:value-of select="@Mean_Value"/></td>
      <td><xsl:value-of select="@Max"/></td>
    </tr>
  </xsl:template>
  <xsl:template match="Saturation/Counter">
    <tr>
      <td><xsl:value-of select="@Name"/></td>
      <td><xsl:value-of select="@Min"/></td>
      <td><xsl:value-of select="@Mean_Value"/></td>
      <td><xsl:value-of select="@Max"/></td>
    </tr>
  </xsl:template>
  <xsl:template match="Error/Counter">
    <tr>
      <td><xsl:value-of select="@Name"/></td>
      <td><xsl:value-of select="@Min"/></td>
      <td><xsl:value-of select="@Mean_Value"/></td>
      <td><xsl:value-of select="@Max"/></td>
    </tr>
  </xsl:template>
</xsl:stylesheet>
