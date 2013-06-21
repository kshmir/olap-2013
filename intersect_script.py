import shapely
import numpy as np
from shapely.geometry import *
from math import *

def sign(x): 
  return 1 if x >= 0 else -1

def find_min_point_in_coords(minDist, minPoint, p, coords):
  for i in xrange(0,len(coords) - 1):
    # Set of points
    p1 = coords[i]       
    p2 = coords[i+1]

    # Compare all distances we have.
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


point = Point(40, -20)
geom = MultiPoint([(0, 0), (1, 1), (1,2), (2,2)])
p1 = Polygon([(0,0),(10,0), (5,-5)])
p2 = Polygon([(100,100),(100,120), (50, -50)])
geom = p2.union(geom).union(p1)

minDist, minPoint = nearest(point, geom)

print minPoint