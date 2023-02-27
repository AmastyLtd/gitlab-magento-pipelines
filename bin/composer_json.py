#!/usr/bin/env python

import json
import os
import sys
import re
from typing import Union

import jsonschema
from jsonschema import validate
import gitlab
import semantic_version as sv

ALLOW_PHP_VERSIONS = ["^7.3.0", ">=7.3.0", ">=7.3", ">=7.4", ">=7.4.0", ">=8.1", ">=8.1.0"]
ALLOW_TYPES = ["magento2-module", "magento2-theme", "library", "metapackage"]
ALLOWED_LICENSES = ["proprietary", "MIT", "GPL-3.0"]
BASE_PROJECT_ID = 212


class ColoredOutput:
    """Class for colored print."""
    WARN = "\033[93m"
    FAIL = "\033[91m"
    GREEN = "\033[92m"
    END = "\033[0m"

    @staticmethod
    def green(message: str):
        """Print green message."""
        print(f"{ColoredOutput.GREEN}{message}{ColoredOutput.END}")

    @staticmethod
    def warn(message: str):
        """Print yellow message."""
        print(f"{ColoredOutput.WARN}{message}{ColoredOutput.END}")

    @staticmethod
    def fail(message: str):
        """Print red message."""
        print(f"{ColoredOutput.FAIL}{message}{ColoredOutput.END}")


def print_validation_error(
    field: str,
    current_value: str = None,
    msg: str = None,
    possible_values: Union[str, list, dict] = None
) -> None:
    """Print validation error message in special format."""
    ColoredOutput.fail(f"- Field: {field}")
    ColoredOutput.fail(f"  Message: {'Structure of the field does not comply with the standard' if msg is None else msg}")

    if current_value is not None:
        ColoredOutput.fail(f"  Current value: {current_value}")

    if isinstance(possible_values, str):
        print("  Should be:")
        ColoredOutput.green(f"    \"{field}\": \"{possible_values}\"")
    elif isinstance(possible_values, list):
        print("  Possible values:")

        for value in possible_values:
            ColoredOutput.green(f"    \"{field}\": \"{value}\"")
    elif isinstance(possible_values, dict):
        print("  Should be:")
        ColoredOutput.green(json.dumps(possible_values,  indent=2).strip('{}'))


# pylint: disable=unused-argument
def exception_handler(kind, message, traceback):
    """Function that overrides default exception output according to verbose option."""
    print(f"{ColoredOutput.FAIL}{kind.__name__}: {message}{ColoredOutput.END}", file=sys.stderr)


sys.excepthook = exception_handler

if __name__ == "__main__":
    ERROR_COUNT = 0

    print()

    try:
        with open("composer.json", mode="r", encoding="utf-8") as json_file:
            local_composer = json.load(json_file)
    except OSError:
        ColoredOutput.fail("Cannot load local composer.json file.")
        sys.exit(1)

    if os.getenv("COMPOSER_DISABLE_SCHEMA_VALIDATION") is None:
        with open(os.path.dirname(os.path.abspath(__file__)) + "/../assets/schema.json", "r", encoding="utf-8") as file:
            execute_api_schema = json.load(file)
        try:
            validate(instance=local_composer, schema=execute_api_schema)
        except jsonschema.exceptions.ValidationError as err:
            print("Schema validation result:")
            ColoredOutput.fail("Given composer.json doesn't match its schema!")
            ColoredOutput.warn(err.message)
            print()
            ERROR_COUNT += 1

    if os.getenv("COMPOSER_DISABLE_VERSION_CHECK") is None:
        version_validator = re.compile(r'^\d+\.\d+\.\d+(?:-(dev|(patch|beta|p)-?\d+))?$')

        if not version_validator.search(local_composer.get("version", "")):
            print_validation_error("version", local_composer.get("version", "empty"))
            ERROR_COUNT += 1

    if os.getenv("COMPOSER_DISABLE_NAME_CHECK") is None:
        name_validator = re.compile(r'^[a-z0-9]([_.-]?[a-z0-9]+)*/[a-z0-9](([_.]?|-{0,2})[a-z0-9]+)*$')

        if not name_validator.search(local_composer.get("name", "")):
            print_validation_error("name", local_composer.get("name", "empty"), "t")
            ERROR_COUNT += 1

        if os.getenv("COMPOSER_VENDOR_NAME") is not None:
            vendor = local_composer.get("name", "").split('/')[0]

            if vendor != os.getenv("COMPOSER_VENDOR_NAME"):
                print_validation_error("name", vendor, "Invalid vendor name", os.getenv("COMPOSER_VENDOR_NAME")+"/package-name")
                ERROR_COUNT += 1

    if os.getenv("COMPOSER_DISABLE_TYPE_CHECK") is None:
        if local_composer.get("type", "") not in ALLOW_TYPES:
            print_validation_error("type", local_composer.get("type", "empty"), "Invalid type", ALLOW_TYPES)
            ERROR_COUNT += 1

    if os.getenv("COMPOSER_DISABLE_LICENSE_CHECK") is None:
        if isinstance(local_composer.get("license", ""), str):
            if local_composer.get("license", "") not in ALLOWED_LICENSES:
                print_validation_error(
                    "license", local_composer.get("license", "empty"), "Invalid license", ALLOWED_LICENSES
                )
                ERROR_COUNT += 1
        else:
            license_field: list = local_composer.get("license", [])

            if len(license_field) != 1:
                print_validation_error(
                    "license", f"[{', '.join(license_field)}]", "Field can contain only one string", ALLOWED_LICENSES
                )
                ERROR_COUNT += 1
            else:
                license_field_value = license_field[0]

                if license_field_value not in ALLOWED_LICENSES:
                    print_validation_error(
                        "license", license_field_value, "Field contains invalid license", ALLOWED_LICENSES
                    )
                    ERROR_COUNT += 1

    if os.getenv("COMPOSER_DISABLE_PSR4_CHECK") is None:
        if 'psr-4' not in local_composer.get("autoload", {}):
            print_validation_error(
                field="autoload.psr-4",
                msg="Required property psr-4 not found",
                possible_values={
                    "autoload": {
                        "psr-4": {
                            "Vendor\\Module": ""
                        }
                    }
                }
            )
            ERROR_COUNT += 1
        elif len(local_composer.get("autoload", {}).get("psr-4", {})) == 0:
            print_validation_error(
                field="autoload.psr-4", msg="The `psr-4` property is specified but contains no data"
            )
            ERROR_COUNT += 1

    if os.getenv("COMPOSER_DISABLE_DESCRIPTION_CHECK") is None:
        if len(local_composer.get("description", "")) == 0:
            print_validation_error(
                field="description", msg="The field description is not filled or empty"
            )
            ERROR_COUNT += 1

        if local_composer.get("description", "").lower() == "n/a":
            print_validation_error(
                field="description",
                msg="Field description contains invalid data",
                current_value=local_composer.get("description", "")
            )
            ERROR_COUNT += 1

    if os.getenv("DISABLE_PHP_CHECK") is None:
        if local_composer.get("require", {}).get("php", "") not in ALLOW_PHP_VERSIONS:
            print_validation_error(
                "php",
                local_composer.get("require", {}).get("php", "empty"),
                "Incorrect PHP dependency was found",
                ALLOW_PHP_VERSIONS
            )
            ERROR_COUNT += 1

    if os.getenv("DISABLE_REGISTRATION_PHP_CHECK") is None:
        if 'registration.php' not in local_composer.get("autoload", {}).get("files", []):
            print_validation_error(
                "files",
                msg="Cannot find registration.php in autoload section",
                possible_values={
                    "files": [
                        "registration.php"
                    ]
                }
            )
            ERROR_COUNT += 1

    if local_composer.get("require", {}).get("magento/magento-composer-installer") is not None:
        print_validation_error(
            field="require",
            msg="Obsolete dependency on \"magento/magento-composer-installer\" was found"
        )
        ERROR_COUNT += 1

    gl = gitlab.Gitlab(
        url=os.getenv("CI_SERVER_URL"), private_token=os.getenv("CONF_CTOKEN")
    )
    try:
        gl.auth()
    except gitlab.GitlabError:
        ColoredOutput.fail("API Error: Cannot sign in.")
        sys.exit(1)

    current_project = gl.projects.get(os.getenv("CI_PROJECT_ID"))
    version_local = local_composer.get("version")

    if version_local is not None:
        try:
            # Load content of composer.json from project master branch.
            master_composer = json.loads(current_project.files.raw(file_path="composer.json", ref="master"))
            version_master = master_composer.get("version", "")

            if version_master != "" and sv.Version(version_local) <= sv.Version(version_master):
                ColoredOutput.fail("You have to update module version. Current master version is " + version_master)
                sys.exit(1)
        except gitlab.exceptions.GitlabOperationError:
            ColoredOutput.warn("composer.json on master branch was not found.")

    if ERROR_COUNT:
        sys.exit(ERROR_COUNT)

    if current_project.id == BASE_PROJECT_ID:
        ColoredOutput.green("This is amasty/base. Exit.")
        sys.exit(0)

    if os.getenv("IGNORE_BASE_REQUIRE") is not None:
        ColoredOutput.green("Skip amasty/base dependency check. Exit.")
        sys.exit(0)

    base_project = gl.projects.get(BASE_PROJECT_ID)

    current_branch = os.getenv("CI_COMMIT_REF_NAME")
    tags = base_project.tags.list()
    last_base_tag = ">=" + tags[0].name

    if local_composer.get("require", {}).get("amasty/base", "") != last_base_tag:
        branch_composer_obj = current_project.files.get(
            file_path="composer.json", ref=current_branch
        )

        local_composer["require"].update({"amasty/base": last_base_tag})
        branch_composer_obj.content = json.dumps(local_composer, indent=4) + "\n"

        try:
            branch_composer_obj.save(
                branch=current_branch, commit_message="Update composer.json."
            )
            ColoredOutput.green("composer.json has been updates. Cancel pipline.")
        except gitlab.GitlabError:
            ColoredOutput.fail("Cannot commit modified composer.json to " + current_branch)
            sys.exit(1)

        pipeline = current_project.pipelines.get(os.getenv("CI_PIPELINE_ID"))
        pipeline.cancel()
