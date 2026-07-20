# -*- coding: utf-8 -*-
import argparse
import sys
import os.path

# Prefer bundled dependencies shipped with this utility.
_BUNDLE_SITE_PACKAGES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "lib", "site-packages")
sys.path.insert(0, _BUNDLE_SITE_PACKAGES)
if os.path.isdir(_BUNDLE_SITE_PACKAGES):
    for _entry in os.listdir(_BUNDLE_SITE_PACKAGES):
        if _entry.endswith('.egg'):
            sys.path.insert(0, os.path.join(_BUNDLE_SITE_PACKAGES, _entry))

import markdown
from jinja2 import Template
import logging
#import importlib
logger = logging.getLogger('MARKDOWN')
logger.setLevel(logging.ERROR)
#logger.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler(sys.stdout)
logger.addHandler(console_handler)
#importlib.reload(sys)
#sys.setdefaultencoding('utf8')
#import translations
LANG_STRINGS = {
    'CONFIDENTIAL' :
        { 'eng' : 'Confidential', 'rus' : 'Конфиденциально' },
    'TABLE_OF_CONTENTS' :
        { 'eng' : 'Table of Contents', 'rus' : 'Содержание' },
}
LANG_DETECTION = [
    (".rus.md", "rus"),
    (".eng.md", "eng"),
    (None, "eng"), # default
]

# to include in bundle
from markdown_include.include import MarkdownInclude
#import markdown_include.include
import mdx_grid_tables
import mdx_del_ins
import mdx_subscript
import mdx_superscript
import mdx_figure_caption
import mdx_markdown_checklist
import mdx_cite

from markdown.treeprocessors import Treeprocessor
from markdown.extensions import Extension
class ImgExtractor(Treeprocessor):
    def run(self, doc):
        "Find all images and append to markdown.images. "
        self.markdown.images = []
        for image in doc.findall('.//img'):
            self.markdown.images.append(image.get('src'))

# Then tell markdown about it

class ImgExtExtension(Extension):
    def extendMarkdown(self, md, md_globals):
        img_ext = ImgExtractor(md)
        md.treeprocessors.add('imgext', img_ext, '>inline')

# Finally create an instance of the Markdown class with the new extension

desc= """Convert Markdown to HTML

Templates can be applied to the output for wrapping into valid xhtml 
documents or generating page headers, footers or covers for PDF for 
assembly with other tools.

Following additional Python packages are required:
    Jinja2 templating engine (pip install Jinja2)
    Python Markdown (pip install markdown)
    Pygments (pip install pygments)
    
The resulting documents can be assembled into PDF using wkhtml2pdf tool.
"""

parser= argparse.ArgumentParser(description= desc, formatter_class= argparse.RawTextHelpFormatter)
parser.add_argument("-o",action="append",dest="out",metavar="outfile",type=argparse.FileType("w"),help="Output unwrapped output to file <outfile>",default=[])
parser.add_argument("-b",action="store",dest="basedir",metavar="basedir",help="Documentation source base directory",default='.')
parser.add_argument("-d",action="store",dest="outdir",metavar="outdir",help="Documentation target directory",default='.')
parser.add_argument("-t",action="append",nargs=2,dest="tout",metavar=("infile","outfile"),help="Output wrapped output to file <outfile> using template <infile>")
parser.add_argument("-x",action="append",dest="extensions",metavar="extension",help="Additional Markdown extensions to load")
parser.add_argument("infile",help="Input Markdown file name")
parser.add_argument("-p",action="append",nargs=2,dest="params",metavar=("name","value"),help="Additional parameter for templating")

args= parser.parse_args()
print((args.infile))
infile = open(args.infile, "rb")

def decode(s):
    if isinstance(s, str):
        return s
    for encoding in [ "utf-8-sig", "utf-8" ] :
        try:
            return s.decode(encoding)
        except UnicodeDecodeError:
            continue
    return s.decode("latin-1")

# open template input and output files
templated= []
if args.tout:
    for (tin,tout) in args.tout:
        try:
            ftin= argparse.FileType("r")(tin)
            ftout= argparse.FileType("w")(tout)
            templated.append((ftin,ftout))
        except Exception as e:
            parser.error(e)

output=os.path.join(os.path.abspath(args.outdir),os.path.relpath(args.infile,args.basedir))
if len(args.out)>0:
    output=args.out[0].name

markdown_include = MarkdownInclude(configs={'basedir':os.path.abspath(args.basedir),'outdir':os.path.abspath(args.outdir),'input':args.infile, 'output':output})
# compose list of extensions to load and initialize Markdown engine
extensions= [
    markdown_include,
    "mdx_cite",
    "markdown.extensions.attr_list",
    "markdown.extensions.def_list",
    "markdown.extensions.fenced_code",
    "markdown.extensions.footnotes",
    "markdown.extensions.tables",
    "markdown.extensions.codehilite",
    "markdown.extensions.meta",
    "markdown.extensions.toc",
    "mdx_grid_tables",
    "mdx_del_ins", # must go before mdx_subscript
    "mdx_subscript",
    "mdx_superscript",
    "mdx_figure_caption",
    "mdx_markdown_checklist", # magicked name, see Makefile
    ImgExtExtension(),
]

extension_configs= {
    'mdx_cite': {
        'BIBFILE': os.environ.get('BIBFILE'),
        'OVERRIDE_BIBFILE': os.environ.get('OVERRIDE_BIBFILE'),
        'EXT_BIBFILE': os.environ.get('EXT_BIBFILE')
    },
}

if args.extensions: extensions+= args.extensions
md= markdown.Markdown(extensions=extensions,extension_configs=extension_configs)

# run Markdown engine
#text= infile.read()
text= decode(infile.read())
html= md.convert(text)
from urllib.parse import urlparse
import os.path
missing_images=[]
for iurl in getattr(md, 'images', []):
    result=urlparse(iurl)
    if not result.netloc and result.path:
        if result.path not in missing_images:
#            if not os.path.isfile(result.path):
            # report all files to allow top level wrapper manage files
            missing_images.append(result.path)
#ParseResult(scheme='http', netloc='cvs.konts.lv', path='/cs_versions/cs.platform.WG/cs.pkg.Level1_A', params='', query='sadasdasd', fragment='')

# write output to unwrapped output files
for ofile in args.out: ofile.write(html)
# If no explicit output targets are provided, write HTML to stdout.
if not args.out and not templated:
    sys.stdout.write(html)
    if not html.endswith('\n'):
        sys.stdout.write('\n')
# create a copy of metadata and add new params from command line
params= md.Meta.copy()
if args.params:
    for (name,value) in args.params: params[name]= value
# add the generated HTML as a template argument
params["html"]= html

lang= None
for langdet in LANG_DETECTION:
    if not langdet[0] or args.infile.endswith(langdet[0]):
        lang= langdet[1]
        break
def translate(id):
    if not lang: return "{{ {} }}".format(id)
    try: return LANG_STRINGS[id][lang]
    except KeyError:
        raise RuntimeError("String with id=<{}> does not have translation to language <{}>".format(id, lang))
params["translate"]= translate

# conjure all required templated output files
for ifile,ofile in templated:
    tmpl= Template(ifile.read())
    s = tmpl.render(**params)
    if not s.endswith('\n'): s += '\n'
    ofile.write(s)

for f in missing_images:
    print("image:%s"%f)
