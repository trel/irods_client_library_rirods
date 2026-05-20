# prepare for CRAN by removing unneeded irods_demo baggage
.ONESHELL:
SHELL = /bin/sh
PATH_MODULES := ../inst/irods_demo
DOCKER_MODULES := $(addprefix $(PATH_MODULES)/,grafana irods_catalog_consumer irods_client_nfsrods irods_client_s3_api irods_client_zone_management_tool metalnx metalnx-db minio-data prometheus sql_exporter)

all: update remove

# update modules
update:
	git submodule sync --recursive
	git submodule update --init --force --recursive --remote
# delete unnecessary docker modules
remove:
	rm -rf $(DOCKER_MODULES)
