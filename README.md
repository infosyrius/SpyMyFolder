# SpyMyFolder

This script check if a file was modified since the last time, with a hash of each file inside a folder (MD5 by default, but you can choose SHA1, SHA256 or SHA512).

Example of use (From --help command): 

	Synthax :  ./testmd5.sh -s /folder/to/test/ -d /folder/for/hash/results/ [-e /exclude/folder] [-v] [-f] [-p [md5/sha1/sha256/sha512]]


	-s : Source folder to control
    
	-d : Destination folder for hashs results
 	  
	-e : Exclude folders or a files in the source. 
	  
	-v : Verbose mode
		
	-p : Choose hash algorithm : md5 sha1 sha256 sha512. default is md5
		
	-f : Force : no ask for replacement hash's result
	
	-m : Send a mail. Warning : This script use mail command
	
	Example : ./spymyfolder.sh -v -f -s /etc/ -d /var/log/spymyfolder/

	./spymyfolder.sh -s /etc/ -d /var/log/spymyfolder/ -e /etc/network/ /etc/apt/ /etc/passwd -p sha256 -m john@doe.com
	
	Warning : If you want to send mail, please check if postfix is ok


#SpyMyFolder

Ce script permet de vérifier si un fichier a été modifié depuis la dernière vérification, par un hash de chaque fichiers dans un repertoire donné (Hash en MD5, SHA1, SHA256 ou SHA512).

Voici un exemple d'utilisation (Issue de la commande --help) :

	Syntaxe : ./spymyfolder.sh -s /Dossier/a/tester/ -d /Destination/des/hashs/md5/ [-e /Dossier/exclu] [-v] [-f] [-p [md5/sha1/sha256/sha512]] [-m john@doe.com]

	-s : Dossier source à controler

	-d : Dossier destination pour la copie des hashs

	-e : Désigne le(s) repertoire(s) ou fichier(s) à exclure

	-v : Mode verbose

	-p : Protocole pour la vérification à utiliser. Au choix : md5, sha1, sha256, ou sha512

	-f : Mode force. Pas de demande de confirmation pour le remplacement des hashs existants

	-m : Mail : Utilise la commande "mail" pour envoyer un rapport. Utile en utilisation automatisé. Assurez-vous d'avoir un postfix fonctionnel !

	Exemple : ./spymyfolder.sh -v -f -s /etc/ -d /var/log/spymyfolder/

	./spymyfolder.sh -s /etc/ -d /var/log/spymyfolder/ -e /etc/network/ /etc/apt/ /etc/passwd -p sha256 -m john@doe.com

	/!\ ATTENTION /!\ : Assurez-vous d'avoir un postfix foncionnel !


Ce script n'est pas fini pour le moment.
