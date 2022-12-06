# Toolbox.sh
*Runtime scrips used in our images.*

Primary enrypoint - toolbox.sh from the bin directory.

Common required environment variables:
| Name        | Description                           | Type     |
|-------------|---------------------------------------|----------|
| SCRIPTS_DIR | path to the toolbox.sh root directory | Variable |

Command list:
* Magento namespace:
	* toolbox.sh magento install
	* toolbox.sh magento deploy
	* toolbox.sh magento mftf
	* toolbox.sh magento i18n
* DB namespace:
	* toolbox.sh db dump
* Modules/Repositories namespace:
	* toolbox.sh modules add
* PHPUnit namespace
	* toolbox.sh phpunit api
	* toolbox.sh phpunit integration
	* toolbox.sh phpunit unit
* Static analysers / Linter namespace:
	* toolbox.sh lint phpmd
	* toolbox.sh lint phpstan


## Magento namespace:
Environment variables:
| Name        | Description                          | Type     |
|-------------|--------------------------------------|----------|
| MAGENTO_DIR | path to the Magento 2 root directory | Variable |

### toolbox.sh magento install
The script is a wrapper over the setup:install command, which starts the Magento 2 installation process with predefined parameters. You can find the list of parameters in the script file itself. Please note that some of them are required.

### toolbox.sh magento deploy
The script is a wrapper over the main commands needed to deploy a Magento 2 application. Unlike the previous script, this one is configured with options when running the command.

### toolbox.sh magento mftf
This script prepares the Magento 2 installation for running MFTF tests, including running Smoke tests inside CI / CD according to a particular scenario. After preparation, the script runs the tests by the group's name.

### toolbox.sh magento i18n
This script creates/updates the translation files for our modules, puts them in the correct directory, and continuously pushes the changes to git to update them according to the code.

## DB namespace:
Environment variables:
| Name           | Description                                                  | Type     |
|----------------|--------------------------------------------------------------|----------|
| MYSQL_DATABASE | Name of MySQL database                                       | Variable |
| DB_DUMP_DIR    | Path to the directory where database dump will be placed or already located | Variable |

### toolbox.sh db dump
The script creates a database dump (default operation) or restores it (`--restore` option). The mydumper utility is used to work with dumps.

## Modules/Repositories namespace
Environment variables:
| Name              | Description                                                  | Type                | Require |
|-------------------|--------------------------------------------------------------|---------------------|---------|
| CI_PROJECT_DIR    | project build directory                                      | Predifined variable | Yes     |
| MAGENTO_DIR       | path to the Magento 2 root directory                         | Variable            | Yes     |
| MODULE_DEPS       | array of required git repositories with modules              | Variable            | No      |
| SMOKE_MODULE_PATH | path to git repository with special module for  Smoke MFTF tests | Variable            | No      |
| COMPOSER_AUTH     | JSON-content of auth.json composer file                      | Variable            | No      |

### toolbox.sh modules add
The script installs the current module and its dependencies.
Dependencies are defined via the `MODULE_DEPS` environment variable and are downloaded from the GitLab instance.
The script can also install a specific module for Smoke MFTF tests if the path to the module is specified via the `SMOKE_MODULE_PATH` environment variable and the script is launched with the appropriate option. To authenticate in private repositories, you must fill the `COMPOSER_AUTH` environment variable with the contents of the auth.json file. The script will forcibly remove all repositories from the composer.json file if the variable is left unset or running.

## PHPUnit namespace
Environment variables:
| Name           | Description                          | Type                |
|----------------|--------------------------------------|---------------------|
| CI_PROJECT_DIR | project build directory              | Predifined variable |
| MAGENTO_DIR    | path to the Magento 2 root directory | Variable            |

These scripts require envsubst.

### toolbox.sh phpunit api
The script is a wrapper for running API tests. Running for REST API and GraphQL tests are currently supported.

### toolbox.sh phpunit integration
Wrapper script to run all integration tests for the current project/module.

### toolbox.sh phpunit unit
Wrapper script to run all unit tests for the current project/module.

## Static analysers / Linter namespace
Environment variables:
| Name           | Description                          | Type                |
|----------------|--------------------------------------|---------------------|
| CI_PROJECT_DIR | project build directory              | Predifined variable |
| MAGENTO_DIR    | path to the Magento 2 root directory | Variable            |

### toolbox.sh lint phpmd
The script launches PHP Mess Detector with built-in Magento 2 rulset.

### toolbox.sh lint phpstan
The script starts PHPStan with a built-in .neon config file.
