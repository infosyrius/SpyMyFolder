# SpyMyFolder
This script check if a file was modified since the last time, by a hash of each file inside a folder (MD5 by default, but you can choose SHA1, SHA256 or SHA512).

There is an example of use : 

	Syntaxe :  ./testmd5.sh -s /folder/to/test/ -d /folder/for/hash/results/ [-e /exclude/folder] [-v] [-f] [-p [md5/sha1/sha256/sha512]]


	-s : Source folder to control
    
	-d : Destination folder for hashs results
 	  
	-e : Exclude a folder in the source
	  
	-v : Verbose mode
		
	-p : Choose hash algorithm : md5 sha1 sha256 sha512. default is md5
		
	-f : No ask for replacement hash's result
		
	Exemple : ./testmd5.sh -v -f -s /etc/ -d /var/log/spymyfolder/

	./testmd5.sh -s /etc/ -d /var/log/spymyfolder/ -e /etc/network/ -p sha256


This script is not finished at this time.
