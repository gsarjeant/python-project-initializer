# python-project-initializer

This repository contains scripts to create scaffolding for python projects on Windows, Mac, and Linux. The scaffolding sets up a basic local testing framework and IDE integration. The goal is to allow development organizations to establish a standardized local development environment for python prjoects that encourages adherence to best practices and test-driven development. The configuration includes:

* Creation of a virtual python environment in the .env directory of the project
  * NOTE: the .env directory is .gitignored
* Installation of common local testing modules
  * pylint
  * pytest
  * coverage
* Integration with [Microsoft Visual Studio Code](https://code.visualstudio.com/)
  * I may do other editors later, but right now I'm obsessed with VSCode.
