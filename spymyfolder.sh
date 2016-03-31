#!/bin/bash

#############################################
#     Script MD5 checksum par Yohannes      #
# Utilisé dans le but de surveiller un site #
#    web, ou alors un système de fichiers   #
#############################################
#
## Se connecter en ssh sur une machine :
## ssh login@machineDistante bash < script.sh 	# Permet d'executer une commande locale
## Penser à renseigner les clés de connexion SSH sur le serveur hote
#

#Definition des variables
nomfichiersmd5="checksum_fichiers.txt"
nomfichiersmd5precedent="checksum_fichiers_precedent.txt"
nomtotalmd5="checksum_total.txt"
nomtotalmd5precedent="checksum_total_precedent.txt"
replace="?"
exclusion=""
maxexclu="0"
commande="md5sum"
obligatoire="0"
verbose="0"
force="0"
mail="0"
email=""
sujetok="[SUCCESS] : SpyMyFolder - Recapitulatif mail du $(date +%d/%m/%Y) à $(date +%R)"
sujetcritical="[CRITICAL] : SpyMyFolder - Recapitulatif mail du $(date +%d/%m/%Y) à $(date +%R)"
corpsok="Bonjour,\n\nR.A.S, tout est en ordre chef."
corpscritical="Bonjour,\n\nVous avez des modifications.\n\n\nSynthèse ci-dessous (le \"<\" signifie fichier non présent, le \">\" signifie fichier en plus) :\n\n"
#Valeur du séparateur par défaut
IFS=$'\n'

#Fonction erreur
function help()
{
        echo ""
        echo "--help pour afficher l'aide"
	echo ""
        echo "Syntaxe : $0 -s /Dossier/a/tester/ -d /Destination/des/hashs/md5/ [-e /Dossier/exclu] [-v] [-f] [-p [md5/sha1/sha256/sha512]] [-m john@doe.com]"
        echo "	         -s : Dossier source à controler"
        echo " 	         -d : Dossier destination pour la copie des hashs"
	echo "	         -e : Désigne le(s) repertoire(s) ou fichier(s) à exclure. "
	echo "		 -v : Mode verbose"
	echo "		 -p : Protocole pour la vérification à utiliser. Au choix : md5, sha1, sha256, ou sha512"
	echo "		 -f : Mode force. Pas de demande de confirmation pour le remplacement des hashs existants"
	echo "		 -m : Mail : Utilise la commande \"mail\" pour envoyer un rapport. Utile en crontab. Assurez-vous d'avoir un \"postfix\" fonctionnel !"
	echo ""
        echo "Exemple : $0 -v -f -s /etc/ -d /var/log/spymyfolder/"
	echo "          $0 -s /etc/ -d /var/log/spymyfolder/ -e /etc/network/ /etc/apt/ /etc/passwd -p sha256 -m john.doe@business.com"
	echo ""
	echo "/!\\ ATTENTION /!\\ : Dépends de la commande \"mail\" pour l'envoi de mail !"
	echo ""
	exit
}

#Fonction d'erreur
function error()
{
	echo "Erreur de syntaxe. Saisissez --help pour afficher l'aide."
	exit
}


#Controle si l'aide est demandée
if [ "$1" == "--help" ]; then
	help
fi

#Traitement des paramètres passés au script
until [ "$*" = "" ]; do
	case "$1" in
	#Test source
	-s)
		shift
		#Test si la source n'a pas déja été renseigné
		if [ "$source" != "" ] ; then
			error
		fi
		if [ ! -d "$1" ]; then
                	echo "Dossier source invalide."
                	exit
        	fi
                #Rajout d'un / si non présent
                if [[ $1 != */ ]] ; then 
                        source="$1""/"
                else
                        source="$1"
                fi
		((obligatoire++))
	;;
	#Test destination
	-d)
		shift
		#Test si la destination n'a pas déja été renseigné
                if [ "$destination" != "" ] ; then
                        error
                fi
        	if [ ! -d "$1" ]; then
                	echo "Dossier destination invalide."
                	exit
        	fi
		#Rajout d'un / si non présent
		if [[ $1 != */ ]] ; then 
			destination="$1""/"
		else
			destination="$1"
		fi
		((obligatoire++))
	;;
	#Test exclusion
	-e)
		#Test si l exclusion n'a pas déja été renseigné
                if [ "$exclusion" != "" ] ; then
                        error
                fi
		#Boucle pour savoir si plusieurs exclusions ont été définies à la suite
		until [ "$*" = "" ]; do
			#On teste si l'argument suivant est valide
			if [[ "$2" == -* || "$2" == "" ]]; then
				break
			fi
			#Test dossier ou fichier existant réélement
                	if [ ! -d "$2" -a ! -f "$2" ]; then
                        	echo "Exclusion invalide. Vérifier que le chemin \"$2\" existe !"
                        	exit
                	fi
			#Test pour savoir si l'exclusion fait bien parti de la source
			if ! [[ "$2" =~ "$source".+ ]]; then
               			echo "Le dossier exclusion \"$2\"n'est pas compatible avec la source !"
        	        	exit
	                fi
			#On teste si c'est la premiere fois
			if [[ "$exclusion" == "" ]]; then
				exclusion="$2"
			else
				exclusion="$exclusion$IFS$2"
				dernierexclu="$2"
			fi
			#On incrémente le compteur maxexclu
			maxexclu=$((maxexclu+1))
		shift
		done
	;;
	#Test verbose
	-v)
		verbose="1"
	;;
	#test protocol
	-p)
		shift
	        case  "$1" in
		sha1)
			commande="sha1sum"
		;;
		md5)
			commande="md5sum"
		;;
		sha256)
			commande="sha256sum"
		;;
		sha512)
			commande="sha512sum"
		;;
		*)
			error
		esac
	;;
	#Test mode sans confirmation utilisateur
	-f)
		force="1"
	;;
	#Test mail : -f implicite
	-m)
		shift
		if [[ "$1" != *@*.* ]]; then
			echo "Il y a une erreur dans la saisie de l'adresse mail."
			exit
		fi
		force="1"
		mail="1"
		email="$1"
	;;
	*)
		shift
		error
	esac
	shift
done

#Test si assez d'argument obligatoire et minimal donné :
if [ "$obligatoire" -le 1 ] && [ "$#" -le 2 ]; then
	error
fi

#########################################################################
#									#
#			     Main					#
#									#
#########################################################################

#Suppression du fichier hash de la précédente utilisation si existant
if [ -e ${destination}${nomfichiersmd5} ]; then
	rm -f ${destination}${nomfichiersmd5}
fi
touch ${destination}${nomfichiersmd5}
#Si il est impossible de créer le fichier des hashs
if [ "$?" == 1 ]; then
	echo "Impossible de créer le fichier listant les hashs. Assurez-vous d'avoir les droits sur le dossier $destination et réessayer."
	exit
fi


#Hash de tous les fichiers présents dans la source dans un seul fichier texte
for fichier in $(find $source); do
	#On défini le compteur exclusion à 0
	compteur=0
	#On teste les exclusions un par un
	for exclu in $exclusion; do
		if [ -f $fichier ] && [[ $fichier != "$exclu"* ]]; then
			compteur=$((compteur+1))
		fi
	done
	#On valide le traitement suivant les deux conditions
        if [[ "$exclu" == "$dernierexclu" ]] && [[ "$compteur" == "$maxexclu" ]]; then 
        	#Gestion du mode verbose
                if [ "$verbose" == "1" ]; then
                	echo "Traitement de $fichier"
                fi
                ${commande} "$fichier" >> ${destination}${nomfichiersmd5}
        fi
done

echo "Le fichier 'md5fichiers' listant tous les fichiers a bien été créé !"

if [ -e ${destination}${nomtotalmd5} ]; then
	rm -f ${destination}${nomtotalmd5}
fi

touch ${destination}${nomtotalmd5}
${commande} ${destination}${nomfichiersmd5} > ${destination}${nomtotalmd5}
echo "Le fichier 'md5total' listant tous les fichiers a bien été créé !"
echo "Tentative de comparaison des fichiers existants ..."

if [ -e ${destination}${nomtotalmd5precedent} ]; then
	cmp ${destination}${nomtotalmd5} ${destination}${nomtotalmd5precedent} 2>/dev/null 2>&1
	resultat=$?
	if [ $resultat -eq 0 ]; then
		echo "Les fichiers sont identiques !"
	elif [ $resultat -eq 1 ]; then
		while [ "$replace" != "o" ] && [ "$replace" != "O" ] && [ "$replace" != "" ]; do
			replace=""
			echo "/!\ FICHIERS DIFFERENTS /!\ "
			diff ${destination}${nomfichiersmd5precedent} ${destination}${nomfichiersmd5}
			#On enregistre le résultat dans un fichier, pour l'envoi du mail, avec le corps
			touch ${destination}"rapport.txt"
			echo -e $corpscritical > ${destination}"rapport.txt"
			diff ${destination}${nomfichiersmd5precedent} ${destination}${nomfichiersmd5} >> ${destination}"rapport.txt"
			#Test si le mode force est activée pour bypasser la demande
			if [ $force -eq 1 ]; then
				echo "Utilisation du mode force. Remplacement en cours..."
				cp ${destination}${nomtotalmd5} ${destination}${nomtotalmd5precedent}
                                cp ${destination}${nomfichiersmd5} ${destination}${nomfichiersmd5precedent}
                                echo "Le fichier a bien été copié !"
			else
				echo -n "Voulez vous remplacer les différents hashs md5 par les nouveaux ? (O/n): "
				read replace
				if [ "$replace" = "o" ] || [ "$replace" = "O" ] || [ "$replace" = "" ]; then
 					cp ${destination}${nomtotalmd5} ${destination}${nomtotalmd5precedent}
					cp ${destination}${nomfichiersmd5} ${destination}${nomfichiersmd5precedent}
					echo "Le fichier a bien été copié !"
				fi
				if [ "$replace" = "n" ] || [ "$replace" = "N" ]; then
					echo "Le fichier n'a pas été remplacé. Fin du programme."
					exit
				fi
			fi
		done
	else
		#Etat impossible
		echo "Impossible d'accéder aux fichiers. Vérifiez les droits"
	fi
else
	echo "Impossible de vérifier l'intégralité du fichier. Création d'une version pour le prochain test. Vous pouvez relancer le programme."
	cp ${destination}${nomtotalmd5} ${destination}${nomtotalmd5precedent}
	cp ${destination}${nomfichiersmd5} ${destination}${nomfichiersmd5precedent}
fi

#Test pour envoyer le rapport par mail
if [ "$mail" == "1" ]; then
	#Si pas de modification depuis la derniere fois, on envoie un success dans le sujet du mail, sinon un rapport
	if  [ "$resultat" == "0" ]; then
		echo -e $corpsok | mail -s $sujetok -a "Content-Type: text/plain; charset=UTF-8" $email
	else
		cat ${destination}"rapport.txt" | mail -s $sujetcritical -a "Content-Type: text/plain; charset=UTF-8" $email
		#On supprime le rapport
		rm -f ${destination}"rapport.txt"
	fi
	echo "Un mail a bien été envoyé à" $email "."
fi
echo "Fin du script."
