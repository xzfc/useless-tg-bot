.PHONY: gettext-update all po

all: po
	nim c --nimcache:nimcache ${NIM_FLAGS} main
	nim c --nimcache:nimcache ${NIM_FLAGS} utils/markov_cli

po:
	msgfmt --output-file=po/ru/LC_MESSAGES/holy.mo po/ru/LC_MESSAGES/holy.po

gettext-update:
	xgettext --from-code=UTF-8 --language=python --keyword=pgettext:1c,2 --add-comments --sort-by-file -o po/holy.pot **/*.nim
	msgmerge --update po/ru/LC_MESSAGES/holy.po po/holy.pot
