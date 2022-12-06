#!/usr/bin/env python3
import jinja2
import os
import argparse
import sys


class App:
    __debug = False
    __web = False
    __mydumper = False
    __alpine = True

    __php_version = "8.1"
    __composer_version = 2
    __php_mem_limit = "4G"

    def __init__(self, debug: bool = False) -> None:
        sys.excepthook = self.__exception_handler
        self.__debug = debug

    def debug(self, flag: bool) -> None:
        self.__debug = flag

    def web(self, flag: bool) -> None:
        self.__web = flag

    def mydumper(self, flag: bool) -> None:
        self.__mydumper = flag

    def alpine(self, flag: bool) -> None:
        self.__alpine = flag

    def php_version(self, version: str) -> None:
        self.__php_version = version

    def composer_version(self, version: int) -> None:
        self.__composer_version = version

    def php_memory_limit(self, limit: str) -> None:
        self.__php_mem_limit = limit

    def is_web(self) -> bool:
        return self.__web
    
    def is_mydumper(self) -> bool:
        return self.__mydumper

    def is_alpine(self) -> bool:
        return self.__alpine

    def get_php_version(self) -> str:
        return self.__php_version

    def get_composer_version(self) -> int:
        return self.__composer_version

    def get_php_memory_limit(self) -> str:
        return self.__php_mem_limit

    def __exception_handler(self, kind, message, traceback) -> None:
        if self.__debug:
            sys.__excepthook__(kind, message, traceback)
        else:
            print("{0}: \033[1m{1}\033[0m".format(kind.__name__, message))

parser = argparse.ArgumentParser(description="Build a Dockerfile for a PHP application")

parser.add_argument(
    "php_version", help="PHP version", action="store", metavar="PHP_VER"
)
parser.add_argument(
    "-v", "--verbose", help="increase output verbosity", action="store_true"
)
parser.add_argument(
    "--web", help="Include NGINX & PHP-FPM", action="store_true"
)
parser.add_argument(
    "--mydumper", help="Include mydumper", action="store_true"
)
parser.add_argument(
    "--alpine", help="Use Alpine Linux", action="store_true", default=True
)
parser.add_argument(
    "--composer-version", help="Configure Composer version", type=float, default=2.2, metavar="VER"
)
parser.add_argument(
    "--php-memory-limit", help="Configure PHP memory_limit", type=str, default="4G", metavar="LIMIT"
)
args = parser.parse_args()

app = App()
app.debug(args.verbose)
app.web(args.web)
app.mydumper(args.mydumper)
app.alpine(args.alpine)
app.php_version(args.php_version)
app.composer_version(args.composer_version)
app.php_memory_limit(args.php_memory_limit)

tpl = jinja2.Environment(loader=jinja2.FileSystemLoader("php"), trim_blocks=True).get_template("Dockerfile.j2")

result = tpl.render({
    'base_image': "php:{version}{fpm}{alpine}".format(version = app.get_php_version(), fpm = "-fpm" if app.is_web() else "", alpine = "-alpine" if app.is_alpine() else ""),
    'composer_version_branch': app.get_composer_version(),
    'image_version': os.getenv("CI_COMMIT_SHORT_SHA"),
    'php_memory_limit': app.get_php_memory_limit(),
    'web': app.is_web(),
    'include_mydumper': app.is_mydumper(),
    'php_version': app.get_php_version(),
    'user': 'worker',
})

print(result)
