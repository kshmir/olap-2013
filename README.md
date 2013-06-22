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


2. En Windows:

- Instalar PostgreSQL 9.0/9.1/9.2 (32/64 bits) (Recomendado 9.0)
- Instalar PostGIS
- Ejecutar el script de instalacion de postgis.
- Instalar python 2.6: (32 bits: http://www.python.org/ftp/python/2.6/python-2.6.msi, 64 bits: http://www.python.org/ftp/python/2.6/python-2.6.amd64.msi)
- Instalar shapely: (32 bits: https://pypi.python.org/packages/2.6/S/Shapely/Shapely-1.2.17.win32-py2.6.exe#md5=88669f37acf9969befaa3ec6a96a0e74, 64 bits: https://pypi.python.org/packages/2.6/S/Shapely/Shapely-1.2.17.win-amd64-py2.6.exe#md5=c950fd3cb1acfc85ca0d54036819284a)
- Copiar la libreria libpython.dll de C:/Python26/ a la carpeta libs y la carpeta bin de la instalación de PostgreSQL
- Todas las librerias deben ser siempre de 32 o 64 bits.
- En el caso de 9.1 y 9.2, utilizar (este dll)[http://cl.ly/1c1b1l0d380G] y copiarlo en la carpeta libs de postgresql.

3. Común:

- Correr los scripts en scripts.sql:
  - `CREATE LANGUAGE plpythonu;` es necesario para que funcionen.
  - Cada función hecha con plpythonu (st_intersection, st_nearcentroid_union, st_nearcentroid_find) lleva su(s) correspondiente(s) funciones de agregación, en este caso, son st_intersects y st_nearcentroid.
  - Una vez creadas esas 5 funciones es posible ejecutar st_intersects y st_nearcentroid como si fuesen funciones de sql.
