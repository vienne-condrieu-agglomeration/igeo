---
title: Installation de PostgreSQL sur un serveur Debian
subtitle: PostgreSQL - Article N°01
authors:
    - Fabien ALLAMANCHE
categories:
    - article
comments: false
date: 2024-04-15
description: PostgreSQL - Série d'articles sur l'installation, la configuration, la maintenance et l'utilisation de PostgreSQL
icon: simple/postgresql
license: Licence Ouverte / Open Licence - ETALAB
robots: index, follow
tags:
    - Potgres
    - Postgis
    - SQL
    - Debian
    - Linux
    - Série
    - Installation
---

# Installation de PostgreSQL sur un serveur Debian

:fontawesome-solid-calendar: Date de publication initiale : 15 avril 2024

!!! abstract "Note de l'auteur"

    Nous commençons une série d’articles qui se veut être un guide pour l'installation, la configuration, la maintenance et l'utilisation de PostgreSQL
    
    Les articles couvriront l’installation et la configuration, mais aussi la mise en place de la sauvegarde, de la supervision, de la maintenance et de la réplication dans des cas simples. Ce premier article concerne l’installation.

!!! info
    
    PostgreSQL est un système de gestion de base de données relationnelle et objet (SGBDRO). C'est un outil libre disponible selon les termes d'une licence de type BSD.

L’installation d’un serveur PostgreSQL n’offre pas vraiment de difficultés. Certains points particuliers sont à connaître, notamment sur les systèmes de fichiers, mais en fait, la difficulté principale est de les connaître, pas de les appliquer.

L'installation de PostgreSQL se décompose en six étapes :

- Préparation du système d’exploitation,
- Installation du dépôt de la communauté,
- Installation des paquets,
- Configuration du service,
- Initialisation du répertoire de données,
- Activation et démarrage du service,
- Configuration de l’utilisateur système postgres.

## __Préparation du système d’exploitation__

### Système hôte

Cette installation est basée sur une machine virtuelle `VM` installée avec Debian 12. Il s’agit de la version `netinst`, nom de code `bookworm` pour PC 64 bits (amd64).
Vous pouvez télécharger l'image iso [debian-12.5.0-amd64-netinst.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso).

Aucune option ne sortant de l'ordinaire n'a été utilisée pour l'installation de la distribution.

La VM (sous VirtualBox) comprend :

- 2 vCPU,
- 2 Go de RAM,
- 1 disque de 20 Go non alloué entièrement.

Toutes les commandes de cet article seront à exécuter avec l’utilisateur `root` ou en utilisant la commande `sudo`.


### __Configuration du système d’exploitation__

Il existe plusieurs paramètres du noyau Linux qui sont importants pour PostgreSQL. Un seul concerne sa stabilité, les autres sont plutôt relatifs aux performances.

Linux dispose d’un système qui lui permet d’allouer aux applications plus de mémoire qu’il n’en a réellement.

!!! tip "Overcommit Memory"

    L’idée de base est simple : beaucoup d’applications demandent de la mémoire, sans vraiment l’utiliser. Les applications écrites en Java en sont un exemple typique : beaucoup de mémoire allouée, mais au final peu réellement utilisée. De ce fait, par défaut, Linux accepte de donner plus de mémoire qu’il n’en a.
    
    Cela fonctionne généralement bien. Mais dans certains cas, comme par exemple avec PostgreSQL, cela peut causer de gros problèmes. En effet, si les applications ont la mauvaise idée d’utiliser toute la mémoire qu’elles ont allouée, Linux risque de se retrouver à court de mémoire. Dans ce cas, il décide de tuer les applications les plus consommatrices. 
    
    Et malheureusement, PostgreSQL a tendance à gagner facilement à ce jeu-là. Ce système s’appelle l’**Overcommit Memory** et il convient de le désactiver sur un serveur dédié à PostgreSQL.

Pour cela, il faut configurer le paramètre `vm.overcommit_memory` à la valeur 2. Le plus simple revient à créer un fichier nommé `/etc/sysctl.d/S99-postgresql` avec ce contenu :

``` bash
root@vm-postgres:~# vi /etc/sysctl.d/S99-postgresql
```

Ajouter la ligne :
``` vim
vm.overcommit_memory = 2
```

De cette façon, la configuration s’appliquera à chaque démarrage du serveur.


#### Désactivation des Transparent Huge Pages

Dans `/proc/meminfo`, la ligne `AnonHugePages` indique des **huge pages** allouées par le mécanisme de Transparent Huge Pages (THP) : le noyau Linux a détecté une allocation contiguë de mémoire et l’a convertie en huge pages, indépendamment du mécanisme décrit plus haut. Hélas, les `THP` ne s’appliquent pas à la mémoire partagée de PostgreSQL.

Les `THP` sont même contre-productives sur une base de données, à cause de la latence engendrée par la réorganisation par le système d’exploitation. Comme les `THP` sont activées par défaut, il faut les désactiver au boot via `/etc/crontab` :

``` bash
root@vm-postgres:~# @reboot  root  echo never > /sys/kernel/mm/transparent_hugepage/enabled
root@vm-postgres:~# @reboot  root  echo never > /sys/kernel/mm/transparent_hugepage/defrag
```

ou encore dans la configuration de `grub` :
``` vim
transparent_hugepage=never
```

Dans `/proc/meminfo`, la ligne `AnonHugePages` doit donc valoir 0.


#### Configuration du système de fichiers

Quel que soit le système d’exploitation, les systèmes de fichiers ne manquent pas. Linux en est la preuve avec pas moins d’une dizaine de systèmes de fichiers. Le choix peut paraître compliqué mais il se révèle fort simple : il est préférable d’utiliser le système de fichiers préconisé par votre distribution Linux. Ce système est à la base de tous les tests des développeurs de la distribution : il a donc plus de chances d’avoir moins de bugs, tout en proposant plus de performances. Les instances de production PostgreSQL utilisent de fait soit `ext4`, soit `XFS`, qui sont donc **les systèmes de fichiers recommandés**.

!!! tip "Performances et système de fichier"

    En 2016, [un benchmark sur Linux de Tomas Vondra](https://fr.slideshare.net/fuzzycz/postgresql-na-ext4-xfs-btrfs-a-zfs-fosdem-pgday-2016) de différents systèmes de fichiers montrait que `ext4` et `XFS` ont des **performantes équivalentes**.

Autrefois réservé à Solaris, `ZFS` est un système très intéressant grâce à son panel fonctionnel et son mécanisme de `Copy On Write` permettant de faire une copie des fichiers sans arrêter PostgreSQL (snapshot). [OpenZFS](https://openzfs.org/wiki/Main_Page), son portage sous Linux/FreeBSD, entre autres, est un système de fichiers proposant un panel impressionnant de fonctionnalités (dont : checksum, compression, gestion de snapshot), les performances en écriture sont cependant bien moins bonnes qu’avec `ext4` ou `XFS`. De plus, il est plus complexe à mettre en place et à administrer. `Btrfs` est relativement répandu et bien intégré à Linux, et offre une partie des fonctionnalités de `ZFS` ; mais il est également **peu performant avec PostgreSQL**.

`LVM` permet de rassembler plusieurs partitions dans un même `Volume Group`, puis d’y tailler des partitions (`Logical Volumes`) qui seront autant de points de montage. `LVM` permet de changer les tailles des `LV` à volonté, d’ajouter ou supprimer des disques physiques à volonté dans les `VG`, ce qui simplifie l’administration au niveau PostgreSQL.

!!! info "LVM : le choix gagnant"
    
    **De nos jours, l’impact en performance est négligeable pour la flexibilité apportée.**
    
    Si l’on utilise les snapshots de `LVM`, il faudra vérifier l’impact sur les performances. `LVM` peut même gérer le RAID mais, dans l’idéal, il est préférable qu’une bonne carte RAID s’en charge en dessous.

`NFS` peut sembler intéressant, vu ses fonctionnalités : facilité de mise en œuvre, administration centralisée du stockage, mutualisation des espaces. Cependant, ce système de fichiers est **source de nombreux problèmes avec PostgreSQL**. Si la base tient en mémoire et que les latences possibles ne sont pas importantes, on peut éventuellement utiliser `NFS`. Il faut la garantie que les opérations sont synchrones. Si ce n’est pas le cas, une panne sur la baie peut entraîner une corruption des données. Au minimum, l’option `sync` doit être présente côté serveur et les options `hard, proto=tcp, noac et nointr` doivent être présentes côté client. Si vous souhaitez en apprendre plus sur le sujet des options pour `NFS`, un article détaillé est disponible dans la [documentation de PostgreSQL à partir de la version 12](https://docs.postgresql.fr/current/creating-cluster.html#creating-cluster-nfs).

!!! danger "NFS et PostgreSQL"

    Par contre, `NFS` est totalement déconseillé dans les environnements critiques avec PostgreSQL. Greg Smith, contributeur très connu, spécialisé dans l’optimisation de PostgreSQL, parle plus longuement [des soucis de NFS avec PostgreSQL](https://www.postgresql.org/message-id/4D2285CF.3050304@2ndquadrant.com). En fait, il y a des dizaines d’exemples de gens ayant eu des problèmes avec `NFS`. Les problèmes de performance sont quasi-systématiques, et ceux de fiabilité fréquents, et compliqués à diagnostiquer (comme illustré [dans ce mail](https://www.postgresql.org/message-id/4D40DDB7.1010000@credativ.com), où le problème venait du noyau Linux).

Sous Windows, la question ne se pose pas : `NTFS` est le seul système de fichiers assez stable. L’installeur fourni par EnterpriseDB dispose d’une protection qui empêche l’installation d’une instance PostgreSQL sur une partition `VFAT`.


##### Partitionnement

Nous allons donc configurer notre système avec une structure `LVM` (Logical Volume Manager).

Voici la liste des partitions et la structure LVM créée :

``` bash
root@vm-postgres:~# lsblk 
NAME                       MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                          8:0    0 223.6G  0 disk 
├─sda1                       8:1    0  1007K  0 part 
├─sda2                       8:2    0     1G  0 part 
├─sda3                       8:3    0    79G  0 part 
│ ├─pve-swap               253:2    0     2G  0 lvm  [SWAP]
│ ├─pve-root               253:3    0  31.2G  0 lvm  /
│ ├─pve-data_tmeta         253:4    0     1G  0 lvm  
│ │ └─pve-data-tpool       253:6    0    34G  0 lvm  
│ │   └─pve-data           253:7    0    34G  1 lvm  
│ └─pve-data_tdata         253:5    0    34G  0 lvm  
│   └─pve-data-tpool       253:6    0    34G  0 lvm  
│     └─pve-data           253:7    0    34G  1 lvm  
└─sda4                       8:4    0 143.6G  0 part 
  ├─fast1-vm--100--disk--0 253:0    0    22G  0 lvm  
  └─fast1-vm--100--disk--1 253:1    0   100G  0 lvm
```

La partition `/var/lib/postgresql` contient les fichiers de PostgreSQL. Le sous-répertoire `/var/lib/postgresql/data` contient le répertoire principal des données. La variable d'environnement `PGDATA` devra pointer vers ce répertoire. La partition `/var/lib/postgresql/wal` contient uniquement les journaux de transactions de PostgreSQL. Il est généralement conseillé de séparer fichiers de données et journaux de transactions dans des partitions différentes, nous le faisons donc ici. Il est aussi généralement conseillé de déplacer les journaux applicatifs de PostgreSQL dans une partition séparée. Cela se fera dans le chapitre sur la configuration, `/var/log/postgresql` étant le répertoire choisi, ce dernier dépendant de la partition `/var`.

Au cas où vous voudriez installer une version antérieure à la 15, les statistiques d’activités sont stockées sur disque et il est généralement préférable de les placer sur un ramdisk pour gagner en performances. Ce n’est plus le cas en version 15 vu que les métriques sont conservées en mémoire pendant toute la durée d’exécution du serveur.

Même si tous les exemples se basent sur Debian, les commandes doivent être utilisables sur toute distribution, quelle que soit sa version.


##### Option `noatime`

Sur les systèmes le supportant, la configuration `noatime` évite l’écriture de l’horodatage du dernier accès au fichier.

`nodiratime` fait de même au niveau du répertoire. Depuis plusieurs années maintenant, `nodiratime` est inclus dans `noatime`.

!!! tip "`dir_index`"

    Pour aller plus loin, l'option `dir_index` permet de modifier la méthode de recherche des fichiers dans un répertoire en utilisant un index spécifique pour accélérer cette opération. L’outil `tune2fs` permet de s’assurer que cette fonctionnalité est activée ou non.

Par exemple, pour une partition /dev/sda1 :
``` bash
root@vm-postgres:~# sudo tune2fs -l /dev/sda1 | grep features
Filesystem features:      has_journal resize_inode **dir_index** filetype
                          needs_recovery sparse_super large_file
```

`dir_index` est activé par défaut sur `ext3` et `ext4`. Il ne pourrait être absent que si le système de fichiers était originellement un système ext2, qui aurait été mal migré.

Pour l’activer, il faut utiliser l’outil `tune2fs`. Par exemple :
``` bash
root@vm-postgres:~# sudo tune2fs -O dir_index /dev/sda1
```

Enfin, il reste à créer ces index à l’aide de la commande `e2fsck` :
``` bash
root@vm-postgres:~# sudo e2fsck -D /dev/sda1
``` 


#### Autres options relatives aux performances de PostgreSQL

Pour finir et pour notre culture générale, voici d'autres paramètres relatifs aux performances de PostgreSQL mais qui ont un effet très peu significatif sur le gain de performances du serveur. Je ne les détaillerai pas dans cet article mais en voici la liste pour les curieux et curieuses :

``` vim
vm.dirty_background_bytes
vm.dirty_background_ratio
vm.dirty_bytes
vm.dirty_ratio
vm.nr_hugepages
vm.nr_overcommit_hugepages
vm.overcommit_ratio
vm.swappinesss
vm.zone_reclaim_mode
```

Si vous souhaitez aller plus loin, je vous conseille de lire l'excellente documentation sur [PostgreSQL et ses performances](https://public.dalibo.com/exports/formation/manuels/formations/perf1/perf1.handout.html) fournit par [Dalibo](https://www.dalibo.com/) sur laquelle j'ai pioché quelques extraits pour détailler cette doc.


## __Installation du dépôt de la communauté__

PostgreSQL est disponible dans toutes les versions Debian par défaut. Cependant, Debian "snapshot" une version spécifique de PostgreSQL qui est ensuite prise en charge tout au long la durée de vie de cette version Debian. 

Si la version incluse dans notre version de Debian n'est pas celle que l'on souhaite, on peut utiliser le dépôt de paquets de la communauté PostgreSQL. Les mises à jour, majeures et mineures, sont souvent disponibles bien plus rapidement. C'est d'autant plus important pour les mises à jour mineures comprenant des failles de sécurité. Il est essentiel de les mettre à jour dès l'annonce de la sortie de versions mineures. 

Pour configurer manuellement le référentiel `Apt` sur notre Debian, suivez les étapes suivantes :
[https://www.postgresql.org/download/linux/debian/](https://www.postgresql.org/download/linux/debian/)
``` bash
# Importer la clé de signature du référentiel
user@vm-postgres:~# sudo apt install curl ca-certificates
user@vm-postgres:~# sudo install -d /usr/share/postgresql-common/pgdg
user@vm-postgres:~# sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Créez le fichier de configuration du référentiel
user@vm-postgres:~# sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Mettre à jour les listes de paquets
user@vm-postgres:~# sudo apt update
```

Le dépôt contient de nombreux ensembles différents, y compris des tiers, addons. Les paquets les plus courants et les plus importants sont :

| **Paquet**                  | **Description**                                                                |
|-----------------------------|--------------------------------------------------------------------------------|
| postgresql-16               | Noyau du serveur de base de données PostgreSQL                                 |
| postgresql-client-16        | Bibliothèques clientes et binaires clients                                     |
| postgresql-doc-16           | Documentation                                                                  |
| libpq-dev                   | Bibliothèques et en-têtes pour le développement du frontend de la langue C     |
| postgresql-server-dev-16    | Bibliothèques et en-têtes pour le développement de l'arrière-plan de langage C |
| postgresql-16-postgis-3[^1] | Prise en charge des objets géographiques pour PostgreSQL                       |
| postgresql-16-pgrouting[^2] | Prise en charge de la fonction itinéraire pour PostgreSQL/PostGIS              |

[^1]: Seulement si vous avez besoin de la prise en charge des objets géographiques pour PostgreSQL
[^2]: Seulement si vous avez besoin de la prise en charge de la fonction itinéraire pour PostgreSQL/PostGIS

## __Installation des paquets__

Nous allons donc installer plusieurs paquets pour PostgreSQL :

``` bash
# Installez la dernière version de PostgreSQL
# Si vous voulez une version spécifique, utilisez 'postgresql-16'
# ou similaire au lieu de 'postgresql'
root@vm-postgres:~# apt install \
    postgresql-16 \
    postgresql-client-16 \
    postgresql-doc-16 \
    libpq-dev \
    postgresql-server-dev-16 \
    postgresql-16-postgis-3 \
    postgresql-16-pgrouting
```


## __Configuration du service__

Comme nous allons placer le répertoire de données dans un répertoire autre que l'habituel `/var/lib/postgresql/16/data`, il nous faut modifier la configuration du service.

À cette fin, il faut créer un fichier `override.conf` qui va permettre, comme son nom l’indique, de surcharger la configuration par défaut. Cela se fait avec les deux commandes suivantes :
``` bash
root@vm-postgres:~# mkdir -p /etc/systemd/system/postgresql-16.service.d
root@vm-postgres:~# cat > /etc/systemd/system/postgresql-16.service.d/override.conf <<_EOF_
[Service]
Environment=PGDATA=/srv/data
_EOF_
```


## __Initialisation du répertoire de données__

Maintenant, il nous faut préparer le répertoire des fichiers de données et celui des journaux de transactions :

``` bash
root@vm-postgres:~# install -d -o postgres -g postgres -m 700 /srv/data
root@vm-postgres:~# rm -rf /srv/wal/lost+found/
root@vm-postgres:~# chown -R postgres:postgres /srv/wal
```

Enfin, nous pouvons initialiser le répertoire des données :
``` bash
root@vm-postgres:~# PGSETUP_INITDB_OPTIONS="--data-checksums --waldir /srv/wal" /usr/pgsql-15/bin/postgresql-15-setup initdb
```

L'option `--data-checksums` permet d'activer les sommes de contrôle sur les fichiers de données. Ces sommes de contrôle permettent d’être prévenu en cas de corruption dans les fichiers de données. L'option `--waldir` permet d'indiquer un autre répertoire de stockage pour les journaux de transactions.

La commande `initdb` va créer les répertoires et fichiers nécessaires pour pouvoir démarrer PostgreSQL. Ces fichiers étant créés, il ne nous reste plus qu'à activer le service et le démarrer.


## __Activation et démarrage du service__

L’activation et le démarrage sont deux commandes séparées pour systemd. Le service PostgreSQL pour ce dernier étant configuré, il ne reste plus qu’à les exécuter :

``` bash
root@vm-postgres:~# systemctl enable postgresql-16
root@vm-postgres:~# systemctl start postgresql-16
```

## Configuration de l’utilisateur système ***postgres***

Ce rôle n’a pas de mot de passe par défaut. Ajoutez-en un si vous le souhaitez :
``` bash
root@vm-postgres:~# passwd postgres
```

Ajoutez surtout dans le fichier d’initialisation de session (`.profile, .bash_profile, ou autre`) la configuration de la variable d’environnement `PGDATA`.

Celle-ci doit pointer vers le répertoire d’installation de PostgreSQL :
``` bash
root@vm-postgres:~# export PGDATA=/srv/data
```

À noter que l'installation de `posgtreSQL` via les paquets le fait bien, cependant le répertoire indiqué pointe vers le répertoire par défaut (`/var/lib/poistgresql/16/data`), et non pas vers le répertoire personnalisé que nous avons choisi.

Il est aussi intéressant de modifier la variable d’environnement `PATH` pour pointer vers les binaires de PostgreSQL, soit :
``` bash
root@vm-postgres:~# export PATH=/usr/pgsql-16/bin:$PATH
```

## Conclusion

Et voilà, cela conclut l'installation de PostgreSQL sur un serveur Debian. Maintenant, l'étape suivante est de la configurer un minimum. Ce sera l'objet du prochain article de cette série.