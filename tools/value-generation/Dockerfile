FROM python:3

WORKDIR /source

# Add the python scripts
COPY *.py ./bin/
COPY requirements.txt ./config/
RUN pip install -r config/requirements.txt 

# Specify the CRD to use as a build argument or mount in to /source/crd.yaml
ARG CRD_FILE=crd.yaml
COPY ${CRD_FILE} crd.yaml

ENTRYPOINT ["python3", "/source/bin/gen.py"]
CMD [ "--help" ]