<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY dspace-ont "http://swig.hpclab.ceid.upatras.gr/dspace-ont/">
<!ENTITY dcterms "http://purl.org/dc/terms/">
<!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
<!ENTITY lom "http://ltsc.ieee.org/xsd/LOM/">
]>
<!--

  - transformer.xslt



  - @ dc:hasVersion   1.5

  - @ dc:date         2014-04-22

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
  					  
  - @ dc:description  1.2: Assign proper URIs to Collections in case handle is disabled.
                                        Enable UNA for collections by using these URIs as uniqueName.
                                        Use these URIs as collection entity IRIs.
                                        Assign xsd:dateTime datatype for dcterms:available and dcterms:dateAccepted.             				
             
  - @ dc:description  1.3: Fix for subject types that have absolute IRIs.

  

  - @ dc:description  1.4: Distinguish between collections and communities.

                                      Revamp mimetype format reification (instances of dcterms:FileFormat class).

 
 
 - @ dc:description  1.5: Inject DBpedia URLs for dcterms:type types, authors, contributors, sponsors

                                      


  
  
  - @ dc:rights       University of Patras, High Performance Information Systems Laboratory (HPCLab)

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:dspace-ont="http://swig.hpclab.ceid.upatras.gr/dspace-ont/" xmlns:dspace-ont-old="http://ippocrates.hpclab.ceid.upatras.gr:8998/dc-ont/dspace-ont.owl#" xmlns:lom="http://ltsc.ieee.org/xsd/LOM/" xmlns="http://www.w3.org/2002/07/owl#" version="2.0" exclude-result-prefixes="xsl xsi oai oai_dc dspace-ont-old">
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
      <Literal>
        <xsl:value-of select="oai:header/oai:identifier"/>
      </Literal>
    </DataPropertyAssertion>
    <xsl:apply-templates select="oai:header/oai:setSpec"/>
    <xsl:apply-templates select="oai:metadata"/>
  </xsl:template>
  <xsl:template match="oai:setSpec">
    <!-- 
    Attempt to assign a URI to the Collection. First check if handle system is enabled (other than the default 123456789). 
    If not, try and guess canonical URL prefix from item identifier. Use this URI as dspace-ont:uniqueName for the Collection
    -->
    <xsl:variable name="handle" select="substring-after(node(), '_')"/>
    <xsl:variable name="item-handle" select="../../oai:metadata/dcterms:identifier[contains(.,'/handle/') and @type='http://www.w3.org/2001/XMLSchema#anyURI']"/>
    <xsl:variable name="collection-identifier">
      <xsl:choose>
        <xsl:when test="substring-before($handle, '_')!='123456789'"><xsl:text>http://hdl.handle.net/</xsl:text><xsl:value-of select="substring-before($handle,'_')"/>/<xsl:value-of select="substring-after($handle,'_')"/></xsl:when>
        <xsl:otherwise>
          <xsl:if test="$item-handle!=''"><xsl:value-of select="substring-before($item-handle, '/handle/')"/><xsl:text>/handle/</xsl:text><xsl:value-of select="substring-before($handle,'_')"/>/<xsl:value-of select="substring-after($handle,'_')"/></xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Is this a collection or community?-->
    <xsl:variable name="element">
      <xsl:choose>
        <xsl:when test="substring-before(node(),'_')='com'">
          <xsl:text>dspace-ont:Community</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>dspace-ont:Collection</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="collection-iri">
      <xsl:choose>
        <xsl:when test="$collection-identifier!=''">
          <xsl:value-of select="$collection-identifier"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>dspace-ont:</xsl:text>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <NamedIndividual IRI="{$collection-iri}"/>
    <ClassAssertion>
      <Class abbreviatedIRI="{$element}"/>
      <NamedIndividual IRI="{$collection-iri}"/>
    </ClassAssertion>
    <!-- sibling communities may be parents of the current collection or the current (sub-) community. Cannot

        make safe assumptions however, due to item mapping

    <xsl:for-each select="preceding-sibling::oai:setSpec[contains(., 'com')] | following-sibling::oai:setSpec[contains(., 'com')]">

      <ObjectPropertyAssertion>

      <ObjectProperty abbreviatedIRI="dcterms:isPartOf"/>

      <NamedIndividual IRI="{$collection-iri}"/>

      <NamedIndividual IRI=""/>

    </ObjectPropertyAssertion>

    </xsl:for-each>

  -->
    <ObjectPropertyAssertion>
      <ObjectProperty abbreviatedIRI="dcterms:isPartOf"/>
      <NamedIndividual IRI="{../oai:identifier}"/>
      <NamedIndividual IRI="{$collection-iri}"/>
    </ObjectPropertyAssertion>
    <xsl:if test="$collection-identifier!=''">
      <DataPropertyAssertion>
        <DataProperty abbreviatedIRI="dcterms:identifier"/>
        <NamedIndividual IRI="{$collection-iri}"/>
        <Literal datatypeIRI="http://www.w3.org/2001/XMLSchema#anyURI">
          <xsl:value-of select="$collection-identifier"/>
        </Literal>
      </DataPropertyAssertion>
      <DataPropertyAssertion>
        <DataProperty abbreviatedIRI="dspace-ont:uniqueName"/>
        <NamedIndividual IRI="{$collection-iri}"/>
        <Literal>
          <xsl:value-of select="$collection-identifier"/>
        </Literal>
      </DataPropertyAssertion>
    </xsl:if>
  </xsl:template>
  <xsl:template match="dcterms:contributor | dspace-ont:author | dspace-ont-old:author" priority="1">
    <xsl:variable name="lang" select="substring(@xml:lang,1,2)"/>
    <xsl:variable name="value" select="."/>
    <xsl:variable name="value2" select="translate($value,',','_')"/>
    <xsl:variable name="dbvalue" select="normalize-space(translate($value,',',' '))"/>
    <xsl:variable name="element" select="name()"/>
    <ObjectPropertyAssertion>
      <ObjectProperty abbreviatedIRI="{$element}"/>
      <NamedIndividual IRI="{../../oai:header/oai:identifier}"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
    </ObjectPropertyAssertion>
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="dspace-ont:uniqueName"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
      <Literal>
        <xsl:value-of select="translate($value2,' ','')"/>
      </Literal>
    </DataPropertyAssertion>
  <!-- Inject DBpedia URI for authors, contributors-->   
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="foaf:page"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
      <Literal>
        <xsl:attribute name="datatypeIRI">
          <xsl:text>http://www.w3.org/2001/XMLSchema#anyURI</xsl:text>
        </xsl:attribute>
        <xsl:text>http://www.dbpedia.org/resource/</xsl:text>
        <xsl:value-of select="translate($value2,' ','')"/>
      </Literal>
    </DataPropertyAssertion>
    
    <xsl:choose>
      <xsl:when test="contains($value, ',')">
        <DataPropertyAssertion>
          <DataProperty abbreviatedIRI="foaf:name"/>
          <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
          <Literal xml:lang="{$lang}">
            <xsl:value-of select="normalize-space(substring-after($value, ','))"/>
          </Literal>
        </DataPropertyAssertion>
        <DataPropertyAssertion>
          <DataProperty abbreviatedIRI="foaf:surname"/>
          <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value2,' ','')}"/>
          <Literal xml:lang="{$lang}">
            <xsl:value-of select="normalize-space(substring-before($value, ','))"/>
          </Literal>
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
      <Literal>
        <xsl:value-of select="translate($value,' ','_')"/>
      </Literal>
    </DataPropertyAssertion>
    <!--	<xsl:for-each select="../dspace-ont:sponsorship[@xml:lang!='']">     -->
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="rdfs:label"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value,' ','_')}"/>
      <Literal xml:lang="{$lang}">
        <xsl:value-of select="."/>
      </Literal>
    </DataPropertyAssertion>
    <!-- 	</xsl:for-each>      -->
    <!--</xsl:if>-->
  <!-- Inject DBpedia URI for sponsors-->   
    <DataPropertyAssertion>
      <DataProperty abbreviatedIRI="foaf:page"/>
      <NamedIndividual abbreviatedIRI="dspace-ont:{translate($value,' ','_')}"/>
      <Literal>
        <xsl:attribute name="datatypeIRI">
          <xsl:text>http://www.w3.org/2001/XMLSchema#anyURI</xsl:text>
        </xsl:attribute>
        <xsl:text>http://www.dbpedia.org/resource/</xsl:text>
        <xsl:value-of select="translate($value,' ','_')"/>
      </Literal>
    </DataPropertyAssertion>  
  </xsl:template>
  <xsl:template match="oai:metadata/*">
    <xsl:variable name="type" select="@type"/>
    <xsl:variable name="prefix">
      <!-- The following exception is only for dcterms:subject fields that have a classification scheme as type. 
              It won't matter if these types get a dcterms: prefix (e.g. dcterms:DDC).
              However, there is the case where the value may be an absolute IRI (without prefix), like a handle.
              -->
      <xsl:choose>
        <xsl:when test="contains(.,'http://')">
          <NamedIndividual IRI="{.}"/>
        </xsl:when>
        <!-- revamp mimetype reification. Should find a workaround for charset specification

            in text formats, that comes after the colon. For now it is kept in the label.

            

        -->
        <xsl:when test="contains($type,'dspace-ont:MimeType')">
          <xsl:choose>
            <xsl:when test="contains(., ';') and contains(., '/')">
              <NamedIndividual abbreviatedIRI="dspace-ont:{substring-before(substring-after(.,'/'), ';')}"/>
            </xsl:when>
            <xsl:when test="contains(., '/') and not(contains(., ';'))">
              <NamedIndividual abbreviatedIRI="dspace-ont:{substring-after(.,'/')}"/>
            </xsl:when>
            <xsl:otherwise>
              <NamedIndividual abbreviatedIRI="dspace-ont:{normalize-space(translate(.,'  ','_ '))}"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <NamedIndividual abbreviatedIRI="{substring-before($type, ':')}:{normalize-space(translate(.,'  ','_ '))}"/>
        </xsl:otherwise>
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
          <xsl:copy-of select="$prefix"/>
        </ObjectPropertyAssertion>
        <ClassAssertion>
          <Class abbreviatedIRI="{$type}"/>
          <xsl:copy-of select="$prefix"/>
        </ClassAssertion>
        <DataPropertyAssertion>
          <DataProperty abbreviatedIRI="rdfs:label"/>
          <xsl:copy-of select="$prefix"/>
          <Literal>
            <xsl:if test="$lang!=''">
              <xsl:attribute name="lang">
                <xsl:value-of select="$lang"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:value-of select="."/>
          </Literal>
        </DataPropertyAssertion>
      
       <!-- Inject DBpedia URI currently, only for dcterms:type types --> 
    <xsl:if test="$element='dcterms:type'">
        <DataPropertyAssertion>
          <DataProperty abbreviatedIRI="foaf:page"/>
          <xsl:copy-of select="$prefix"/>
          <Literal>
              <xsl:attribute name="datatypeIRI">
                <xsl:text>http://www.w3.org/2001/XMLSchema#anyURI</xsl:text>
              </xsl:attribute>
            http://dbpedia.org/resource/<xsl:value-of select="translate(.,' ','_')"/>
          </Literal>
        </DataPropertyAssertion>
      </xsl:if>
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
            <xsl:if test="$element='dcterms:available' or $element='dcterms:dateAccepted'">
              <xsl:attribute name="datatypeIRI">
                <xsl:text>http://www.w3.org/2001/XMLSchema#dateTime</xsl:text>
              </xsl:attribute>
            </xsl:if>
            <xsl:value-of select="."/>
          </Literal>
        </DataPropertyAssertion>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
