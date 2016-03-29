#!/bin/bash

#############################################
#     Script MD5 checksum par Yohannes      #
# Utilisé dans le but de surveiller un site #
#    web, ou alors un système de fichiers   #
#############################################
#		    V2.1		    #
#############################################
#		 29/03/2016		    #
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
commande="md5sum"
obligatoire="0"
verbose="0"
force="0"
mail="0"
email=""
sujetok="[SUCCESS] : SpyMyFolder - Recapitulatif mail du $(date +%d/%m/%Y) à $(date +%R)"
sujetcritical="[CRITICAL] : SpyMyFolder - Recapitulatif mail du $(date +%d/%m/%Y) à $(date +%R)"
corpsok="Bonjour,\n\nR.A.S, tout est en ordre chef."
corpscritical="Bonjour,\n\nVous avez des erreurs. Voici ci dessous les fichiers qui ont été modifiés :\n\n\n"
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
	echo "	         -e : Désigne un repertoire à exclure"
	echo "		 -v : Mode verbose"
	echo "		 -p : Protocole pour la vérification à utiliser. Au choix : md5, sha1, sha256, ou sha512"
	echo "		 -f : Mode force. Pas de demande de confirmation pour le remplacement des hashs existants"
	echo "		 -m : Mail : Utilise la commande \"mail\" pour envoyer un rapport. Utile en utilisation automatisé. Assurez-vous d'avoir un \"postfix\" fonctionnel !"
	echo ""
        echo "Exemple : $0 -v -f -s /etc/ -d /var/log/md5/"
	echo "          $0 -s /etc/ -d /var/log/md5/ -e /etc/network/ -p sha256 -m john@doe.com"
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
		shift
		#Test dossier exclusion
                if [ ! -d "$1" ]; then
                        echo "Dossier d'exclusion invalide."
                        exit
                fi
                scount=$(echo -n $source | wc -c)
                ecount=$(echo -n $1 | wc -c)
                if  [[ "$1" != "$source"* ]] || [ "$scount" -ge "$ecount" ]; then
                        echo "Le dossier exclusion n'est pas compatible avec la source !"
                        exit
                fi
		exclusion="$1"
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

#Suppression du fichier md5 de la précédente utilisation si existant
if [ -e ${destination}${nomfichiersmd5} ]; then
	rm -f ${destination}${nomfichiersmd5}
fi
touch ${destination}${nomfichiersmd5}

#md5sum de tous les fichiers dans un seul fichier texte
for fichier in $(find $source); do
	#Gestion du mode verbose
	if [ "$verbose" == "1" ]; then
		echo "$fichier"
	fi
	if [ -f $fichier ] && [[ $fichier != "$exclusion"* ]] && [ ! -d "$fichier" ]; then
		${commande} "$fichier" >> ${destination}${nomfichiersmd5}
	fi
done

echo "Le fichier 'md5fichiers' listant tous les fichiers a bien été créé !"

if [ -e ${destination}${nomtotalmd5} ]; then
	rm ${destination}${nomtotalmd5}
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
			echo -e $corpscritical > ${destination}"rapport.txt"
			echo -e "Synthèse ci-dessous (le \"<\" signifie fichier non présent, le \">\" signifie fichier en plus) :\n\n" >> ${destination}"rapport.txt"
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
		#Mail etat impossible
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
		echo -e $corpsok | mail -s $sujetok -a "Content-Type: text/plain; charset=ISO-8859-15" $email
	else
		cat ${destination}"rapport.txt" | mail -s $sujetcritical -a "Content-Type: text/plain; charset=ISO-8859-15" $email
		#On supprime le rapport
		rm ${destination}"rapport.txt"
	fi
	echo "Un mail a bien été envoyé à "$email "."
fi
echo "Fin du programme."
