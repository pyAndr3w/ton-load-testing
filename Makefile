#!make
.PHONY: deploy clean address

OUTDIR=build
BASE=test1
CODE_PATH=$(BASE).fif
ADDR_PATH=$(OUTDIR)/$(BASE).addr
BOC_PATH=$(OUTDIR)/$(BASE).boc
GQL=http://localhost/graphql

FIFT=$(TOOLS_BIN)/fift
FIFT_LIBS=$(TOOLS_BIN)/fiftlibs
TONOS=$(TOOLS_BIN)/tonos-cli

WC=0
WORKCHAIN=$(WC)
ifeq ($(WORKCHAIN),0)
	GAS_CONFIG=21
else ifeq ($(WORKCHAIN),-1)
	GAS_CONFIG=20
else
	$(error Bad workchain id, must be 0 or -1)
endif

TOOLS_BASE=tonos-cli-fift-
TOOLS_BIN=bin


ifeq ($(OS),Windows_NT)
	TOOLS_BASE := $(TOOLS_BASE)windows
else
    UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
        TOOLS_BASE := $(TOOLS_BASE)linux
    endif
	ifeq ($(UNAME_S),Darwin)
        TOOLS_BASE := $(TOOLS_BASE)mac
		UNAME_P := $(shell uname -p)
		ifneq ($(filter arm%,$(UNAME_P)),)
			TOOLS_BASE := $(TOOLS_BASE)-m1
		endif
    endif
endif


TOOLS_ARCHIVE=$(TOOLS_BASE).tar.gz
TOOLS_URL=https://github.com/pyAndr3w/ton-load-testing/releases/download/tools/$(TOOLS_ARCHIVE)
EXTLIB_URL=https://raw.githubusercontent.com/pyAndr3w/ExtLib.fif/aa30a11728477e2ac86978e8badf8cae57201abb/ExtLib.fif


$(TOOLS_ARCHIVE):
	wget $(TOOLS_URL)
$(OUTDIR):
	@mkdir -p $@
$(TOOLS_BIN):
	@mkdir -p $@


tools: $(TOOLS_ARCHIVE) | $(TOOLS_BIN)
	tar -xvf $< -C $|
	$(foreach t,$(TOOLS_BINARIES),$t --version;)
	wget $(EXTLIB_URL) -O $(FIFT_LIBS)/ExtLib.fif
	rm -f $<
	
	$(ifneq ($(OS),Windows_NT))
		@chmod +x $(TOOLS_BIN)/fift
		@chmod +x $(TOOLS_BIN)/tonos-cli


compile: $(OUTDIR)
	@$(eval FLAT_GAS_PRICE=$(shell tonos-cli -u $(GQL) --json getconfig $(GAS_CONFIG) | jq -rM .flat_gas_price))
	@$(FIFT) -I $(FIFT_LIBS) -s $(CODE_PATH) $(FLAT_GAS_PRICE) $(ADDR_PATH) $(BOC_PATH) $(WORKCHAIN)


deploy:
	@$(TONOS) -u $(GQL) sendfile '$(OUTDIR)/$(BASE).boc'


clean:
	rm -rf $(OUTDIR)/*


address:
	@cat $(ADDR_PATH)
	@echo

