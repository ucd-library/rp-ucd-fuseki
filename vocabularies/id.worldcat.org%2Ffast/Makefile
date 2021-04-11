SHELL:=/bin/bash

oclc:=https://researchworks.oclc.org/researchdata/fast/

FASTTopical.nt:
	[[ -f $@.zip ]] || wget ${oclc}/$@.zip
	unzip $@.zip $@

topical.ttl.gz: FASTTopical.nt
	arq --query=fast.rq --data=FASTTopical.nt | gzip > topical.ttl.gz

clean:
	rm -f FASTTopical.nt* *.nt *.ttl
