# workaround for com_apple_MobileAsset_DictionaryServices_dictionaryOSX.xml

BEGIN {
	FS = OFS = "\t"
}
# Monterey
$1 == 11 {
	sub(/.*\//, "", $4)
	sub(/\.zip$/, ".asset", $4)  # basename(url)
	original[$5] = $4  # bundle -> zipball
	next
}
# Big Sur
$1 == 10 {
	sub(/.*\//, "", $4)
	sub(/\.zip$/, ".asset", $4)
	fake[$5] = $4
	next
}
END {
	# python tsv.py  # re-format dicts.tsv
	# awk -f dicts.awk <dicts.tsv >install.sh
	# sh install.sh	 # in recovery mode
	srcdir = "/Volumes/UNLOCKED/Users/USERNAME/MobileAssetsDownload"
	olddir = "/Volumes/UNLOCKED/Users/USERNAME/Library/Dictionaries"
	dstdir = "/Volumes/UNLOCKED/System/Library/AssetsV2/com_apple_MobileAsset_DictionaryServices_dictionaryOSX"
	print "#!/bin/sh"
	print "set +e -u +f; unset -v IFS; export LC_ALL=C"
	for (k in original) {
		if (k in fake) {
			l = shquote(srcdir "/" original[k])
			r = shquote(dstdir "/" fake[k])
			printf "cp -a %s/ %s/\n", l, r
		} else {
			l = shquote(srcdir "/" original[k] "/AssetData")
			r = shquote(olddir)
			printf "cp -a %s/ %s/\n", l, r
		}
	}
	printf "chown -R _nsurlsessiond:_nsurlsessiond %s/*.asset\n", shquote(dstdir)
	printf "chown -R USERNAME:staff %s/*.dictionary\n", shquote(olddir)
}

function shquote(path) {
	gsub(/'/, "'\\''", path)
	return "'" path "'"
}
