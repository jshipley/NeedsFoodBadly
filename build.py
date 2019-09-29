import glob
import os
import shutil
from zipfile import ZipFile

from jinja2 import Environment, FileSystemLoader
from pynt import task

ADDON_DIR = r'C:/Program Files (x86)/World of Warcraft/_classic_/Interface/AddOns/NeedsFoodBadly'

TESTING = False
VERSION = None

interface = '11302'
files = [
    'main.lua',
    'data.lua'
]
testfiles = ['tests.lua']

@task()
def clean():
    if os.path.isdir('dist'):
        shutil.rmtree('dist')

@task()
def v(version):
    '''Set the add-on version'''
    global VERSION
    VERSION = version

@task()
def test():
    global TESTING
    TESTING = True

@task(v)
def toc():
    '''Generate toc file'''
    if not os.path.isdir('dist'):
        os.mkdir('dist')
    with open(os.path.join('dist', 'NeedsFoodBadly.toc'), 'w') as tocfile:
        tocfile.write(FileSystemLoader('.')
            .load(Environment(trim_blocks=True), 'NeedsFoodBadly.toc.j2')
            .render(interface=interface, version=VERSION, files=files, testfiles=testfiles if TESTING else []))

@task(clean, toc)
def _dist():
    if not os.path.isdir('dist'):
        os.mkdir('dist')
    for f in files:
        shutil.copy(f, 'dist')
    print(TESTING)
    if TESTING:
        for f in testfiles:
            shutil.copy(f, 'dist')

def _distfiles():
    return ['NeedsFoodBadly.toc'] + files + (testfiles if TESTING else [])

@task(_dist, v)
def zipfile():
    z = ZipFile(os.path.join('dist', 'NeedsFoodBadly-{}.zip'.format(VERSION)), 'w')
    for f in _distfiles():
        z.write(os.path.join('dist', f), os.path.join('NeedsFoodBadly', f))

@task(_dist)
def local():
    if TESTING:
        print('  Copying NeedsFoodBadly to Interface/Addons -- TEST MODE')
    else:
        print('  Copying NeedsFoodBadly to Interface/Addons')
    if not os.path.isdir(ADDON_DIR):
        os.makedirs(ADDON_DIR)
    for f in glob.glob(os.path.join(ADDON_DIR, '*')):
        os.remove(f)
    for f in _distfiles():
        shutil.copy(os.path.join('dist', f), ADDON_DIR)
