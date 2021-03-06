--1
--A
select lpad('-', 2 * (level - 1), '|-') || t.owner || '.' || t.type_name || ' (FINAL:' || t.final ||
       ', INSTANTIABLE:' || t.instantiable || ', ATTRIBUTES:' || t.attributes || ', METHODS:' || t.methods || ')'
from all_types t
start with t.type_name = 'ST_GEOMETRY'
connect by prior t.type_name = t.supertype_name
       and prior t.owner = t.owner;

--B

select distinct m.method_name
from all_type_methods m
where m.type_name like 'ST_POLYGON'
  and m.owner = 'MDSYS'
order by 1;

--C

CREATE TABLE MYST_MAJOR_CITIES
(
    FIPS_CNTRY VARCHAR2(2),
    CITY_NAME  VARCHAR2(40),
    STGEOM     ST_POINT
);

--D
INSERT INTO MYST_MAJOR_CITIES(FIPS_CNTRY, CITY_NAME, STGEOM)
SELECT fips_cntry, city_name, TREAT(ST_POINT.FROM_SDO_GEOM(GEOM) as ST_POINT) STGEOM
FROM MAJOR_CITIES
;

--2
--A
INSERT INTO MYST_MAJOR_CITIES
VALUES ('PL', 'Szczyrk', TREAT(ST_POINT.FROM_WKT('POINT (19.036107 49.718655)') as ST_POINT));

--B
SELECT r.NAME, r.GEOM.GET_WKT() WKT
FROM RIVERS r;

--C
SELECT SDO_UTIL.TO_GMLGEOMETRY(a.STGEOM.GET_SDO_GEOM()) GML
FROM MYST_MAJOR_CITIES a
WHERE CITY_NAME = 'Szczyrk';

--3
--A
CREATE TABLE MYST_COUNTRY_BOUNDARIES
(
    FIPS_CNTRY VARCHAR2(2),
    CNTRY_NAME VARCHAR2(40),
    STGEOM     ST_MULTIPOLYGON
);

--B
INSERT INTO MYST_COUNTRY_BOUNDARIES(FIPS_CNTRY, CNTRY_NAME, STGEOM)
SELECT FIPS_CNTRY, CNTRY_NAME, ST_MULTIPOLYGON(GEOM) STGEOM
FROM COUNTRY_BOUNDARIES;

--C
SELECT r.STGEOM.ST_GEOMETRYTYPE() TYPE, COUNT(*)
FROM MYST_COUNTRY_BOUNDARIES r
GROUP BY r.STGEOM.ST_GEOMETRYTYPE();

--D
SELECT B.CNTRY_NAME, B.STGEOM.ST_ISSIMPLE()
FROM MYST_COUNTRY_BOUNDARIES B;

--4
--A
-- szczyrk znajduje sie w innej geometrii

DELETE
FROM MYST_MAJOR_CITIES
WHERE CITY_NAME = 'Szczyrk';

INSERT INTO MYST_MAJOR_CITIES
VALUES ('PL', 'Szczyrk', TREAT(ST_POINT.FROM_WKT('POINT (19.036107 49.718655)', 8307) as ST_POINT));

SELECT co.CNTRY_NAME, count(co.CNTRY_NAME)
FROM myst_country_boundaries co,
     myst_major_cities ci
WHERE ci.STGEOM.ST_WITHIN(co.STGEOM) = 1
GROUP BY co.CNTRY_NAME
;

--B
SELECT a.CNTRY_NAME
FROM MYST_COUNTRY_BOUNDARIES a,
     (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Czech Republic') b
WHERE b.STGEOM.ST_TOUCHES(a.STGEOM) = 1
;

--C
SELECT DISTINCT c.CNTRY_NAME, NAME
FROM RIVERS r,
     (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Czech Republic') c
WHERE ST_INTERSECTS(r.GEOM, c.STGEOM) = 'TRUE';

--D
SELECT ROUND(TREAT(s.STGEOM.ST_UNION(c.STGEOM) as ST_POLYGON).ST_AREA())
FROM (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Slovakia') s,
     (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Czech Republic') c
;

SELECT *
FROM MYST_MAJOR_CITIES;
SELECT *
FROM WATER_BODIES;
--E
SELECT c.STGEOM.ST_DIFFERENCE(ST_GEOMETRY(s.GEOM)).ST_GEOMETRYTYPE()
FROM (SELECT * FROM WATER_BODIES WHERE NAME = 'Balaton') s,
     (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Czech Republic') c

--5

--A
SELECT pl.CNTRY_NAME, count(*)
FROM MYST_MAJOR_CITIES c,
     (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland') pl
WHERE SDO_WITHIN_DISTANCE(c.STGEOM, pl.STGEOM, 'distance=100 unit=km') = 'TRUE'
GROUP BY pl.CNTRY_NAME;

--B
INSERT INTO USER_SDO_GEOM_METADATA
VALUES ('MYST_MAJOR_CITIES',
        'STGEOM',
        MDSYS.SDO_DIM_ARRAY(
                MDSYS.SDO_DIM_ELEMENT('X', 12.8549994, 26.3166674, 1),
                MDSYS.SDO_DIM_ELEMENT('Y', 45.8680002, 57.7859992, 1)
            ),
        8307);

INSERT INTO USER_SDO_GEOM_METADATA
VALUES ('MYST_COUNTRY_BOUNDARIES',
        'STGEOM',
        MDSYS.SDO_DIM_ARRAY(
                MDSYS.SDO_DIM_ELEMENT('X', 12.603676, 26.369824, 1),
                MDSYS.SDO_DIM_ELEMENT('Y', 45.8464, 58.0213, 1)
            ),
        8307);

--C
CREATE INDEX myst_major_cities_idx
    ON MYST_MAJOR_CITIES (STGEOM)
    INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;

CREATE INDEX myst_country_boundaries_idx
    ON MYST_COUNTRY_BOUNDARIES (STGEOM)
    INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;


--D
SELECT pl.CNTRY_NAME, count(*)
FROM MYST_MAJOR_CITIES c,
     (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland') pl
WHERE SDO_WITHIN_DISTANCE(c.STGEOM, pl.STGEOM, 'distance=100 unit=km') = 'TRUE'
GROUP BY pl.CNTRY_NAME;

EXPLAIN PLAN FOR
SELECT pl.CNTRY_NAME, count(*)
FROM MYST_MAJOR_CITIES c,
     (SELECT * FROM MYST_COUNTRY_BOUNDARIES WHERE CNTRY_NAME = 'Poland') pl
WHERE SDO_WITHIN_DISTANCE(c.STGEOM, pl.STGEOM, 'distance=100 unit=km') = 'TRUE'
GROUP BY pl.CNTRY_NAME;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
