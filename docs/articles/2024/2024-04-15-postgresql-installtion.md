---
title: Installation de PostgreSQL sur un serveur Debian
subtitle: écrit en 2024
authors:
    - Fabien ALLAMANCHE
categories:
    - article
comments: false
date: 2024-04-15
description: test
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
---

# Installation de PostgreSQL sur un serveur Debian

:fontawesome-solid-calendar: Date de publication initiale : 16 avril 2024

!!! abstract "Note de l'auteur"

    Nous commençons une série d’articles qui se veut être un guide pour l'installation, la maintenance et l'utilisation de PostgreSQL.
    
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
- Activation et démarrage du service.

## __Préparation du système d’exploitation__


### Système hôte

Cette installation est basée sur une machine virtuelle `VM` installée avec Debian 12. Il s’agit de la version `netinst`, nom de code `bookworm` pour PC 64 bits (amd64).
Vous pouvez télécharger l'image iso [debian-12.5.0-amd64-netinst.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso).

Aucune option ne sortant de l'ordinaire n'a été utilisée pour l'installation de la distribution.

La VM (sous VirtualBox) comprend :

- 2 vCPU,
- 2 Go de RAM,
- 1 disque de 20 Go non alloué entièrement.

### Partitionnement

Ce dernier a été partitionné et le système `LVM` (Logical Volume Manager) est utilisé.

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

Toutes les commandes de cet article seront à exécuter avec l’utilisateur `root` ou en utilisant la commande `sudo`.

### __Configuration du système d’exploitation__

Il existe plusieurs paramètres du noyau Linux qui sont importants pour PostgreSQL. Un seul concerne sa stabilité, les autres sont plutôt relatifs aux performances.

Linux dispose d’un système qui lui permet d’allouer aux applications plus de mémoire qu’il n’en a réellement.

!!! tip "Overcommit Memory"

    L’idée de base est simple : beaucoup d’applications demandent de la mémoire, sans vraiment l’utiliser. Les applications écrites en Java en sont un exemple typique : beaucoup de mémoire allouée, mais au final peu réellement utilisée. De ce fait, par défaut, Linux accepte de donner plus de mémoire qu’il n’en a.
    
    Cela fonctionne généralement bien. Mais dans certains cas, comme par exemple avec PostgreSQL, cela peut causer de gros problèmes. En effet, si les applications ont la mauvaise idée d’utiliser toute la mémoire qu’elles ont allouée, Linux risque de se retrouver à court de mémoire. Dans ce cas, il décide de tuer les applications les plus consommatrices. 
    
    Et malheureusement, PostgreSQL a tendance à gagner facilement à ce jeu-là. Ce système s’appelle l’**Overcommit Memory** et il convient de le désactiver sur un serveur dédié à PostgreSQL.

Pour cela, il faut configurer le paramètre `vm.overcommit_memory` à la valeur 2. Le mieux revient à créer un fichier nommé `/etc/sysctl.d/S99-postgresql` avec ce contenu :

``` bash
root@vm-postgres:~# vi /etc/sysctl.d/S99-postgresql
```

Ajouter la ligne :
``` vim
vm.overcommit_memory = 2
```

De cette façon, la configuration s’appliquera à chaque démarrage du serveur.


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

Pensez néanmoins à désactiver les Transparent Huge Pages.

#### Désactivation des Transparent Huge Pages

Dans `/proc/meminfo`, la ligne `AnonHugePages` indique des **huge pages** allouées par le mécanisme de Transparent Huge Pages: le noyau Linux a détecté une allocation contiguë de mémoire et l’a convertie en huge pages, indépendamment du mécanisme décrit plus haut. Hélas, les THP ne s’appliquent pas à la mémoire partagée de PostgreSQL.

Les THP sont même contre-productives sur une base de données, à cause de la latence engendrée par la réorganisation par le système d’exploitation. Comme les THP sont activées par défaut, il faut les désactiver au boot via `/etc/crontab` :

``` bash
@reboot  root  echo never > /sys/kernel/mm/transparent_hugepage/enabled
@reboot  root  echo never > /sys/kernel/mm/transparent_hugepage/defrag
```

ou encore dans la configuration de `grub` :
``` vim
transparent_hugepage=never
```

Dans `/proc/meminfo`, la ligne `AnonHugePages` doit donc valoir 0.

#### Configuration du système de fichiers

Quel que soit le système d’exploitation, les systèmes de fichiers ne manquent pas. Linux en est la preuve avec pas moins d’une dizaine de systèmes de fichiers. Le choix peut paraître compliqué mais il se révèle fort simple : il est préférable d’utiliser le système de fichiers préconisé par votre distribution Linux. Ce système est à la base de tous les tests des développeurs de la distribution : il a donc plus de chances d’avoir moins de bugs, tout en proposant plus de performances. Les instances de production PostgreSQL utilisent de fait soit `ext4`, soit `XFS`, qui sont donc **les systèmes de fichiers recommandés**.

En 2016, [un benchmark sur Linux de Tomas Vondra](https://fr.slideshare.net/fuzzycz/postgresql-na-ext4-xfs-btrfs-a-zfs-fosdem-pgday-2016) de différents systèmes de fichiers montrait que `ext4` et `XFS` ont des **performantes équivalentes**.

Autrefois réservé à Solaris, `ZFS` est un système très intéressant grâce à son panel fonctionnel et son mécanisme de Copy On Write permettant de faire une copie des fichiers sans arrêter PostgreSQL (snapshot). [OpenZFS](https://openzfs.org/wiki/Main_Page), son portage sous Linux/FreeBSD, entre autres, est un système de fichiers proposant un panel impressionnant de fonctionnalités (dont : checksum, compression, gestion de snapshot), les performances en écriture sont cependant bien moins bonnes qu’avec `ext4` ou `XFS`. De plus, il est plus complexe à mettre en place et à administrer. `Btrfs` est relativement répandu et bien intégré à Linux, et offre une partie des fonctionnalités de `ZFS` ; mais il est également **peu performant avec PostgreSQL**.

`LVM` permet de rassembler plusieurs partitions dans un même `Volume Group`, puis d’y tailler des partitions (`Logical Volumes`) qui seront autant de points de montage. `LVM` permet de changer les tailles des `LV` à volonté, d’ajouter ou supprimer des disques physiques à volonté dans les `VG`, ce qui simplifie l’administration au niveau PostgreSQL.

 De nos jours, l’impact en performance est négligeable pour la flexibilité apportée. Si l’on utilise les snapshots de `LVM`, il faudra vérifier l’impact sur les performances. `LVM` peut même gérer le RAID mais, dans l’idéal, il est préférable qu’une bonne carte RAID s’en charge en dessous.

`NFS` peut sembler intéressant, vu ses fonctionnalités : facilité de mise en œuvre, administration centralisée du stockage, mutualisation des espaces. Cependant, ce système de fichiers est **source de nombreux problèmes avec PostgreSQL**. Si la base tient en mémoire et que les latences possibles ne sont pas importantes, on peut éventuellement utiliser `NFS`. Il faut la garantie que les opérations sont synchrones. Si ce n’est pas le cas, une panne sur la baie peut entraîner une corruption des données. Au minimum, l’option `sync` doit être présente côté serveur et les options `hard, proto=tcp, noac et nointr` doivent être présentes côté client. Si vous souhaitez en apprendre plus sur le sujet des options pour `NFS`, un article détaillé est disponible dans la base de connaissances Dalibo, et la documentation de PostgreSQL à partir de la version 12.

Par contre, `NFS` est totalement déconseillé dans les environnements critiques avec PostgreSQL. Greg Smith, contributeur très connu, spécialisé dans l’optimisation de PostgreSQL, parle plus longuement [des soucis de NFS avec PostgreSQL](https://www.postgresql.org/message-id/4D2285CF.3050304@2ndquadrant.com). En fait, il y a des dizaines d’exemples de gens ayant eu des problèmes avec `NFS`. Les problèmes de performance sont quasi-systématiques, et ceux de fiabilité fréquents, et compliqués à diagnostiquer (comme illustré [dans ce mail](https://www.postgresql.org/message-id/4D40DDB7.1010000@credativ.com), où le problème venait du noyau Linux).

Sous Windows, la question ne se pose pas : `NTFS` est le seul système de fichiers assez stable. L’installeur fourni par EnterpriseDB dispose d’une protection qui empêche l’installation d’une instance PostgreSQL sur une partition `VFAT`.

Concernant les systèmes de fichiers, faites bien attention à activer l’option `noatime` sur les systèmes le supportant.

Si vous souhaitez aller plus loin, je vous conseille de lire l'excellente documentation sur [PostgreSQL et ses performances](https://public.dalibo.com/exports/formation/manuels/formations/perf1/perf1.handout.html) fournit par [Dalibo](https://www.dalibo.com/) sur laquelle j'ai pioché quelques extraits pour détailler cette doc.


## __Installation du dépôt de la communauté__

En effet, nous n'allons pas utiliser les paquets fournis par la distribution Debian. Nous allons utiliser ceux fournis par la communauté PostgreSQL.

Les mises à jour, majeures et mineures, sont souvent disponibles bien plus rapidement. C'est d'autant plus important pour les mises à jour mineures comprenant des failles de sécurité. Il est essentiel de les mettre à jour dès l'annonce de la sortie de versions mineures. 

Nous allons donc installer la définition du dépôt de la communauté PostgreSQL. Pour un serveur Debian, on procède de cette façon :
``` bash
@reboot  root  echo never > /sys/kernel/mm/transparent_hugepage/enabled
@reboot  root  echo never > /sys/kernel/mm/transparent_hugepage/defrag
```



## __Installation des paquets__

## __Configuration du service__

## __Initialisation du répertoire de données__

## __Activation et démarrage du service__
