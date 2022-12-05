#!/usr/bin/env python

import json
import os
import sys
import gitlab
import semantic_version as sv

ALLOW_PHP_VERSIONS = ["^7.3.0", ">=7.3.0", ">=7.3"]
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


if __name__ == "__main__":
    current_branch = os.getenv("CI_COMMIT_REF_NAME")

    gl = gitlab.Gitlab(
        url=os.getenv("CI_SERVER_URL"), private_token=os.getenv("CONF_CTOKEN")
    )

    try:
        with open("composer.json", mode="r", encoding="utf-8") as json_file:
            local_composer = json.load(json_file)
    except Exception:
        ColoredOutput.fail("Cannot load local composer.json file.")
        sys.exit(1)

    try:
        gl.auth()
    except Exception:
        ColoredOutput.fail("API Error: Cannot sign in.")
        sys.exit(1)

    # Get current project
    current_project = gl.projects.get(os.getenv("CI_PROJECT_ID"))

    try:
        # Load content of composer.json from project master branch.
        master_composer = json.loads(
            current_project.files.raw(file_path="composer.json", ref="master")
        )

        if sv.Version(local_composer.get("version", "")) <= sv.Version(
            master_composer.get("version", "")
        ):
            ColoredOutput.fail(
                "You have to update module version. Current master version is "
                + master_composer.get("version", "")
            )
            sys.exit(1)
    except gitlab.exceptions.GitlabOperationError:
        ColoredOutput.warn("composer.json on master branch was not found.")

    if os.getenv("DISABLE_PHP_CHECK") is None:
        if local_composer.get("require", {}).get("php") not in ALLOW_PHP_VERSIONS:
            ColoredOutput.fail(
                'Incorrect PHP dependency was found. Should be "php":"'
                + '" or "php":"'.join(ALLOW_PHP_VERSIONS)
                + '".'
            )
            sys.exit(1)

    if local_composer.get("require", {}).get("magento/magento-composer-installer"):
        ColoredOutput.fail(
            'Obsolete dependency on "magento/magento-composer-installer" was found.'
        )
        sys.exit(1)

    if current_project.id == BASE_PROJECT_ID:
        ColoredOutput.green("This is amasty/base. Exit.")
        sys.exit(0)

    if os.getenv("IGNORE_BASE_REQUIRE") is not None:
        ColoredOutput.green("Skip amasty/base dependency check. Exit.")
        sys.exit(0)

    base_project = gl.projects.get(BASE_PROJECT_ID)

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
        except Exception:
            ColoredOutput.fail(
                "Cannot commit modified composer.json to " + current_branch
            )
            sys.exit(1)

        pipeline = current_project.pipelines.get(os.getenv("CI_PIPELINE_ID"))
        pipeline.cancel()
