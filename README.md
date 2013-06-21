## Trabajo Especial OLAP 2013

- Kevin Kenny
- Cristian Pereyra

### Que contiene:

Este repositorio contiene algunos datos de ejemplo y los scripts programados en pl/python para implementar lo requerido en el TP1 de OLAP Espacial.

### Como utilizar:

1. En ubuntu 12.04:

- Instalar PostgreSQL 9.1
- Instalar PostGIS 
- Ejecutar el script de instalacion de postgis. 
- Instalar Python 2.7: `apt-get install python2.7`
- Instalar PL/Python (permite ejecutar Python en PostgreSQL): `apt-get install postgresql-plpython-9.1`
- Instalar pip (permite instalar dependencias de python fácilmente): `apt-get install python-pip`
- Instalar shapely via pip: `pip install shapely`
- Una vez instalados plpythonu, python y shapely hay que ver el punto 3


2. En windows:

Falta ver como..

3. Común:

- Correr los scripts en scripts.sql:
  - `CREATE LANGUAGE plpythonu;` es necesario para que funcionen.
  - Cada función hecha con plpythonu (st_intersection, st_nearcentroid_union, st_nearcentroid_find) lleva su(s) correspondiente(s) funciones de agregación, en este caso, son st_intersects y st_nearcentroid.
  - Una vez creadas esas 5 funciones es posible ejecutar st_intersects y st_nearcentroid como si fuesen funciones de sql.
