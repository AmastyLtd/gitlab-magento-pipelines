#!/usr/bin/env python3
import json, argparse, sys, re, os, subprocess
from typing import List
from pathlib import Path

def exception_handler(kind, message, traceback):
    print('{0}: {1}'.format(kind.__name__, message))

def main():
    parser = argparse.ArgumentParser("require_processor")
    parser.add_argument("-v", "--verbose", help="increase output verbosity",
                        action="store_true")

    if not parser.parse_args().verbose:
        sys.excepthook = exception_handler

    exec_composer(process_directories(str(Path().absolute()) + "/app/code"))

def process_directories(directory):
    packages = []

    for item in Path(directory).rglob('composer.json'):
        packages += parse_composer(item.absolute())

    return packages

def parse_composer(composerFile) -> List[str]:
    composer_json = json.load(open(composerFile, "r"))
    requires = composer_json['require']
    vendor_name = composer_json['name'].split('/')[0]

    if 'amasty' != vendor_name:
        vendor_name += "|amasty"

    regex = re.compile("php|magento|"+vendor_name)
    packages = []

    for package,version in requires.items():
        if not regex.match(package):
            if '*' == version:
                packages +=[package]
            else:
                packages +=[package+":"+version]

    return packages


def exec_composer(packages):
    if not packages:
        print('There is nothing to install. Exit!')
        exit()

    composer_env = os.environ.copy()
    composer_env["COMPOSER_MEMORY_LIMIT"] = "-1"

    process = subprocess.Popen(['composer', 'require']+packages, stdout=subprocess.PIPE, env=composer_env)
    process.wait()

main()
