<?xml			version="1.0"
				encoding="UTF-8"?>
<xsl:stylesheet	version="2.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:outline="http://wkhtmltopdf.org/outline"
				xmlns="http://www.w3.org/1999/xhtml">
<xsl:output		doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
				doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
				indent="yes" />
<xsl:template	match="outline:outline">

<html>
<head>
<title>Table of Contents</title>
<meta			http-equiv="Content-Type"
				content="text/html; charset=utf-8" />
<style>
* {
	margin: 0;
	padding: 0;
}
body {
	padding: 0px 20px;
}

.toc {
	text-align: center;
	font-size: 30px;
	font-family: 'Roboto';
	color: #2a2a2a;
}

ol {
	counter-reset: item;
	font-size: 1em;
	font-family: 'Roboto';
	padding-left: 0;
}

ol ol {
	padding-left: 13px;
}

li {
	list-style: none;
	display: list-item;
	padding-top: 8px;
}

li:before {
	display: inline-block;
	content: counters(item, ".");
	counter-increment: item;
	padding-right: 10px;
	margin-left: 0;
	color: #2a2a2a;
}

li a {
	text-decoration: none;
	padding-right: 6px;
	color: #2a2a2a;
}

li span {
	float: right;
	padding-left: 6px;
	color: #2a2a2a;
}



</style>
</head>
<body>
	<div class="toc">Table of Contents</div>
	<ol><xsl:apply-templates select="outline:item/outline:item"/></ol>
</body>
</html>
</xsl:template>

<xsl:template match="outline:item">
<li>
	<xsl:if test="@title!=''">
		<a>
			<xsl:if test="@link">
				<xsl:attribute name="href">
					<xsl:value-of select="@link"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@backLink">
				<xsl:attribute name="name">
					<xsl:value-of select="@backLink"/>
				</xsl:attribute>
			</xsl:if><xsl:value-of select="@title" />
		</a>
		<span><xsl:value-of select="@page" /></span>
	</xsl:if>
	<ol>
		<xsl:comment>added to prevent self-closing tags in QtXmlPatterns</xsl:comment>
		<xsl:apply-templates select="outline:item"/>
	</ol>
</li>
</xsl:template>
</xsl:stylesheet>
