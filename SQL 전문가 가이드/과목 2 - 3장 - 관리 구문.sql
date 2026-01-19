--------------------------------------------------------------------------------
-- 과목 II - 3장 - 관리 구문
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.3.1 DML
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.3.1.1 INSERT
--------------------------------------------------------------------------------
INSERT INTO player (player_id, player_name, team_id,
                    position, height, weight, back_no)
VALUES ('2002007', '박지성', 'K07', 'MF', 178, 73, 7);

INSERT INTO player
VALUES ('2002010', '이청용', 'K07', '', 'BlueDragon', '2002', 'MF', '17',
        NULL, NULL, '1', 180, 69);

INSERT INTO player (player_id, player_name, team_id)
VALUES (
    (SELECT TO_CHAR(MAX(TO_NUMBER(player_id)) + 1) FROM player),
    '홍길동', 'K06');

INSERT INTO team (team_id, region_name, team_name, orig_yyyy, stadium_id)
SELECT REPLACE(team_id, 'K', 'A') AS team_id, region_name,
       region_name || ' 올스타' AS team_name, 2019 AS orig_yyyy, stadium_id
FROM team WHERE region_name IN ('성남', '인천');

INSERT INTO player (player_id, player_name, team_id, position)
SELECT 'A' || SUBSTR(player_id, 2) AS player_id, player_name,
       REPLACE(team_id, 'K', 'K') AS team_id, position
FROM player WHERE team_id IN ('K04', 'K08');

ROLLBACK;
--------------------------------------------------------------------------------
-- 2.3.1.2 UPDATE
--------------------------------------------------------------------------------
UPDATE player SET back_no = 99;

UPDATE player SET position = 'MF' WHERE position IS NULL;

UPDATE team a SET a.address = (SELECT x.address FROM stadium x
                               WHERE x.hometeam_id = a.team_id and 1 = 2)
WHERE a.orig_yyyy > 2000;

UPDATE stadium a SET (a.ddd, a.tel) = (SELECT x.ddd, x.tel FROM team x
                                       WHERE x.team_id = a.hometeam_id);

UPDATE stadium a SET (a.ddd, a.tel) = (SELECT x.ddd, x.tel FROM team x
                                       WHERE x.team_id = a.hometeam_id)
WHERE EXISTS (SELECT 1 FROM team x WHERE x.team_id = a.hometeam_id);

MERGE INTO stadium s USING team t ON (t.team_id = s.hometeam_id)
WHEN MATCHED THEN UPDATE set s.ddd = t.ddd, s.tel = t.tel;

ROLLBACK;
--------------------------------------------------------------------------------
-- 2.3.1.3 DELETE
--------------------------------------------------------------------------------
DELETE FROM player;
ROLLBACK;

DELETE FROM player WHERE position = 'DF' AND join_yyyy < 2010;
ROLLBACK;

DELETE player a WHERE EXISTS (SELECT 1 FROM team x
                              WHERE x.team_id = a.team_id
                                    AND x.orig_yyyy < 1980);

DELETE player WHERE team_id IN (SELECT team_id FROM player
                                GROUP BY team_id HAVING COUNT(*) <= 10);
ROLLBACK;
--------------------------------------------------------------------------------
-- 2.3.1.4 MERGE
--------------------------------------------------------------------------------
CREATE TABLE team_tmp AS
SELECT NVL(b.team_id, 'K' || ROW_NUMBER() OVER
                             (ORDER BY b.team_id, a.stadium_id)) AS team_id,
       SUBSTR(a.stadium_name, 1, 2) AS region_name,
       SUBSTR(a.stadium_name, 1, 2)
           || NVL2(b.team_name, 'FC', '시티즌') AS team_name,
       a.stadium_id, a.ddd, a.tel
FROM stadium a, team b WHERE b.stadium_id(+) = a.stadium_id;

SELECT * FROM team_tmp;

MERGE INTO team t USING team_tmp s ON (t.team_id = s.team_id)
WHEN MATCHED THEN UPDATE SET t.region_name = s.region_name,
                             t.team_name = s.team_name,
                             t.ddd = s.ddd, t.tel = s.tel
WHEN NOT MATCHED THEN
INSERT (t.team_id, t.region_name, t.team_name, t.stadium_id, t.ddd, t.tel)
VALUES (s.team_id, s.region_name, s.team_name, s.stadium_id, s.ddd, s.tel);

MERGE INTO team t USING (SELECT * FROM team_tmp
                         WHERE region_name IN ('성남', '부산', '대구', '전주')) s
ON (t.team_id = s.team_id)
WHEN MATCHED THEN UPDATE SET t.region_name = s.region_name,
                             t.team_name = s.team_name,
                             t.ddd = s.ddd, t.tel = s.tel
WHEN NOT MATCHED THEN
INSERT (t.team_id, t.region_name, t.team_name, t.stadium_id, t.ddd, t.tel)
VALUES (s.team_id, s.region_name, s.team_name, s.stadium_id, s.ddd, s.tel);

ROLLBACK;

MERGE INTO team t USING team_tmp s ON (t.team_id = s.team_id)
WHEN MATCHED THEN UPDATE SET t.region_name = s.region_name,
                             t.team_name = s.team_name,
                             t.ddd = s.ddd, t.tel = s.tel;

MERGE INTO team t USING team_tmp s ON (t.team_id = s.team_id)
WHEN NOT MATCHED THEN
INSERT (t.team_id, t.region_name, t.team_name, t.stadium_id, t.ddd, t.tel)
VALUES (s.team_id, s.region_name, s.team_name, s.stadium_id, s.ddd, s.tel);

ROLLBACK;

DROP TABLE team_tmp;
--------------------------------------------------------------------------------
-- 2.3.2 TCL
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.3.2.2 COMMIT
--------------------------------------------------------------------------------
INSERT INTO player
    (player_id, team_id, player_name, position, height, weight, back_no)
VALUES ('1997035', 'K02', '이운재', 'GK', 182, 82, 1);
COMMIT;

UPDATE player SET height = 100;
COMMIT;

DELETE FROM player;
COMMIT;
--------------------------------------------------------------------------------
-- 2.3.2.3 ROLLBACK
--------------------------------------------------------------------------------
INSERT INTO player
    (player_id, team_id, player_name, position, height, weight, back_no)
VALUES ('1997035', 'K02', '이운재', 'GK', 182, 82, 1);
ROLLBACK;

UPDATE player SET height = 100;
ROLLBACK;

DELETE FROM player;
ROLLBACK;
--------------------------------------------------------------------------------
-- 2.3.2.4 SAVEPOINT
--------------------------------------------------------------------------------
SAVEPOINT svpt1;

ROLLBACK TO svpt1;

SAVEPOINT svpt1;
INSERT INTO player
    (player_id, team_id, player_name, position, height, weight, back_no)
VALUES ('1997035', 'K02', '이운재', 'GK', 182, 82, 1);
ROLLBACK TO svpt1;

SELECT COUNT(*) AS cnt FROM player;
SELECT COUNT(*) AS cnt FROM player WHERE weight = 100;
INSERT INTO player
    (player_id, team_id, player_name, position, height, weight, back_no)
VALUES ('1999035', 'K02', '이운재', 'GK', 182, 82, 1);
SAVEPOINT svpt_a;
UPDATE player SET weight = 100;
SAVEPOINT svpt_b;
DELETE FROM player;

SELECT COUNT(*) AS cnt FROM player;
ROLLBACK TO svpt_b;
SELECT COUNT(*) AS cnt FROM player;

SELECT COUNT(*) AS cnt FROM player WHERE weight = 100;
ROLLBACK TO svpt_a;
SELECT COUNT(*) AS cnt FROM player WHERE weight = 100;

SELECT COUNT(*) AS cnt FROM player;
ROLLBACK;
SELECT COUNT(*) AS cnt FROM player;
--------------------------------------------------------------------------------
-- 2.3.3 DDL
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.3.3.1 CREATE TABLE
--------------------------------------------------------------------------------
DROP table player;
DROP table team;

CREATE TABLE team (
    team_id     CHAR(3)         NOT NULL,
    region_name VARCHAR2(8)     NOT NULL,
    team_name   VARCHAR2(40)    NOT NULL,
    e_team_name VARCHAR2(50),
    orig_yyyy   CHAR(4),
    stadium_id  CHAR(3)         NOT NULL,
    zip_code1   CHAR(3),
    zip_code2   CHAR(3),
    address     VARCHAR2(80),
    ddd         VARCHAR2(3),
    tel         VARCHAR2(10),
    fax         VARCHAR2(10),
    homepage    VARCHAR2(50),
    owner       VARCHAR2(10),
    CONSTRAINT team_pk PRIMARY KEY (team_id)
);

CREATE TABLE player (
    player_id   CHAR(7)         NOT NULL,
    player_name VARCHAR2(20)    NOT NULL,
    team_id     CHAR(3)         NOT NULL,
    e_player_name   VARCHAR2(40),
    nickname        VARCHAR2(30),
    join_yyyy       CHAR(4),
    position        VARCHAR2(10),
    back_no         NUMBER(2),
    nation          VARCHAR2(20),
    birth_date      DATE,
    solar           CHAR(1),
    height          NUMBER(3),
    weight          NUMBER(3),
    CONSTRAINT player_pk PRIMARY KEY (player_id),
    CONSTRAINT player_fk FOREIGN KEY (team_id) REFERENCES team (team_id)
);

-- DESC player;

CREATE TABLE team_temp AS SELECT * FROM team;
--------------------------------------------------------------------------------
-- 2.3.3.2 ALTER TABLE
--------------------------------------------------------------------------------
ALTER TABLE player ADD (address VARCHAR2(80));

-- DESC player;

ALTER TABLE player DROP (address);

ALTER TABLE team_temp MODIFY (
    orig_yyyy VARCHAR2(8) DEFAULT '20020129' NOT NULL);

DROP TABLE team_temp;

-- DESC team_temp;

ALTER TABLE player RENAME COLUMN player_id TO temp_id;
ALTER TABLE player RENAME COLUMN temp_id TO player_id;

ALTER TABLE player DROP CONSTRAINT player_fk;

ALTER TABLE player ADD CONSTRAINT
    player_fk FOREIGN KEY (team_id) REFERENCES team (team_id);

-- ORA-02449: 외래 키에 의해 참조되는 고유/기본 키가 테이블에 있습니다
-- DROP TABLE team;

INSERT INTO team (team_id, region_name, team_name, stadium_id)
VALUES ('K10', '대전', '시티즌', 'D02');

INSERT INTO player (player_id, team_id, player_name, position, height,
                    weight, back_no)
VALUES ('2000003', 'K10', '유동우', 'DF', 177, 70, 40);

COMMIT;

-- ORA-02292: 무결성 제약조건(PLAYER_FK)이 위배되었습니다- 자식 레코드가 발견되었습니다
-- DELETE team WHERE team_id = 'K10';
--------------------------------------------------------------------------------
-- 2.3.3.3 RENAME TABLE
--------------------------------------------------------------------------------
RENAME team TO team_backup;

RENAME team_backup TO team;
--------------------------------------------------------------------------------
-- 2.3.3.4 DROP TABLE
--------------------------------------------------------------------------------
DROP TABLE player;

-- DESC player;
--------------------------------------------------------------------------------
-- 2.3.3.5 TRUNCATE TABLE
--------------------------------------------------------------------------------
TRUNCATE TABLE team;

-- DESC team;

DROP TABLE team;

-- DESC team;
--------------------------------------------------------------------------------
-- 2.3.4 DCL
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.3.4.2 유저와 권한
--------------------------------------------------------------------------------
-- CONN scott/tiger;
-- ORA-01031: 권한이 불충분합니다
CREATE USER sqld IDENTIFIED BY db2019;

GRANT CREATE USER TO scott;
-- CONN scott/tiger;
CREATE USER sqld IDENTIFIED BY db2019;

-- ORA-01045: user SQLD lacks CREATE SESSION privilege; logon denied
-- CONN sqld/db2019;
-- CONN system/manager;
GRANT CREATE SESSION TO sqld;

-- CONN sqld/db2019;
SELECT * FROM user_tables;
-- ORA-01031: insufficient privileges
CREATE TABLE menu (menu_seq NUMBER NOT NULL, title VARCHAR2(10));

-- CONN system/manager;
GRANT CREATE TABLE TO sqld;
-- CONN sqld/db2019;
CREATE TABLE menu (menu_seq NUMBER NOT NULL, title VARCHAR2(10));

-- CONN scott/tiger;
-- ORA-00942: 테이블 또는 뷰가 존재하지 않습니다
SELECT * FROM sqld.menu;

-- CONN sqld/db2019;
INSERT INTO menu VALUES (1, '화이팅');
COMMIT;
GRANT SELECT ON menu TO scott;

-- CONN scott/tiger;
SELECT * FROM sqld.menu;

-- ORA-01031: 권한이 불충분합니다
UPDATE sqld.menu SET title = '코리아' WHERE menu_seq = 1;
--------------------------------------------------------------------------------
-- 2.3.4.3 Role을 이용한 권한 부여
--------------------------------------------------------------------------------
-- CONN system/manager;
REVOKE CREATE SESSION, CREATE TABLE FROM sqld;
-- ORA-01045: user SQLD lacks CREATE SESSION privilege; logon denied
-- CONN sqld/db2019;

-- CONN system/manager;
CREATE ROLE login_table;
GRANT CREATE SESSION, CREATE TABLE TO login_table;
GRANT login_table TO sqld;
-- CONN sqld/db2019;
CREATE TABLE menu (menu_seq NUMBER NOT NULL, title VARCHAR2(10));

-- CONN system/manager;
DROP USER sqld CASCADE;
CREATE USER sqld IDENTIFIED BY db2019;
GRANT CONNECT, RESOURCE TO sqld;
-- CONN sqld/db2019;
CREATE TABLE menu (menu_seq NUMBER NOT NULL, title VARCHAR2(10));