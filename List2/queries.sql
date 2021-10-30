--1
create table movies
(
    id        number(12) PRIMARY KEY,
    title     varchar2(400) not null,
    category  varchar2(50),
    year      char(12),
    cast      varchar2(4000),
    director  varchar2(4000),
    story     varchar2(4000),
    price     number(5, 2),
    cover     BLOB,
    MIME_TYPE VARCHAR2(50)
);

--2
INSERT INTO movies(id, title, category, year, cast, director, story, price, cover, MIME_TYPE)
SELECT a.id,
       a.title,
       a.category,
       a.year,
       a.cast,
       a.director,
       a.story,
       a.price,
       b.image,
       b.mime_type
FROM DESCRIPTIONS a
         LEFT JOIN covers b on a.id = b.movie_id
;
--3
SELECT id, title
FROM movies
WHERE cover IS NULL;
--4
SELECT id, title, dbms_lob.getlength(cover) as filesize
FROM movies
WHERE cover is not null;
--5
SELECT id, title, dbms_lob.getlength(cover) as filesize
FROM movies
WHERE cover is null;
--6
SELECT *
FROM dba_directories;

--7
UPDATE movies
SET cover=EMPTY_BLOB(),
    MIME_TYPE='image/jpeg'
WHERE id = 66;

--8
SELECT id, title, dbms_lob.getlength(cover) as filesize
FROM movies
WHERE id = 65
   or id = 66;

--9
DECLARE
    lobd blob;
    fils BFILE := BFILENAME('ZSBD_DIR', 'escape.jpg');
BEGIN

    SELECT cover
    INTO lobd
    FROM movies
    WHERE id = 66
        FOR UPDATE;
    DBMS_LOB.fileopen(fils, DBMS_LOB.file_readonly);
    DBMS_LOB.LOADFROMFILE(lobd, fils, DBMS_LOB.GETLENGTH(fils));
    DBMS_LOB.FILECLOSE(fils);
    COMMIT;
END;

--10

CREATE TABLE TEMP_COVERS
(
    movie_id  NUMBER(12),
    image     BFILE,
    mime_type VARCHAR2(50)
);

--11
INSERT INTO TEMP_COVERS
VALUES (65, BFILENAME('ZSBD_DIR', 'eagles.jpg'), 'image/jpeg');

--12
SELECT movie_id, dbms_lob.getlength(image) as filesize
FROM TEMP_COVERS;

--13
DECLARE
    bf   bfile;
    lobd blob;
    mt   varchar2(50);
BEGIN
    SELECT image, mime_type
    INTO bf, mt
    FROM TEMP_COVERS
    WHERE movie_id = 65;
    dbms_lob.createtemporary(lobd, TRUE);
    DBMS_LOB.fileopen(bf, DBMS_LOB.file_readonly);
    DBMS_LOB.LOADFROMFILE(lobd, bf, DBMS_LOB.GETLENGTH(bf));
    DBMS_LOB.FILECLOSE(bf);
    UPDATE movies
    SET cover=lobd,
        mime_type=mt
    WHERE id = 65;

    dbms_lob.freetemporary(lobd);


    COMMIT;
END;

--14
SELECT id, title, dbms_lob.getlength(cover) as filesize
FROM movies
WHERE id = 65
   or id = 66;

--15
DROP TABLE movies;
DROP TABLE TEMP_COVERS;