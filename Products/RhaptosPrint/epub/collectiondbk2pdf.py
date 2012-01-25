# python -c "import collectiondbk2pdf; print collectiondbk2pdf.__doStuff('./tests', 'modern-textbook');" > result.pdf

import sys
import os
import Image
from StringIO import StringIO
from tempfile import mkdtemp
import subprocess

from lxml import etree
import urllib2

import module2dbk
import collection2dbk
import util

DEBUG= 'DEBUG' in os.environ

XHTML_PATH = '/usr/local/bin/prince'
if 'XHTML_PATH' in os.environ:
  XHTML_PATH = os.environ['XHTML_PATH']
BASE_PATH = os.getcwd()
#PRINT_STYLE='modern-textbook' # 'modern-textbook-2column'

# XSL files
DOCBOOK2XHTML_XSL=util.makeXsl('dbk2xhtml.xsl')
DOCBOOK_CLEANUP_XSL = util.makeXsl('dbk-clean-whole.xsl')

MODULES_XPATH = etree.XPath('//col:module/@document', namespaces=util.NAMESPACES)
IMAGES_XPATH = etree.XPath('//c:*/@src[not(starts-with(.,"http:"))]', namespaces=util.NAMESPACES)

def __doStuff(dir, printStyle):
  collxml = etree.parse(os.path.join(dir, 'collection.xml'))
  
  moduleIds = MODULES_XPATH(collxml)
  
  modules = {} # {'m1000': (etree.Element, {'file.jpg':'23947239874'})}
  allFiles = {}
  for moduleId in moduleIds:
    print >> sys.stderr, "LOG: Starting on %s" % (moduleId)
    moduleDir = os.path.join(dir, moduleId)
    if os.path.isdir(moduleDir):
      cnxml, files = loadModule(moduleDir)
      for f in files:
        allFiles[os.path.join(moduleId, f)] = files[f]

      modules[moduleId] = (cnxml, files)

  dbk, newFiles = collection2dbk.convert(collxml, modules, svg2png=False, math2svg=True)
  allFiles.update(newFiles)
  pdf, stdErr = convert(dbk, allFiles, printStyle)
  return pdf

def __doStuffModule(moduleId, dir, printStyle):
  cnxml, files = loadModule(dir)
  _, newFiles = module2dbk.convert(moduleId, cnxml, files, {}, svg2png=False, math2svg=True) # Last arg is coll params
  dbkStr = newFiles['index.standalone.dbk']
  dbk = etree.parse(StringIO(dbkStr))
  allFiles = {}
  allFiles.update(files)
  allFiles.update(newFiles)
  pdf, stdErr = convert(dbk, allFiles, printStyle)
  return pdf

def loadModule(moduleDir):
  """ Given a directory of files (containing an index.cnxml) 
      load it into memory """
  # Try autogenerated CNXML 1st
  cnxmlPath = os.path.join(moduleDir, 'index_auto_generated.cnxml')
  if not os.path.exists(cnxmlPath):
    cnxmlPath = os.path.join(moduleDir, 'index.cnxml')
  cnxmlStr = open(cnxmlPath).read()
  cnxml = etree.parse(StringIO(cnxmlStr))
  files = {}
  for f in IMAGES_XPATH(cnxml):
    try:
      data = open(os.path.join(moduleDir, f)).read()
      files[f] = data
      #print >> sys.stderr, "LOG: Image ADDED! %s %s" % (module, f)
    except IOError:
      print >> sys.stderr, "LOG: Image not found %s %s" % (os.path.basename(moduleDir), f)
  return (cnxml, files)

def xhtml2pdf(xhtml, files, tempdir, printStyle):
  """ Convert XHTML and assorted files to PDF using a XHTML+CSS to PDF script """
  # Write all of the files into tempdir
  for fname, content in files.items():
    fpath = os.path.join(tempdir, fname)
    fdir = os.path.dirname(fpath)
    if not os.path.isdir(fdir):
      os.makedirs(fdir)
    #print >> sys.stderr, "LOG: Writing to %s" % fpath
    f = open(fpath, 'w')
    f.write(content)
    f.close()
  
  CSS_FILE = os.path.join(BASE_PATH, 'css/%s.css' % printStyle)
  
  # Run Prince (or an Opensource) to generate an abstract tree 1st
  strCmd = [XHTML_PATH, '-v', '--style=%s' % CSS_FILE, '--output=%s' % '/dev/stdout', '/dev/stdin']

  env = { }

  # run the program with subprocess and pipe the input and output to variables
  p = subprocess.Popen(strCmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True, env=env)
  # set STDIN and STDOUT and wait untill the program finishes
  pdf, stdErr = p.communicate(etree.tostring(xhtml))
  if DEBUG:
    open('temp-collection5.pdf','w').write(pdf)

  # Clean up the tempdir
  # Remove added files
  if not DEBUG:
    for fname in files:
      fpath = os.path.join(tempdir, fname)
      os.remove(fpath)
      fdir = os.path.dirname(fpath)
      if len(os.listdir(fdir)) == 0:
        os.rmdir(fdir)

  return pdf, stdErr

def convert(dbk1, files, printStyle):
  """ Converts a Docbook Element and a dictionary of files into a PDF. """
  tempdir = mkdtemp(suffix='-fo2pdf')

  def transform(xslDoc, xmlDoc):
    """ Performs an XSLT transform and parses the <xsl:message /> text """
    ret = xslDoc(xmlDoc, **({'cnx.output.fop': '1', 'cnx.tempdir.path':"'%s'" % tempdir}))
    for entry in xslDoc.error_log:
      # TODO: Log the errors (and convert JSON to python) instead of just printing
      print >> sys.stderr, entry
    return ret

  # Step 0 (Sprinkle in some index hints whenever terms are used)
  # termsprinkler.py $DOCBOOK > $DOCBOOK2
  if DEBUG:
    open('temp-collection1.dbk','w').write(etree.tostring(dbk1,pretty_print=True))

  # Step 1 (Cleaning up Docbook)
  dbk2 = transform(DOCBOOK_CLEANUP_XSL, dbk1)
  if DEBUG:
    open('temp-collection2.dbk','w').write(etree.tostring(dbk2,pretty_print=True))

  # Step 2 (Docbook to XHTML)
  xhtml = transform(DOCBOOK2XHTML_XSL, dbk2)
  if DEBUG:
    open('temp-collection3.xhtml','w').write(etree.tostring(xhtml))

  #import pdb; pdb.set_trace()
  # Step 4 Converting XSL:FO to PDF (using Apache FOP)
  # Change to the collection dir so the relative paths to images work
  pdf, stdErr = xhtml2pdf(xhtml, files, tempdir, printStyle)
  #os.rmdir(tempdir)
  
  return pdf, stdErr
