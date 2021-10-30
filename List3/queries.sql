--1
create table DOKUMENTY
(
    id       number(12) primary key,
    dokument clob
);
--2
DECLARE
    long_text CLOB := '';
BEGIN
    FOR a in 1..10000
        LOOP
            long_text := long_text || 'Oto tekst. ';
        end loop;
    INSERT INTO DOKUMENTY VALUES (1, long_text);

end;

--3

select *
from DOKUMENTY;

select UPPER(dokument)
from DOKUMENTY;

select length(dokument)
from DOKUMENTY;

select dbms_lob.getlength(dokument)
from DOKUMENTY;

select substr(dokument, 5, 1000)
from DOKUMENTY;

select dbms_lob.substr(dokument, 1000, 5)
from DOKUMENTY;

--4

INSERT INTO DOKUMENTY
VALUES (2, EMPTY_CLOB());

--5

BEGIN
    INSERT INTO DOKUMENTY VALUES (3, NULL);
    COMMIT;
end;

--7
SELECT *
FROM dba_directories;

--8
DECLARE
    lobd    clob;
    fils    BFILE   := BFILENAME('ZSBD_DIR', 'dokument.txt');
    doffset integer := 1;
    soffset integer := 1;
    langctx integer := 0;
    csid    integer := 0;
    warn    integer := null;
BEGIN
    SELECT dokument
    INTO lobd
    FROM DOKUMENTY
    WHERE ID = 2 FOR UPDATE;
    DBMS_LOB.fileopen(fils, DBMS_LOB.file_readonly);
    DBMS_LOB.LOADCLOBFROMFILE(lobd, fils, DBMS_LOB.LOBMAXSIZE,
                              doffset, soffset, csid, langctx, warn);
    DBMS_LOB.FILECLOSE(fils);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Status operacji: ' || warn);

end;

--9
UPDATE DOKUMENTY
SET DOKUMENT=TO_CLOB(BFILENAME('ZSBD_DIR', 'dokument.txt'), 0, 'text/sml')
WHERE id = 3;

--10
SELECT *
FROM DOKUMENTY;

--11
SELECT id, dokument, dbms_lob.getlength(dokument) as filesize
FROM DOKUMENTY;

--12
DROP TABLE DOKUMENTY;

--13
CREATE OR REPLACE PROCEDURE CLOB_CENSOR(lobd in out clob, word varchar2)
AS
    word_count  number;
    idx         number;
    word_length number;
    buffer VARCHAR2(32767);
BEGIN
    word_count := REGEXP_COUNT(lobd, word);
    word_length := LENGTH(word);
    for a in 1..word_length
    LOOP
        buffer := buffer || '.';
        end loop;

    DBMS_OUTPUT.PUT_LINE(buffer);
    FOR i in 1..word_count
        LOOP
            idx := DBMS_LOB.INSTR(lobd, word, 1, 1);
            DBMS_LOB.WRITE(lobd, word_length, idx, buffer);
        end loop;
end;

--14

CREATE TABLE BIOGRAPHIES AS SELECT * FROM ZSBD_TOOLS.BIOGRAPHIES;
DECLARE
    lobd clob;
BEGIN
    SELECT BIO INTO lobd FROM BIOGRAPHIES WHERE id = 1 FOR UPDATE;
    CLOB_CENSOR(lobd, 'Cimrman');
end;

--15

DROP TABLE BIOGRAPHIES;