# Value file generation

This directory contains simple Python tooling to auto-generate a `values.yaml` file with comments from a CRD.

`docker build -t values-generator .`
`docker run values-generator > values.yaml`

The YAML is output to standard output of the container.
To run with a custom CRD:
`docker run values-generator - < <CRD>`

A helper script is provided to automate all this: 
`CRD_FILE=<CRD> ./generateValuesFile.sh > values.yaml`

# Markdown generation

Once a values.yaml file has been created, we can use another tool to parse this into human-readable Markdown (or any templated) documentation.
The tool used is this: https://github.com/norwoodj/helm-docs

A helper script is provided to automate it's usage:
`CHART_DIR=<dir of chart with values.yaml> ./generateDocumentation.sh`

This will update the `README.md` file in the specified directory and use any custom templates defined there as well.
