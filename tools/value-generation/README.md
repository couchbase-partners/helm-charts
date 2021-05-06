# Value file generation

This directory contains simple Python tooling built on the example here:

It will auto-generate a values.yaml file with comments from a CRD.

To create a container with the CRD to use:
`docker build --build-arg CRD_FILE=<CRD to use> -t crd-value-generator .`

To run it is then:
`docker run crd-value-generator > values.yaml`

The YAML is output to standard output of the container and is also kept within the container as well.

To run with a custom CRD:
`docker run --mount type=bind,readonly=true,source=<CRD>,target=/source/crd.yaml crd-value-generator > values.yaml`
