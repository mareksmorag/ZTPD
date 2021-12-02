--1
--A
INSERT INTO USER_SDO_GEOM_METADATA
VALUES ('FIGURY',
        'KSZTALT',
        MDSYS.SDO_DIM_ARRAY(
                MDSYS.SDO_DIM_ELEMENT('X', 0, 8, 0.01),
                MDSYS.SDO_DIM_ELEMENT('Y', 0, 7, 0.01)),
        null);
--B
SELECT SDO_TUNE.ESTIMATE_RTREE_INDEX_SIZE(3000000, 8192, 10, 2, 0)
FROM DUAL;

--C
create index FIGURY_IDX
    on FIGURY (KSZTALT)
    INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;

--D
select ID
from FIGURY
where SDO_FILTER(KSZTALT,
                 SDO_GEOMETRY(2001, null,
                              SDO_POINT_TYPE(3, 3, null),
                              null, null)) = 'TRUE';

--output
-- ID
-- ----------
--  3
--  2
--  1
-- dzieje się tak, dlatego, że sdo_filter daje nam jedynie zbior "kandydatow" dla indexu


--E
SELECT ID
FROM FIGURY
WHERE SDO_RELATE(KSZTALT,
                 SDO_GEOMETRY(2001, null, SDO_POINT_TYPE(3, 3, null), null, null),
                 'mask=ANYINTERACT') = 'TRUE';

--tak, tylko ta figura ma cos wspolnego z punktem 3,3

--2
--A
SELECT A.CITY_NAME, SDO_NN_DISTANCE(1) DISTANCE
FROM MAJOR_CITIES A
WHERE SDO_NN(A.GEOM, (SELECT GEOM FROM MAJOR_CITIES WHERE CITY_NAME = 'Warsaw'), 'sdo_num_res=10 unit=km', 1) = 'TRUE'
  and A.CITY_NAME != 'Warsaw';

--B
select C.CITY_NAME
from MAJOR_CITIES C
where SDO_WITHIN_DISTANCE(C.GEOM,
                          (SELECT GEOM FROM MAJOR_CITIES WHERE CITY_NAME = 'Warsaw'),
                          'distance=100 unit=km') = 'TRUE'
  AND C.CITY_NAME != 'Warsaw';

--C
SELECT CNTRY_NAME, CITY_NAME
FROM MAJOR_CITIES
WHERE SDO_RELATE(
                  (SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME LIKE 'Slovakia'),
                  GEOM,
                  'mask=contains+coveredby') = 'TRUE';

--D
SELECT A.CNTRY_NAME,
       SDO_GEOM.SDO_DISTANCE((SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland'), A.GEOM, 1,
                             'unit=km') AS DISTANCE
FROM COUNTRY_BOUNDARIES A
WHERE SDO_RELATE(
                  (SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland'),
                  geom,
                  'mask=anyinteract'
          ) = 'FALSE';

--3
--A
SELECT A.CNTRY_NAME,
       SDO_GEOM.SDO_LENGTH(
               SDO_GEOM.SDO_INTERSECTION(A.GEOM, (SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland'), 1),
               1, 'unit=km') AS BORDER_LENGTH
FROM COUNTRY_BOUNDARIES A
WHERE SDO_RELATE(
                  (SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland'),
                  geom,
                  'mask=anyinteract'
          ) = 'TRUE'
  and A.CNTRY_NAME != 'Poland';

--B
SELECT A.CNTRY_NAME
FROM (
         SELECT CNTRY_NAME, SDO_GEOM.SDO_AREA(GEOM, 1, 'unit=SQ_KM') AS AREA
         FROM COUNTRY_BOUNDARIES
         ORDER BY AREA DESC) A
WHERE ROWNUM = 1;

--C

SELECT SDO_GEOM.SDO_AREA(SDO_GEOM.SDO_MBR(SDO_GEOM.SDO_UNION(
            (SELECT GEOM FROM MAJOR_CITIES WHERE CITY_NAME = 'Warsaw'),
            (SELECT GEOM FROM MAJOR_CITIES WHERE CITY_NAME = 'Lodz')
    )), 1, 'unit=SQ_KM') AS SQ_KM
FROM DUAL;

--D
SELECT (b.a.GET_DIMS() || b.a.GET_LRS_DIM() || '0' || b.a.GET_GTYPE()) as GTYPE
FROM (
         SELECT SDO_GEOM.SDO_UNION(
                            (SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland'),
                            (SELECT GEOM FROM MAJOR_CITIES WHERE CITY_NAME = 'Prague'),
                            1
                    ) a
         FROM DUAL) b;

--E
SELECT d.CITY_NAME, d.CNTRY_NAME
FROM (
         SELECT c.CITY_NAME, c.CNTRY_NAME, SDO_GEOM.SDO_DISTANCE(c.GEOM, c.CENTER, 1, 'unit=km') DIST
         FROM (
                  SELECT b.CITY_NAME, b.CNTRY_NAME, b.GEOM, a.CENTER
                  FROM MAJOR_CITIES b
                           JOIN
                       (SELECT CNTRY_NAME, SDO_GEOM.SDO_CENTROID(GEOM, 1) CENTER
                        FROM COUNTRY_BOUNDARIES) a
                       ON a.CNTRY_NAME = b.CNTRY_NAME) c
         ORDER BY DIST) d
WHERE ROWNUM = 1
;


--F
SELECT A.NAME,
       SUM(SDO_GEOM.SDO_LENGTH(
               SDO_GEOM.SDO_INTERSECTION(A.GEOM, (SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland'), 1),
               1, 'unit=km')) AS BORDER_LENGTH
FROM RIVERS A
WHERE SDO_RELATE(
                  (SELECT GEOM FROM COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland'),
                  A.GEOM,
                  'mask=anyinteract'
          ) = 'TRUE'
GROUP BY A.NAME;