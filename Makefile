DEPENDS=$(HOME)/.vim/autoload/xolox/path.vim \
		$(HOME)/.vim/autoload/xolox/escape.vim
HTMLDOC=doc/README.html
ZIPDIR := $(shell mktemp -d)
ZIPFILE := $(shell mktemp -u)

# NOTE: Make does NOT expand the following back ticks!
VERSION=`grep '^" Version:' publish.vim | awk '{print $$3}'`

# The main rule builds a ZIP that can be published to http://www.vim.org.
archive: Makefile publish.vim autoload.vim $(HTMLDOC)
	@echo "Creating \`publish-$(VERSION).zip' .."
	@mkdir -p $(ZIPDIR)/plugin $(ZIPDIR)/autoload/xolox $(ZIPDIR)/doc
	@cp publish.vim $(ZIPDIR)/plugin
	@cp autoload.vim $(ZIPDIR)/autoload/publish.vim
	@cp $(DEPENDS) $(ZIPDIR)/autoload/xolox
	@cp $(HTMLDOC) $(ZIPDIR)/doc/publish.html
	@cd $(ZIPDIR) && zip -r $(ZIPFILE) . >/dev/null
	@rm -R $(ZIPDIR)
	@mv $(ZIPFILE) publish-$(VERSION).zip

# This rule converts the Markdown README to HTML, which reads easier.
$(HTMLDOC): Makefile README.md
	@echo "Creating \`README.html' .."
	@cat doc/README.header > $(HTMLDOC)
	@markdown README.md >> $(HTMLDOC)
	@cat doc/README.footer >> $(HTMLDOC)

# This is only useful for myself, it uploads the latest README to my website.
web: $(HTMLDOC)
	@echo "Uploading homepage .."
	@scp -q $(HTMLDOC) vps:/home/peterodding.com/public/files/code/vim/publish/index.html

all: archive web
