---
title: Reversement partiel du produit de la taxe foncière sur les ZAE
subtitle: FINANCE - Reversement partiel du produit de la taxe foncière sur les zones d'activités économiques
authors:
    - Fabien ALLAMANCHE
categories:
    - article
comments: false
date: 2024-04-15
description: FINANCE - Reversement partiel du produit de la taxe foncière sur les zones d'activités économiques
icon: material/finance
license: Licence Ouverte / Open Licence - ETALAB
robots: index, follow
tags:
    - Finance
    - Taxe foncière
    - SQL
    - TFPB
    - MAJIC
    - Cadastre
---

# Reversement partiel du produit de la taxe foncière sur les Zones d'Activités Économiques (ZAE)

!!! tip "EXTRAIT DU REGISTRE DES DELIBERATIONS DU CONSEIL COMMUNAUTAIRE"

    Délibération N°15-111 de la séance du 25 juin 2015

## __Préambule__

Les difficultés financières auxquelles sont confrontées les collectivités locales mettent en évidence la modification profonde du modèle économique et fiscal des EPCI et des relations avec les communes. A une période où les recettes fiscales, et donc le financement des actions, dépendaient du dynamisme du tissu économique, a succédé une nouvelle ère où la base locative foncière est devenue le principal socle de fiscalité. 

Le contexte budgétaire imposé aux collectivités locales oblige à s'interroger sur le financement des politiques publiques. Dans ce cadre, les élus communautaires ont conscience que c'est le développement et le renouvellement des bases fiscales qui conditionnera le rythme des dépenses et le choix dans les investissements.

Cette nouvelle situation éclaire le retour fiscal paradoxal et qui n'est pas en rapport avec les investissements respectifs consentis par les communes et l'intercommunalité. 

En effet, alors que c'est l'intercommunalité qui supporte la totalité des dépenses nécessaires à la création de sites économiques, le retour fiscal, qui permet de financer les actions intercommunales dans tous les domaines, se traduit principalement par la CFE tandis que la totalité du produit des taxes foncières généré par ces investissements revient aux communes.

C'est pourquoi il a été décidé d'instaurer un dispositif de partage de la fiscalité sur les sites économiques créés par l'Agglomération, conformément à l'article 29-11 de la Loi n°80-10 du 10 janvier 1980 portant aménagement de la fiscalité directe locale qui prévoit : 

!!! quote "Article 29-11 de la Loi n°80-10 du 10 janvier 1980"

    Lorsqu'un groupement de communes (. . .) crée ou gére une zone d'activités économiques, tout ou partie de la part communale de la taxe foncière sur les propriétés bâties acquittée par les entreprises implantées sur cette zone d'activités peut être affecté au groupement (...) par délibérations concordantes de l'organe de gestion du groupement (...) et de la ou des communes sur le territoire desquelles est installée la zone d'activités économiques.

Pour le territoire de l'Agglomération, le dispositif est institué selon les principes suivants :

- Partage à parts égales du produit annuel de la taxe foncière sur les propriétés bâties pour les opérations résultant d'un investissement de l'Agglomération,
- Partage éventuel du produit de la taxe d'aménagement au cas par cas, afin d'équilibrer le budget prévisionnel d'investissements d'une opération.

Ce dispositif s'appliquera à partir de 2015 (année fiscale de référence), sans effet rétroactif afin de ne pas pénaliser les budgets communaux. Il est également rappelé que ce transfert de produit fiscal entraine une correction symétrique des potentiels fiscaux des communes concernées afin de ne pas pénaliser ces dernières pour le montant de la DGF.

Les sites identifiés (zones entières ou parcelles concernées) feront l'objet de délibérations ultérieures à celle de l'Agglomération par les communes concernées. Une convention relative aux modalités de reversement et sera signée avec la commune pour chaque site identifié.


## __Conventionnement__

### Modalités de versement

Chaque année, le versement au profit de Vienne Condrieu Agglomération sera établi sur la base des taxes foncières sur les propriétés bâties issues des zones concernées par le champ d'application de la convention et encaissées par la commune au cours de l'exercice précédent.

Pour ce faire, un état des versements à opérer établi sur la base des données N-1 sera adressé à la commune par les services de l'Agglomération avant le 15 mars de l'année N. Il sera établi à partir des informations transmises par les services fiscaux, notamment [**via les données MAJIC**](https://www.craig.fr/fr/produit/3655-fichiers-fonciers-majic).


### Modalités de calcul

Le montant du reversement au titre de l'année N est calculé en appliquant à **50%** des bases nettes d'imposition de l'année N-1 des redevables concernés multiplié par le taux de la taxe foncière sur les propriétés bâties voté par la commune pour cette même année (N-1).

!!! tip "Calcul du montant de reversement"

    Montant du reversement (année N) = (Bases nettes d'imposition (année N-1) des sites concernés x %) x taux communal TFPB de l'année nN-1.


### Paiement

Les versements seront établis sur une base annuelle, avec un paiement au 30 juin de chaque année.


### Inscriptions budgétaires

Les reversements de la Taxe Foncière des propriétés Bâties (TFPB) seront imputés en section de fonctionnement en chapitre 014 pour la commune et en chapitre 73 pour Vienne Condrieu Agglomération.


## __Mise en oeuvre SIG__

!!! Abstract "Note"

    La mise en oeuvre de cette application a été réalisé sous [QGIS](https://qgis.org/fr/site/) et en analysant les fichiers fonciers **MAJIC** qui nous sont fournis chaque année.
    
    Par conséquent, chaque année, une révision des titres est effectuée en fonction des nouveaux millésime des données **MAJIC** et des sites conventionnés avec les communes.

### Atlas QGIS

Les titres sont émis grâce à un atlas réalisé sous [QGIS](https://qgis.org/fr/site/) et un modèle d'impression au format A4.

L'atlas vient boucler sur une couche de parcelles identifiée et sur laquelle différentes tables générées sous Postgresql lui sont jointes.


### Les requêtes SQL

Afin de pérenniser au mieux la génération de ces titres qui seront édités chaque année, l'ensemble du projet [QGIS](https://qgis.org/fr/site/) se repose sur l'import des données **MAJIC** via l'extension [Cadastre](https://docs.3liz.org/QgisCadastrePlugin/) de [QGIS](https://qgis.org/fr/site/) développé par la [société 3liz](https://www.3liz.com/).

Ce projet repose sur 2 requêtes SQL en particulier.

Voici la première :
``` sql
DROP TABLE IF EXISTS taxe.majic2023_revenu_cadastral;
CREATE TABLE taxe.majic2023_revenu_cadastral AS
SELECT	RIGHT(cadastre_2023.local00.parcelle,12) AS keypar,
	cadastre_2023.local00.ccodep || cadastre_2023.local00.ccocom AS code_insee,
	cadastre_2023.pev.invar,
	cadastre_2023.pev.ccoaff AS code_affectation,
	CASE
	  WHEN cadastre_2023.pev.ccoaff = 'A' THEN 'Locaux commerciaux et biens divers passibles de la TH'
	  WHEN cadastre_2023.pev.ccoaff = 'B' THEN 'Bâtiment industriel (lié à CCOEVA = A ou E)'
	  WHEN cadastre_2023.pev.ccoaff = 'C' THEN 'Commerce'
	  WHEN cadastre_2023.pev.ccoaff = 'E' THEN 'Locaux commerciaux et biens divers non passibles de la TH ni de la TP'
	  WHEN cadastre_2023.pev.ccoaff = 'H' THEN 'Habitation'
	  WHEN cadastre_2023.pev.ccoaff = 'K' THEN 'Locaux administratifs non passibles de la TH'
	  WHEN cadastre_2023.pev.ccoaff = 'L' THEN 'Hôtel'
	  WHEN cadastre_2023.pev.ccoaff = 'P' THEN 'Professionnel'
	  WHEN cadastre_2023.pev.ccoaff = 'S' THEN 'Biens divers passibles de la TH'
	  WHEN cadastre_2023.pev.ccoaff = 'T' THEN 'Terrain industriel (lié à CCOEVA = A ou E)'
	  ELSE 'Erreur dans la base'::text
	END libelle_affectation,
	cadastre_2023.local10.cconlc AS code_nature_local,
	CASE
	  WHEN cadastre_2023.local10.cconlc = 'AP' THEN 'Appartement'
	  WHEN cadastre_2023.local10.cconlc = 'AT' THEN 'Antenne téléphone'
	  WHEN cadastre_2023.local10.cconlc = 'AU' THEN 'Autoroute'
	  WHEN cadastre_2023.local10.cconlc = 'CA' THEN 'Commerce sans boutique'
	  WHEN cadastre_2023.local10.cconlc = 'CB' THEN 'Local divers'
	  WHEN cadastre_2023.local10.cconlc = 'CD' THEN 'Dépendance commerciale'
	  WHEN cadastre_2023.local10.cconlc = 'CH' THEN 'Chantier'
	  WHEN cadastre_2023.local10.cconlc = 'CM' THEN 'Commerce avec boutique'
	  WHEN cadastre_2023.local10.cconlc = 'DC' THEN 'Dépendance lieux communs'
	  WHEN cadastre_2023.local10.cconlc = 'DE' THEN 'Dépendance bâtie isolée'
	  WHEN cadastre_2023.local10.cconlc = 'LC' THEN 'Local commun'
	  WHEN cadastre_2023.local10.cconlc = 'MA' THEN 'Maison'
	  WHEN cadastre_2023.local10.cconlc = 'ME' THEN 'Maison exceptionnelle'
	  WHEN cadastre_2023.local10.cconlc = 'MP' THEN 'Maison partagée par une limite territoriale'
	  WHEN cadastre_2023.local10.cconlc = 'SM' THEN 'Sol de maison'
	  WHEN cadastre_2023.local10.cconlc = 'U' THEN 'Etablissement industriel (évalué par méthode comptable)'
	  WHEN cadastre_2023.local10.cconlc = 'U1' THEN 'Gare'
	  WHEN cadastre_2023.local10.cconlc = 'U2' THEN 'Gare : triage'
	  WHEN cadastre_2023.local10.cconlc = 'U3' THEN 'Gare : atelier matériel'
	  WHEN cadastre_2023.local10.cconlc = 'U4' THEN 'Gare : atelier magasin'
	  WHEN cadastre_2023.local10.cconlc = 'U5' THEN 'Gare : dépôt - titulaire'
	  WHEN cadastre_2023.local10.cconlc = 'U6' THEN 'Gare : dépôt - réel'
	  WHEN cadastre_2023.local10.cconlc = 'U7' THEN 'Gare : matériel transport'
	  WHEN cadastre_2023.local10.cconlc = 'U8' THEN 'Gare : entretien matériel roulant'
	  WHEN cadastre_2023.local10.cconlc = 'U9' THEN 'Gare : Station usine'
	  WHEN cadastre_2023.local10.cconlc = 'UE' THEN 'Transformateur électrique'
	  WHEN cadastre_2023.local10.cconlc = 'UG' THEN 'Appareil à gaz'
	  WHEN cadastre_2023.local10.cconlc = 'UN' THEN 'Usine nucléaire'
	  WHEN cadastre_2023.local10.cconlc = 'US' THEN 'Etablissement industriel (évalué par méthode particulière)'
	  ELSE 'Erreur dans la base'::text
	END libelle_nature_local,
	cadastre_2023.pev.dsupot AS surface_pondere_m2_pev,
	cadastre_2023.pevprofessionnelle.dsupot AS surface_pondere_m2_pev_pro,
	------------------------------ CALCUL REVERSEMENT -----------------------------------------	
	ROUND(role.tf_header_article_a1_commune_taux.taux_bati_commune,2) AS taux_bati_commune,
	ROUND(role.tf_header_article_a1_commune_taux.taux_nonbati_commune,2) AS taux_nonbati_commune,
	cadastre_2023.pev.dvlpera AS valeur_locative_pev, -- Valeur locative de la PEV, en valeur de l'année
	ROUND(((cadastre_2023.pev.dvlpera)::double precision/2)::numeric) AS revenu_cadastral,
	--cadastre_2023.pevtaxation.co_vlbai, 				-- Commune - Part de VL imposée (valeur70) -
	--cadastre_2023.pevtaxation.co_vlbaia,				-- Commune - Part de VL imposée (valeur de l’année) -
	cadastre_2023.pevtaxation.co_bipevla AS base_imposition_pev_communale,	-- Commune - Base d’imposition de la pev(valeur de l’année)
	--cadastre_2023.pevtaxation.gp_vlbai,				-- Groupement de commune - Part de VL imposée (valeur70) -
	--cadastre_2023.pevtaxation.gp_vlbaia,				-- Groupement de commune - Part de VL imposée (valeur de l’année) -
	--cadastre_2023.pevtaxation.gp_bipevla				-- Groupement de commune - Base d’imposition de la pev(valeur de l’année)
	ROUND(cadastre_2023.pevtaxation.co_bipevla*(role.tf_header_article_a1_commune_taux.taux_bati_commune/100),2) AS tfpb_communale,
	(cadastre_2023.pevtaxation.co_bipevla)::double precision/2 AS demi_base_imposition_pev_communale,
	ROUND(cadastre_2023.pevtaxation.co_bipevla*(role.tf_header_article_a1_commune_taux.taux_bati_commune/100)/2,2) AS demi_tfpb_communale
  FROM cadastre_2023.local00
  INNER JOIN cadastre_2023.pev
    ON cadastre_2023.pev.invar = cadastre_2023.local00.invar
  INNER JOIN cadastre_2023.pevtaxation
    ON cadastre_2023.pevtaxation.invar || cadastre_2023.pevtaxation.dnupev = cadastre_2023.pev.invar || cadastre_2023.pev.dnupev
  INNER JOIN role.tf_header_article_a1_commune_taux
    ON role.tf_header_article_a1_commune_taux.code_insee = cadastre_2023.local00.ccodep || cadastre_2023.local00.ccocom AND role.tf_header_article_a1_commune_taux.millesime = '2023'
  INNER JOIN cadastre_2023.local10
    ON cadastre_2023.local10.invar = cadastre_2023.local00.invar
  LEFT JOIN cadastre_2023.pevprofessionnelle
    ON cadastre_2023.pevprofessionnelle.invar =  cadastre_2023.local00.invar
  ORDER BY RIGHT(cadastre_2023.local00.parcelle,12);
```

!!! tip "Explication"

    Pour l'ensemble des parcelles du territoire de l'Agglomération, on récupère :

    - le code INSEE,
    - le numéro d'invariant du local,
    - le code d'affectation et son libellé,
    - le code de la nature du local et son libellé,
    - la surface pondérée en m² de la partie d'évaluation (PEV),
    - la surface pondérée en m² de la partie d'évaluation (PEV) pour les locaux à titre professionnel,
    - le taux communale sur les propriétés bâties à appliquer sur la Base d’imposition,
    - le taux communale sur les propriétés non bâties à appliquer sur la Base d’imposition,
    - la valeur locative de la PEV, en valeur de l'année,
    - le revenu cadastral (valeur locative/2),
    - la base d’imposition de la pev(valeur de l’année)
    - la part de VL imposée (valeur 70) du groupement de commune,
    - la part de VL imposée (valeur de l’année) du groupement de commune,
    - la base d’imposition de la pev (valeur de l’année) du groupement de commune,
    - le calcul du reversement de la TFPB à 100%,
    - le calcul du reversement de la TFPB à 50%.

    Cette requête se veut assez exhaustive et le champ qui nous intéresse tout particulièrement est **demi_tfpb_communale** qui est le calcul du reversement de la TFPB à 50% au titre du partage du produit de la taxe foncière sur les propriétés bâties pour les sites économiques.


Et la seconde requête SQL :
``` sql
DROP TABLE IF EXISTS taxe.majic2023_revenu_cadastral_reversement_tfpb;
CREATE TABLE taxe.majic2023_revenu_cadastral_reversement_tfpb AS
SELECT	RIGHT(cadastre_2023.parcelle.parcelle,12) AS keypar,
	CASE
	  WHEN SUM(taxe.majic2023_revenu_cadastral.demi_tfpb_communale) IS NULL THEN 0::numeric
	  ELSE SUM(taxe.majic2023_revenu_cadastral.demi_tfpb_communale)
	END reversement
  FROM taxe.majic2023_revenu_cadastral
  RIGHT JOIN cadastre_2023.parcelle
    ON RIGHT(cadastre_2023.parcelle.parcelle,12) = taxe.majic2023_revenu_cadastral.keypar
  GROUP BY taxe.majic2023_revenu_cadastral.keypar, RIGHT(cadastre_2023.parcelle.parcelle,12)
  ORDER BY taxe.majic2023_revenu_cadastral.keypar;

 --ALTER TABLE taxe.majic2023_revenu_cadastral_reversement_tfpb ADD PRIMARY KEY(gid);
 CREATE INDEX idx_majic2023_revenu_cadastral_reversement_tfpb_keypar ON taxe.majic2023_revenu_cadastral_reversement_tfpb USING btree (keypar COLLATE pg_catalog."default");
```

!!! tip "Explication"

    La première requête établit le montant du reversement de la TFPB pour chaque partie d'évaluation se trouvant sur une parcelle (pour une parcelle, on a une relation 0 à N partie d'évaluation).

    Cette seconde requête aggrège l'ensemble des montants du reversement de la TFPB pour avoir la somme global du reversement par parcelle.


## Aperçu d'un titre

<figure markdown="span">
  ![Exemple de titre](/assets/images/articles/finance/reversement-tfpb-titre-sample.jpg){ width="400" }
  <figcaption>Exemple de titre</figcaption>
</figure>