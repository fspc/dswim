# Use Makefile.alternative if you want the modules in /usr or /usr/local,
# not in /usr/lib/perl5, see INSTALL.

PREFIX=/usr

all:

clean:
	-rm build
	-rm *.bak

install:	
	install -d $(DESTDIR)/var/lib/dpkg
	install -d $(DESTDIR)/$(PREFIX)/sbin
	cp -a swim $(DESTDIR)/$(PREFIX)/sbin/swim
	install -d $(DESTDIR)/$(PREFIX)/lib/perl5/SWIM
	cp -f Conf.pm $(DESTDIR)/$(PREFIX)/lib/perl5/SWIM/Conf.pm
	cp -fa lib/* $(DESTDIR)/$(PREFIX)/lib/perl5/SWIM
	install -d $(DESTDIR)/$(PREFIX)/lib/SWIM 
	cp -fa bin/* $(DESTDIR)/$(PREFIX)/lib/SWIM
	install -d $(DESTDIR)/$(PREFIX)/share/man/man8
	cp -f swim.8 $(DESTDIR)/$(PREFIX)/share/man/man8
	install -d $(DESTDIR)/$(PREFIX)/share/man/man5
	cp -f swimrc.5 $(DESTDIR)/$(PREFIX)/share/man/man5	
	install -d $(DESTDIR)/usr/share/doc/swim/swim.html
	cp -fa swim.html/* $(DESTDIR)/usr/share/doc/swim/swim.html
	install -d $(DESTDIR)/usr/share/doc/swim/swimrc.html
	cp -fa swimrc.html/* $(DESTDIR)/usr/share/doc/swim/swimrc.html
	cp -f QUICKSTART.html $(DESTDIR)/usr/share/doc/swim
	cp -f REQUIREMENTS.html $(DESTDIR)/usr/share/doc/swim
	cp -f swim_by_example.html $(DESTDIR)/usr/share/doc/swim
	install -d $(DESTDIR)/usr/share/doc/swim/examples
	cp -fa examples/*  $(DESTDIR)/usr/share/doc/swim/examples
	install -d $(DESTDIR)/etc/swim
	cp -f swimz.list $(DESTDIR)/etc/swim
	cp -f swimrc $(DESTDIR)/etc/swim

installdoc:
	install -d $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a QUICKSTART.text $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a REQUIREMENTS.text $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a swim_by_example.html $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a THEMES $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a TODO $(DESTDIR)/$(PREFIX)/share/doc/swim 
	cp -a BUGS $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a TODO $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a COPYING $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a contact_and_website $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a changelog $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a swim.text $(DESTDIR)/$(PREFIX)/share/doc/swim
	cp -a swimrc.text $(DESTDIR)/$(PREFIX)/share/doc/swim

remove:
	rm $(PREFIX)/lib/perl5/SWIM/*
	rmdir $(PREFIX)/lib/perl5/SWIM
	rm $(PREFIX)/sbin/swim
	rm /usr/share/doc/swim/swim.html/*
	rmdir /usr/share/doc/swim/swim.html
	rm /usr/share/doc/swim/swimrc.html/*
	rmdir /usr/share/doc/swim/swimrc.html
	rm /usr/share/doc/swim/examples/*
	rmdir /usr/share/doc/swim/examples
	rm /usr/share/doc/swim/*
	rmdir /usr/share/doc/swim
	rm $(PREFIX)/share/man/man5/swimrc.5
	rm $(PREFIX)/share/man/man8/swim.8
	rm $(PREFIX)/lib/SWIM/*
	rmdir $(PREFIX)/lib/SWIM

debian:
	dpkg-buildpackage -tc -rfakeroot


dist: debian localdist stampede rpm

.PHONY: debian
