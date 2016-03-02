PGXNTOOL_NO_PGXS_INCLUDE := 1
include pgxntool/base.mk

include $(PGXS)

testdeps: cat_tools
.PHONY: cat_tools
cat_tools: $(DESTDIR)$(datadir)/extension/cat_tools.control

$(DESTDIR)$(datadir)/extension/cat_tools.control:
	pgxn install cat_tools

#
# pgtap
#
# NOTE! This currently MUST be after PGXS! The problem is that
# $(DESTDIR)$(datadir) aren't being expanded. This can probably change after
# the META handling stuff is it's own makefile.
#
.PHONY: pgtap
pgtap: $(DESTDIR)$(datadir)/extension/pgtap.control

$(DESTDIR)$(datadir)/extension/pgtap.control:
	pgxn install pgtap

