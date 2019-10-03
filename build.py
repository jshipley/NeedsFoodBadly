import glob
import os
import shutil
from zipfile import ZipFile

from jinja2 import Environment, FileSystemLoader
from pynt import task

ADDON_DIR = r'C:/Program Files (x86)/World of Warcraft/_classic_/Interface/AddOns/NeedsFoodBadly'

VERSION = None

interface = '11302'

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
def tests():
    if os.system('busted') > 0:
        raise Exception('unit tests failed')

@task(v)
def toc():
    '''Generate toc file'''
    if not os.path.isdir('dist'):
        os.mkdir('dist')
    with open(os.path.join('dist', 'NeedsFoodBadly.toc'), 'w') as tocfile:
        tocfile.write(FileSystemLoader('.')
            .load(Environment(trim_blocks=True), 'NeedsFoodBadly.toc.j2')
            .render(interface=interface, version=VERSION))

@task(clean, toc)
def _dist():
    if not os.path.isdir('dist'):
        os.mkdir('dist')
    for f in glob.glob('*.lua'):
        shutil.copy(f, 'dist')
    shutil.copy('README.md', 'dist')

@task(tests, v, _dist)
def zipfile():
    z = ZipFile(os.path.join('dist', 'NeedsFoodBadly-{}.zip'.format(VERSION)), 'w')
    for f in glob.glob(os.path.join('dist', '*')):
        if os.path.splitext(f)[1] == '.zip':
            continue
        z.write(f, os.path.join('NeedsFoodBadly', os.path.relpath(f, 'dist')))

@task(_dist)
def local():
    print('  Copying NeedsFoodBadly to Interface/Addons')
    if not os.path.isdir(ADDON_DIR):
        os.makedirs(ADDON_DIR)
    for f in glob.glob(os.path.join(ADDON_DIR, '*')):
        os.remove(f)
    for f in glob.glob(os.path.join('dist', '*')):
        shutil.copy(f, ADDON_DIR)
