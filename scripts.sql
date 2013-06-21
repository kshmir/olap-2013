-- Inicialización de Tabla de Ejemplo

-- CREATE
CREATE LANGUAGE plpythonu; 
CREATE table geomtable(the_geom geometry, id int);

-- DROP
DROP TABLE geomtable;

-- Punto 1: Intersects

-- CREATE

---- Función Python que contiene la logica
CREATE OR REPLACE FUNCTION st_intersection(base geometry, geom geometry)
  RETURNS geometry AS
$BODY$
 import shapely
 from shapely.wkb import loads 
 if base == None: 
   return geom
 else:
   shape1 = loads(base.decode('hex'))
   shape2 = loads(geom.decode('hex'))
   result = shape1.intersection(shape2)
   return result.wkb.encode('hex')
$BODY$
  LANGUAGE plpythonu VOLATILE
  COST 100;
ALTER FUNCTION st_intersection(geometry, geometry)
  OWNER TO postgres;

---- Agregación de función
CREATE AGGREGATE st_intersects (
  sfunc=st_intersection,
  stype=geometry,
  basetype=geometry
);


-- DROP de intersection e intersects
DROP FUNCTION st_intersection(geometry, geometry) CASCADE;


-- Punto 2: Nearcentroid

---- CREATE BEGIN

CREATE OR REPLACE FUNCTION st_nearcentroid_union(base geometry, geom geometry)
  RETURNS geometry AS
$BODY$
 import shapely
 from shapely.wkb import loads 
 if base == None: 
   return geom
 else:
   shape1 = loads(base.decode('hex'))
   shape2 = loads(geom.decode('hex'))
   result = shape1.union(shape2)
   return result.wkb.encode('hex')
$BODY$
  LANGUAGE plpythonu VOLATILE
  COST 100;
ALTER FUNCTION st_intersection(geometry, geometry)
  OWNER TO postgres;

CREATE OR REPLACE FUNCTION st_nearcentroid_find(geom geometry)
  RETURNS geometry AS
$BODY$
import shapely
from shapely.geometry import Polygon, LineString, Point, GeometryCollection, MultiPoint, MultiPolygon, MultiLineString
from shapely.wkb import loads 
from math import atan, cos, sin

def sign(x): 
  return 1 if x >= 0 else -1

def find_min_point_in_coords(minDist, minPoint, p, coords):
  for i in xrange(0,len(coords) - 1):
    p1 = coords[i]       
    p2 = coords[i+1]

    dist = p.distance(LineString(([p1[0], p1[1]],[p2[0], p2[1]])))
    dist1 = p.distance(Point([p1[0], p1[1]]))
    dist2 = p.distance(Point([p2[0], p2[1]]))

    if (dist < minDist or dist1 < minDist or dist2 < minDist):
      # If the distance we have is at one end of the points...
      if (dist == dist1 or dist == dist2):
        if dist1 < dist2:
          m = dist1
          _v = [p1[0] - p.x, p1[1] - p.y]
        else:
          _v = [p2[0] - p.x, p2[1] - p.y]
          m = dist2
      else:
      # Otherwise the closest point it in the middle...
        _v = [p2[1] - p1[1], -(p2[0] - p1[0])]
        m = dist

      # The sign of the vector is the direction where we must move the centroid to
      dX = sign(_v[0])
      dY = sign(_v[1])

      try:
        tita = atan(_v[1]/_v[0])  
      except Exception, e:
        tita = atan(float('inf'))

      # This makes pX + alpha * cosine * direction
      # Same for Y.
      pX = dX * abs(cos(tita)) * dist + p.x;
      pY = dY * abs(sin(tita)) * dist + p.y;
      minPoint = Point(pX, pY)
      minDist = m
  return minDist, minPoint

def nearestInner(minDist, minPoint, p, geometry):
  coords = None
  if isinstance(geometry, Polygon):
    coords = geometry.exterior.coords
  elif isinstance(geometry, LineString):
    coords = geometry.coords
  elif isinstance(geometry, Point):
    if (p.distance(geometry) < minDist):
      return p.distance(geometry), geometry
  elif isinstance(geometry, MultiPoint) or \
    isinstance(geometry, MultiLineString) or \
    isinstance(geometry, MultiPolygon) or \
    isinstance(geometry, GeometryCollection):
    for geom in geometry.geoms:
      minDist, minPoint = nearestInner(minDist, minPoint, p, geom)

  if coords != None:
    minDist, minPoint = find_min_point_in_coords(minDist, minPoint, p, coords)

  if (hasattr(geometry, 'interiors')):
    for interior in geometry.interiors:
      minDist, minPoint = find_min_point_in_coords(minDist, minPoint, p, interior.coords)      
 
  return minDist, minPoint

def nearest(p, geometry):
  minDist = float('inf')
  minPoint = None
  minDist, minPoint = nearestInner(minDist, minPoint, p, geometry)
  return minDist, minPoint
  
shape = loads(geom.decode('hex'))
centroid = shape.centroid
dist = shape.distance(centroid)
if dist == 0.0:
  return centroid
else:
  d,p = nearest(centroid, shape)
  return p
$BODY$
  LANGUAGE plpythonu VOLATILE
  COST 100;

CREATE AGGREGATE st_nearcentroid (
  sfunc=st_nearcentroid_union,
  stype=geometry,
  basetype=geometry,
  finalfunc=st_nearcentroid_find
);

---- CREATE END

---- DROP
DROP FUNCTION st_nearcentroid_union(geometry, geometry) CASCADE;
DROP FUNCTION st_nearcentroid_find(geometry) CASCADE;

---- DEMO DATA

-- Intersecting everything gives empty
INSERT INTO geomtable values('POINT (-289.70236371968144 -41.60196343188081)',1);
INSERT INTO geomtable values('POINT (-291.09552052262677 -225.49866142066088)',1);
INSERT INTO geomtable values('POINT (0.0742512929416675 -122.40505800270842)',1);
INSERT INTO geomtable values('POINT (-174.0703490752213 -90.36245153496644)',1);
INSERT INTO geomtable values('POINT (-261.8392276607754 -97.32823554969295)',1);
INSERT INTO geomtable values('POINT (-112.77144974562792 -180.91764372641117)',1);


-- Intersecting these things gives a line
INSERT INTO geomtable values('LINESTRING (-451.3085528613367 -164.19976209106753, 59.97999381958972 54.52585597134513, -462.4538072848991 379.13139105760087, 229.94512377891675 500.33603291384225, 174.2188516611046 53.13269916839983, -387.2233399258527 67.06426719785287, 142.17624519336263 582.5322842876152, -373.29177189639967 650.796967631935, -144.8140562133699 -332.77173524744927)',1);
INSERT INTO geomtable values('POLYGON ((-259.0529140548848 565.8144026522715, -27.788884765964404 165.9784002069694, 143.56940199630793 341.51615737807765, 137.9967747845267 464.11395603726436, -31.968355174800312 575.5665002728887, -259.0529140548848 565.8144026522715))',1);
INSERT INTO geomtable values('POLYGON ((-328.71075420215 515.6607577462406, -222.8308371783069 317.8324917280075, -47.293080007198654 446.00291759897544, -80.72884327788594 512.87444414035, -328.71075420215 515.6607577462406))',1);


-- Works with centroid

INSERT INTO geomtable values('POLYGON ((-438.7032620641639 658.5990862352536, -437.4526080883858 571.0533079307828, -397.43168086348487 594.8157334705678, -411.81420158493364 644.8418925016939, -416.81681748804624 670.480299005146, -426.19672230638236 664.2270291262553, -438.7032620641639 658.5990862352536))',1);
INSERT INTO geomtable values('POLYGON ((-418.6927984517135 691.1160896054855, -428.0727032700496 654.8471243079191, -400.5583158029302 634.2113337075796, -373.0439283358109 682.3615117750385, -418.6927984517135 691.1160896054855))',1);
INSERT INTO geomtable values('POLYGON ((-351.1574837596932 702.997302375378, -396.1810268877067 681.1108577992603, -396.1810268877067 658.5990862352536, -313.63786448634863 657.9737592473645, -186.6964859448661 678.609549847704, -123.5384601680694 717.3798230968267, -214.2108734119855 723.6330929757175, -351.1574837596932 702.997302375378))',1);
INSERT INTO geomtable values('POLYGON ((-188.57246690853336 743.0182296002788, -204.83096859364935 694.2427245449309, -204.83096859364935 581.0585397370081, -230.46937509710148 500.39135829931723, -165.43536835663753 446.61323734085664, -131.04238402273833 455.36781517130373, -117.91051727706773 500.39135829931723, -188.57246690853336 743.0182296002788))',1);
INSERT INTO geomtable values('POLYGON ((-150.4275206472997 464.74771998963985, -280.4955341282276 464.74771998963985, -327.3950582199083 506.0193011903189, -181.06854305386443 506.644628178208, -150.4275206472997 464.74771998963985))',1);
INSERT INTO geomtable values('POLYGON ((-340.5269249655789 488.5101455294248, -301.1313247285671 518.5258409481004, -368.04131243269825 572.9292888944501, -421.19410640326976 551.6681713062214, -438.7032620641639 512.2725710692097, -408.06223965759915 477.87958673531045, -340.5269249655789 488.5101455294248))',1);
INSERT INTO geomtable values('POLYGON ((-428.6980302579387 526.6550917906584, -377.4212172510344 531.032380705882, -366.79065845692014 591.0637715432333, -391.8037379724832 604.1956382889039, -419.3181254396025 604.1956382889039, -464.341668567616 588.562463591677, -464.9669955555051 541.6629394999962, -428.6980302579387 526.6550917906584))',1);

---- END DEMO DATA