<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:x="http://www.w3.org/1999/xhtml">

  <xsl:output method="text" encoding="UTF-8" indent="no" />

  <xsl:template match="/">
    <xsl:variable name="assets" select="plist/dict/key[.='Assets'][1]/following-sibling::*[1][self::array]" />

    <xsl:for-each select="$assets/dict">
      <xsl:variable name="asset.version" select="key[.='_CompatibilityVersion'][1]/following-sibling::*[1][self::integer]" />
      <xsl:variable name="asset.name" select="key[.='DictionaryPackageDisplayName'][1]/following-sibling::*[1][self::string]" />
      <xsl:variable name="asset.bundle" select="key[.='DictionaryPackageName'][1]/following-sibling::*[1][self::string]" />
      <xsl:variable name="asset.size" select="key[.='_DownloadSize'][1]/following-sibling::*[1][self::integer]" />
      <xsl:variable name="checksum.type" select="key[.='_MeasurementAlgorithm'][1]/following-sibling::*[1][self::string]" />
      <xsl:variable name="checksum.base64" select="key[.='_Measurement'][1]/following-sibling::*[1][self::data]" />
      <xsl:variable name="url.base" select="key[.='__BaseURL'][1]/following-sibling::*[1][self::string]" />
      <xsl:variable name="url.path" select="key[.='__RelativePath'][1]/following-sibling::*[1][self::string]" />

      <xsl:value-of select="concat($asset.version, '&#9;', $asset.size)" />
      <xsl:text>&#9;</xsl:text>
      <xsl:value-of select="concat($checksum.type, '&#9;', normalize-space($checksum.base64))" />
      <xsl:text>&#9;</xsl:text>
      <xsl:value-of select="concat($url.base, '&#9;', $url.path)" />
      <xsl:text>&#9;</xsl:text>
      <xsl:value-of select="concat($asset.bundle, '&#9;', normalize-space($asset.name))" />
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
