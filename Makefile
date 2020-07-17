#! /bin/make
SHELL:=/bin/bash

prefix:=$(shell echo ~/.local)

pod_src:=fuseki-db-init
pod:=$(patsubst %,%.pod,${pod_src})

pod:${pod}

pre-commit: ${pod}
	@podchecker ${pod_src}

${pod}:%.pod:%
	@podselect $< > $@

install:
	@type podchecker;
	@type http;
	@type pod2text;
	@if [[ -d ${prefix}/bin ]]; then\
    echo "install ${pod_src} ${prefix}/bin"; \
    install ${pod_src} ${prefix}/bin; \
	else \
		echo "installation directory ${prefix}/bin not found"; \
		echo "Try setting prefix as in make prefix=. install"; \
		exit 1; \
	fi;
