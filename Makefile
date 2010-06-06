DEPENDS=$(HOME)/.vim/autoload/xolox/path.vim \
		$(HOME)/.vim/autoload/xolox/escape.vim
VIMDOC=doc/publish.txt
HTMLDOC=doc/readme.html
ZIPDIR := $(shell mktemp -d)
ZIPFILE := $(shell mktemp -u)

# NOTE: Make does NOT expand the following back ticks!
VERSION=`grep '^" Version:' publish.vim | awk '{print $$3}'`

# The main rule builds a ZIP that can be published to http://www.vim.org.
archive: Makefile publish.vim autoload.vim $(VIMDOC) $(HTMLDOC)
	@echo "Creating \`publish-$(VERSION).zip' .."
	@mkdir -p $(ZIPDIR)/plugin $(ZIPDIR)/autoload/xolox $(ZIPDIR)/doc
	@cp publish.vim $(ZIPDIR)/plugin
	@cp autoload.vim $(ZIPDIR)/autoload/publish.vim
	@cp $(DEPENDS) $(ZIPDIR)/autoload/xolox
	@cp $(VIMDOC) $(ZIPDIR)/doc/publish.txt
	@cp $(HTMLDOC) $(ZIPDIR)/doc/publish.html
	@cd $(ZIPDIR) && zip -r $(ZIPFILE) . >/dev/null
	@rm -R $(ZIPDIR)
	@mv $(ZIPFILE) publish-$(VERSION).zip

# This rule converts the Markdown README to Vim documentation.
$(VIMDOC): Makefile README.md
	@echo "Creating \`$(VIMDOC)' .."
	@mkd2vimdoc.py `basename $(VIMDOC)` < README.md > $(VIMDOC)

# This rule converts the Markdown README to HTML, which reads easier.
$(HTMLDOC): Makefile README.md doc/README.header doc/README.footer
	@echo "Creating \`$(HTMLDOC)' .."
	@cat doc/README.header > $(HTMLDOC)
	@cat README.md | markdown | SmartyPants >> $(HTMLDOC)
	@cat doc/README.footer >> $(HTMLDOC)

# This is only useful for myself, it uploads the latest README to my website.
web: $(HTMLDOC)
	@echo "Uploading homepage .."
	@scp -q $(HTMLDOC) vps:/home/peterodding.com/public/files/code/vim/publish/index.html

all: archive web
