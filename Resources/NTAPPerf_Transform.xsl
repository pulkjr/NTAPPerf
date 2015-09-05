<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:decimal-format name="us" decimal-separator='.' grouping-separator=',' />
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <html>
        <head>
          <script>
            <![CDATA[
            function removeEmptyTables(){

              var table = document.getElementsByTagName("table");
              for(var i=0;i<table.length;i++){
                if(table[i].querySelectorAll("td[bgcolor]").length<1)
                {
                  table[i].className = 'hidden';
                }
                else{
                  var rows = document.getElementsByTagName("tr");

                  for(var i=0;i<rows.length;i++){
                    cells = rows[i].querySelectorAll("td[bgcolor]");
                    if(cells.length==0){
                      if(rows[i].parentElement.nodeName=="TBODY"){
                        rows[i].className = 'hidden';
                      }
                    }
                  }
                }
              }
            }
            function expandRows(theElement){
              if(theElement.parentElement.querySelectorAll("tr[style='display: none;']")){
                theNodes = theElement.parentElement.querySelectorAll("tbody > tr");
                for(var i=0;i<theNodes.length;i++){
                  if(theNodes[i].className == 'hidden'){
                    theNodes[i].className = 'shown';
                  }
                  else{
                    if(theNodes[i].className == 'shown'){
                      theNodes[i].className = 'hidden';

                    }
                  }
                }
              }
            }
            function expandTable(theElement){
              if(theElement.querySelectorAll("Table")){
                theNodes = theElement.querySelectorAll("table");
                for(var i=0;i<theNodes.length;i++){
                  if(theNodes[i].className == 'hidden'){
                    theNodes[i].className = 'shown';
                  }
                  else{
                    if(theNodes[i].className == 'shown'){
                      theNodes[i].className = 'hidden';

                    }
                  }
                }
              }
            }
            ]]>
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
            .NTAPPerf thead th{
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
              PADDING-TOP:20px;
              PADDING-BOTTOM:0;
            	FONT-SIZE: 28px;
            	MARGIN-BOTTOM: 0;
            	COLOR: #5196EE;
            	FONT-FAMILY: Arial;
            	WIDTH: 700;
              Height:30px;
              line-height:30px;
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
              text-align: left;
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
            .shown{

            }
            .carrot{
              font-size:8px;
              font-family:Arial;
              font-weight:normal;
              vertical-align:middle;
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
              <span>Developed By: Joseph</span>
            </div>
          </div>
        </body>
    </html>
  </xsl:template>
  <xsl:template match="Category">
    <span>
      <div class="h2_header" style="WIDTH: 700; text-align: left;" onclick="expandTable(this.parentElement)">
          <xsl:attribute name="title">Click to see more details on the <xsl:value-of select="@Name"/> information. </xsl:attribute>
          <xsl:value-of select="@Name"/> Details  &#10095;
      </div>
      <xsl:apply-templates select="Instance"/>
    </span>
  </xsl:template>
  <xsl:template match="Instance">
    <div class="NTAPPerf">
      <Table>
        <thead>
          <tr id="Instance" onclick="expandRows(this.parentElement)">
            <xsl:attribute name="title">Click to see more details on the instance of: <xsl:value-of select="@Name"/> </xsl:attribute>
            <td colspan="5">Instance: <xsl:value-of select="@Name"/>  &#10095;</td>
          </tr>
          <tr>
            <th style="width:10px" title="Utilization, Saturation, Errors">USE</th>
            <th>Counter Name</th>
            <th title="The Mean minus standard deviation">Min</th>
            <th title="Sum of values divided by the count of itterations.">Mean</th>
            <th title="The Mean plus standard deviation">Max</th>
          </tr>
        </thead>
        <tbody>

          <xsl:apply-templates select="Utilization/Counter"/>
          <xsl:apply-templates select="Saturation/Counter"/>
          <xsl:apply-templates select="Error/Counter"/>
        </tbody>
      </Table>
    </div>

  </xsl:template>
  <xsl:template match="Utilization/Counter">
    <tr>
      <td style="width:10px" title="Utilization">U</td>
      <td>
        <xsl:attribute name="title"><xsl:value-of select="@Desc"/></xsl:attribute>
        <xsl:value-of select="@Name"/>
      </td>
      <td>
        <xsl:attribute name="title"><xsl:value-of select="format-number(@Mean_Value, '###,###.00;(###,###.00)', 'us')"/>-<xsl:value-of select="format-number(@SD, '###,###.00;(###,###.00)', 'us')"/> SD</xsl:attribute>
        <xsl:value-of select="format-number(@Min, '###,###.00;(###,###.00)', 'us')"/>&#160;<xsl:value-of select="@unit"/>
      </td>
      <td><xsl:value-of select="format-number(@Mean_Value, '###,###.00;(###,###.00)', 'us')"/>&#160;<xsl:value-of select="@unit"/></td>
      <td><xsl:value-of select="format-number(@Max, '###,###.00;(###,###.00)', 'us')"/>&#160;<xsl:value-of select="@unit"/></td>
    </tr>
  </xsl:template>
  <xsl:template match="Saturation/Counter">
    <tr>
      <td style="width:10px" title="Saturation">S</td>
      <td>
        <xsl:attribute name="title"><xsl:value-of select="@Desc"/></xsl:attribute>
        <xsl:value-of select="@Name"/>
      </td>
      <td>
        <xsl:attribute name="title"><xsl:value-of select="format-number(@Mean_Value, '###,###.00;(###,###.00)', 'us')"/>-<xsl:value-of select="format-number(@SD, '###,###.00;(###,###.00)', 'us')"/> SD</xsl:attribute>
        <xsl:value-of select="format-number(@Min, '###,###.00;(###,###.00)', 'us')"/>&#160;<xsl:value-of select="@unit"/>
      </td>
      <td>
        <xsl:if test="(@unit='microsec')">
          <xsl:if test="(@Mean_Value &gt; 10000)">
            <xsl:attribute name="bgcolor">#F1655C</xsl:attribute>
            <xsl:attribute name="title">The saturation of this resource is above 10ms. This is an indicator of a problem getting serious</xsl:attribute>
          </xsl:if>
          <xsl:if test="((@Mean_Value &gt;= 1000) and (@Mean_Value &lt;= 10000))">
            <xsl:attribute name="bgcolor">#F4A71C</xsl:attribute>
            <xsl:attribute name="title">The saturation of this resource is above 1ms. This may indicate the start of a problem.</xsl:attribute>
          </xsl:if>
        </xsl:if>
        <xsl:if test="(@unit='millisec')">
          <xsl:if test="(@Mean_Value &gt; 10)">
            <xsl:attribute name="bgcolor">#F1655C</xsl:attribute>
            <xsl:attribute name="title">The saturation of this resource is above 10ms. This is an indicator of a problem getting serious</xsl:attribute>
          </xsl:if>
          <xsl:if test="((@Mean_Value &gt;= 1) and (@Mean_Value &lt;= 10))">
            <xsl:attribute name="bgcolor">#F4A71C</xsl:attribute>
            <xsl:attribute name="title">The saturation of this resource is above 1ms. This may indicate the start of a problem.</xsl:attribute>
          </xsl:if>
        </xsl:if>
        <xsl:value-of select="format-number(@Mean_Value, '###,###.00;(###,###.00)', 'us')"/>&#160;<xsl:value-of select="@unit"/></td>
      <td><xsl:value-of select="format-number(@Max, '###,###.00;(###,###.00)', 'us')"/>&#160;<xsl:value-of select="@unit"/></td>
    </tr>
  </xsl:template>
  <xsl:template match="Error/Counter">
    <tr>
      <td style="width:10px" title="Error">E</td>
      <td>
        <xsl:attribute name="title"><xsl:value-of select="@Desc"/></xsl:attribute>
        <xsl:value-of select="@Name"/>
      </td>
      <td>
        <xsl:attribute name="title"><xsl:value-of select="format-number(@Mean_Value, '###,###.00;(###,###.00)', 'us')"/>-<xsl:value-of select="format-number(@SD, '###,###.00;(###,###.00)', 'us')"/> SD</xsl:attribute>
        <xsl:value-of select="format-number(@Min, '###,###.00;(###,###.00)', 'us')"/>
      </td>
      <td>
        <xsl:if test="(@SD &gt; 10)">
          <xsl:attribute name="bgcolor">#F1655C</xsl:attribute>
          <xsl:attribute name="title">The errors present indicate a serious problem</xsl:attribute>
        </xsl:if>
        <xsl:if test="((@SD &lt;= '1') and (@SD &gt;= '10'))">
          <xsl:attribute name="bgcolor">#F4A71C</xsl:attribute>
          <xsl:attribute name="title">The errors present indicate a problem</xsl:attribute>
        </xsl:if>
        <xsl:value-of select="format-number(@Mean_Value, '###,###.00;(###,###.00)', 'us')"/>
      </td>
      <td><xsl:value-of select="format-number(@Max, '###,###.00;(###,###.00)', 'us')"/></td>
    </tr>
  </xsl:template>
</xsl:stylesheet>
