<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY dspace-ont "http://swig.hpclab.ceid.upatras.gr/dspace-ont/">
<!ENTITY dcterms "http://purl.org/dc/terms/">
<!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
<!ENTITY lom "http://ltsc.ieee.org/xsd/LOM/">
]>
<!--

  - transformer.xslt



  - @ dc:hasVersion   1.1

  - @ dc:date         2012-02-20

  - @ dc:creator      Dimitrios Koutsomitropoulos

  - @ dc:description  Implements the transformation of the OAI QDC output to the DSpace OWL 2 ontology

  - @ dc:description  1.01: Only single language metadata are now supported 

  - @ dc:description  1.02: Enforce Unique Name Assumption for Items, Authors, Sponsors

  - @ dc:description  1.03: Use xsl:text to avoid unneccessary spaces (e.g. collection identifier). 
                                          Reify dcterms classification types.
                                          Pretty-printing issues with non-breaking chars.
                                          Truncate lang tags (en_US to simply en) for HerMiT compatibility.
                                          Remove xsd:language for FaCT++ compatibility.
                                          Consider and replace old namespace dspace-ont-old for nemertes compatibility.

  - @ dc:description  1.04: Retract AllDifferent Axioms for UNA, because they don't scale (e.g. Pellet).
  				          Introduce instead functional dspace-ont:uniqueName for Items and Authors.
    
  - @ dc:description  1.1: Rewrite XLST to output OWL/XML instead of RDF. This way punned properties appear to be saved.
  					  dspace-ont namespace change.
  					  
  
  - @ dc:rights       University of Patras, High Performance Information Systems Laboratory (HPCLab)

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:dspace-ont="http://swig.hpclab.ceid.upatras.gr/dspace-ont/" xmlns:dspace-ont-old="http://ippocrates.hpclab.ceid.upatras.gr:8998/dc-ont/dspace-ont.owl#" xmlns:lom="http://ltsc.ieee.org/xsd/LOM/" version="2.0" xmlns="http://www.w3.org/2002/07/owl#" exclude-result-prefixes="xsl xsi oai oai_dc dspace-ont-old">
  <xsl:output method="xml" indent="yes"/>
  <xsl:variable name="langCount" select="1"/>
  <xsl:template match="/">
    <Ontology>
      <Prefix name="dspace-ont" IRI="http://swig.hpclab.ceid.upatras.gr/dspace-ont/"/>
      <Prefix name="dcterms" IRI="http://purl.org/dc/terms/"/>
      <Prefix name="rdf" IRI="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
      <Prefix name="rdfs" IRI="http://www.w3.org/2000/01/rdf-schema#"/>
      <Prefix name="foaf" IRI="http://xmlns.com/foaf/0.1/"/>
      <Prefix name="lom" IRI="http://ltsc.ieee.org/xsd/LOM/"/>
      <Prefix name="dc" IRI="http://purl.org/dc/elements/1.1/"/>
      <Import>http://swig.hpclab.ceid.upatras.gr/dspace-ont/dspace-ont.owl</Import>
      <Import>http://swig.hpclab.ceid.upatras.gr/dspace-ont/lom.owl</Import>
      <!--<Import>http://purl.org/dc/terms/</Import>-->
      <xsl:apply-templates select="oai:OAI-PMH/oai:ListRecords/oai:record"/>
      <!--<xsl:apply-templates select="/" mode="UNA"/>-->
    </Ontology>
  </xsl:template>
  
  <xsl:template match="oai:record" priority="1">
   <NamedIndividual IRI="{oai:header/oai:identifier}"/>
    <ClassAssertion>
      <Class abbreviatedIRI="dspace-ont:Item"/>
      <NamedIndividual IRI="{oai:header/oai:identifier}"/>
    </ClassAssertion>
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="dspace-ont:uniqueName"/>
      <NamedIndividual IRI="{oai:header/oai:identifier}"/>
      <Literal><xsl:value-of select="oai:header/oai:identifier"/></Literal>
    </DataPropertyAssertion>
    <xsl:apply-templates select="oai:header/oai:setSpec"/>
    <xsl:apply-templates select="oai:metadata"/>
  </xsl:template>
  
  <xsl:template match="oai:setSpec">
  <NamedIndividual abbreviatedIRI="dspace-ont:{.}"/>
    <xsl:variable name="handle" select="substring-after(node(), '_')"/>
    <ClassAssertion>
      <Class abbreviatedIRI="dspace-ont:Collection"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{.}"/>
    </ClassAssertion>
    <ObjectPropertyAssertion>
      <ObjectProperty abbreviatedIRI="dcterms:isPartOf"/>
      <NamedIndividual IRI="{../oai:identifier}"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{.}"/>
    </ObjectPropertyAssertion>
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="dcterms:identifier"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{.}"/>
      <Literal datatypeIRI="http://www.w3.org/2001/XMLSchema#anyURI">
      <xsl:text>http://hdl.handle.net/</xsl:text><xsl:value-of select="substring-before($handle,'_')"/>/<xsl:value-of select="substring-after($handle,'_')"/>
      </Literal>
    </DataPropertyAssertion>
</xsl:template>



<xsl:template match="dcterms:contributor | dspace-ont:author | dspace-ont-old:author" priority="1">
    <xsl:variable name="lang" select="substring(@xml:lang,1,2)"/>
    <xsl:variable name="value" select="."/>
    <xsl:variable name="value2" select="translate($value,',','_')"/>
    <xsl:variable name="element" select="name()"/>

   
   <ObjectPropertyAssertion>
     <ObjectProperty abbreviatedIRI="{$element}"/>
     <NamedIndividual IRI="{../../oai:header/oai:identifier}"/>
     <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
   </ObjectPropertyAssertion>
   
   <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="dspace-ont:uniqueName"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
      <Literal><xsl:value-of select="translate($value2,' ','')"/></Literal>
   </DataPropertyAssertion> 
   
   <xsl:choose>
    <xsl:when test="contains($value, ',')"> 
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="foaf:name"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
      <Literal xml:lang="{$lang}"><xsl:value-of select="normalize-space(substring-after($value, ','))"/></Literal>
   </DataPropertyAssertion> 
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="foaf:surname"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
      <Literal xml:lang="{$lang}"><xsl:value-of select="normalize-space(substring-before($value, ','))"/></Literal>
   </DataPropertyAssertion> 
    </xsl:when>
  </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dspace-ont:sponsorship | dspace-ont-old:sponsorship" priority="1">
    <xsl:variable name="value" select="."/>
    <xsl:variable name="lang" select="substring(@xml:lang,1,2)"/>
    <!--<xsl:if test="self::*[not(preceding-sibling::dspace-ont:sponsorship[.!=''])]">-->
    <ObjectPropertyAssertion>
      <ObjectProperty abbreviatedIRI="dspace-ont:sponsorship"/>
     <NamedIndividual IRI="{../../oai:header/oai:identifier}"/>
     <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value,' ','_')}"/>
    </ObjectPropertyAssertion>
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="dspace-ont:uniqueName"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value,' ','_')}"/>
      <Literal><xsl:value-of select="translate($value,' ','_')"/></Literal>
    </DataPropertyAssertion>
<!--	<xsl:for-each select="../dspace-ont:sponsorship[@xml:lang!='']">     -->    
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="rdfs:label"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value,' ','_')}"/>
      <Literal xml:lang="{$lang}"><xsl:value-of select="."/></Literal>
    </DataPropertyAssertion>
            <!-- 	</xsl:for-each>      -->
    <!--</xsl:if>-->
  </xsl:template>
  

  
  
 <xsl:template match="oai:metadata/*">
    <xsl:variable name="type" select="@type"/>
    <xsl:variable name="prefix">
      <xsl:choose>
       <xsl:when test="contains($type,'dcterms:')">dspace-ont:</xsl:when>
       <xsl:otherwise><xsl:value-of select="substring-before($type, ':')"/>:</xsl:otherwise>
     </xsl:choose>
    </xsl:variable>
    <xsl:variable name="element" select="name()"/>
    <xsl:variable name="value" select="."/>
    <xsl:variable name="lang" select="substring(@xml:lang,1,2)"/>
    

    
      <xsl:choose>
        <xsl:when test="contains($type,'dcterms:') or contains($type,'lom:') or contains($type,'dspace-ont:')">
          <ObjectPropertyAssertion>
            <ObjectProperty abbreviatedIRI="{$element}"/>
            <NamedIndividual IRI="{../../oai:header/oai:identifier}"/>
            <NamedIndividual abbreviatedIRI="{$prefix}{normalize-space(translate(.,'  ','_ '))}"/>
          </ObjectPropertyAssertion>
          <ClassAssertion>
            <Class abbreviatedIRI="{$type}"/>
            <NamedIndividual abbreviatedIRI="{$prefix}{normalize-space(translate(.,'  ','_ '))}"/>
          </ClassAssertion>
          <DataPropertyAssertion>
            <DataProperty abbreviatedIRI="rdfs:label"/>
            <NamedIndividual abbreviatedIRI="{$prefix}{normalize-space(translate(.,'  ','_ '))}"/>
            <Literal>
            <xsl:if test="$lang!=''">
             <xsl:attribute name="lang">
             <xsl:value-of select="$lang"/>
             </xsl:attribute>
             </xsl:if>
            <xsl:value-of select="."/>
            </Literal>
          </DataPropertyAssertion>
          </xsl:when>
        
<!-- Hack to exclude xsd:language datatypes that FaCT++ 1.5.2 would complain about -->        
         <xsl:when test="$type!='http://www.w3.org/2001/XMLSchema#language' and $type!=''">
             <DataPropertyAssertion>
             <DataProperty abbreviatedIRI="{$element}"/>
             <NamedIndividual IRI="{../../oai:header/oai:identifier}"/>
            <Literal>
            <xsl:if test="$lang!=''">
             <xsl:attribute name="lang">
             <xsl:value-of select="$lang"/>
             </xsl:attribute>
             </xsl:if>
             <xsl:attribute name="datatypeIRI">
             <xsl:value-of select="$type"/>
             </xsl:attribute>
            <xsl:value-of select="."/>
            </Literal>
           </DataPropertyAssertion>
         </xsl:when>
         <xsl:otherwise>
              <DataPropertyAssertion>
             <DataProperty abbreviatedIRI="{$element}"/>
             <NamedIndividual IRI="{../../oai:header/oai:identifier}"/>
            <Literal>
            <xsl:if test="$lang!=''">
             <xsl:attribute name="lang">
             <xsl:value-of select="$lang"/>
             </xsl:attribute>
             </xsl:if>
            <xsl:value-of select="."/>
            </Literal>
           </DataPropertyAssertion>
         </xsl:otherwise>
       </xsl:choose> 
  </xsl:template>
        
  
</xsl:stylesheet>