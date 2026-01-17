--------------------------------------------------------------------------------
-- 과목 II - 2장 - SQL 활용
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.1 서브 쿼리
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.1.1 단일 행 서브 쿼리
--------------------------------------------------------------------------------
SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버
FROM player WHERE team_id = (SELECT team_id FROM player
                                            WHERE player_name = '정남일')
ORDER BY player_name;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버
FROM player WHERE height <= (SELECT AVG(height) FROM player)
ORDER BY player_name;
--------------------------------------------------------------------------------
-- 2.2.1.2 다중 행 서브 쿼리
--------------------------------------------------------------------------------
-- ORA-01427: 단일 행 하위 질의에 2개 이상의 행이 리턴되었습니다.
-- SELECT region_name AS 연고지명, team_name AS 팀명, e_team_name AS 영문팀명
-- FROM team WHERE team_id = (SELECT team_id FROM player
--                                           WHERE player_name = '정현수')
-- ORDER BY team_name;

SELECT region_name AS 연고지명, team_name AS 팀명, e_team_name AS 영문팀명
FROM team WHERE team_id IN (SELECT team_id FROM player
                                          WHERE player_name = '정현수')
ORDER BY team_name;
--------------------------------------------------------------------------------
-- 2.2.1.3 다중 칼럼 서브 쿼리
--------------------------------------------------------------------------------
SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키 FROM player
WHERE (team_id, height) IN (SELECT team_id, min(height)
                            FROM player GROUP BY team_id)
ORDER BY team_id, player_name;
--------------------------------------------------------------------------------
-- 2.2.1.4 연관 서브 쿼리
--------------------------------------------------------------------------------
SELECT b.team_name AS 팀명, a.player_name AS 선수명, a.position AS 포지션,
       a.back_no AS 백넘버, a.height AS 키
FROM player a, team b
WHERE a.height < (SELECT AVG(x.height) FROM player x
                  WHERE x.team_id = a.team_id
                  GROUP BY x.team_id)
      AND b.team_id = a.team_id
ORDER BY 선수명;

SELECT a.stadium_id AS id, a.stadium_name AS 경기장명 FROM stadium a
WHERE EXISTS (SELECT 1 FROM schedule x
              WHERE x.stadium_id = a.stadium_id
                    AND x.sche_date BETWEEN '20120501' AND '20120502');
--------------------------------------------------------------------------------
-- 2.2.1.5 그 밖의 위치에서 사용하는 서브 쿼리
--------------------------------------------------------------------------------
SELECT a.player_name AS 선수명, a.height AS 키,
       ROUND((SELECT AVG(x.height) FROM player x
              WHERE x.team_id = a.team_id), 3) AS 팀평균키
FROM player a;

SELECT b.team_name AS 팀명, a.player_name AS 선수명, a.back_no AS 백넘버
FROM (SELECT team_id, player_name, back_no
      FROM player WHERE position = 'MF') a, team b
WHERE b.team_id = a.team_id ORDER BY 선수명;

SELECT player_name AS 선수명, position AS 포지션, back_no AS 백넘버, height AS 키
FROM (SELECT player_name, position, back_no, height
      FROM player WHERE height IS NOT NULL ORDER BY height DESC)
WHERE ROWNUM <= 5;

SELECT a.team_id AS 팀코드, b.team_name AS 팀명, ROUND(AVG(a.height), 3) AS 평균키
FROM player a, team b WHERE b.team_id = a.team_id
GROUP BY a.team_id, b.team_name
HAVING AVG(a.height) < (SELECT AVG(x.height) FROM player x
                        WHERE x.team_id IN (SELECT team_id FROM team
                                            WHERE team_name = '삼성블루윙즈'));
--------------------------------------------------------------------------------
-- 2.2.1.6 뷰
--------------------------------------------------------------------------------
CREATE VIEW v_player_team AS
    SELECT a.player_name, a.position, a.back_no, b.team_id, b.team_name
    FROM player a, team b WHERE b.team_id = a.team_id;

CREATE VIEW v_player_team_filter AS
    SELECT player_name, position, back_no, team_name
    FROM v_player_team WHERE position IN ('GK', 'MF');

SELECT player_name, position, back_no, team_id, team_name
FROM v_player_team WHERE player_name LIKE '황%';

SELECT player_name, position, back_no, team_id, team_name
FROM (SELECT a.player_name, a.position, a.back_no, b.team_id, b.team_name
      FROM player a, team b WHERE b.team_id = a.team_id)
WHERE player_name LIKE '황%';

DROP VIEW v_player_team;

DROP VIEW v_player_team_filter;
--------------------------------------------------------------------------------
-- 2.2.2 집합 연산자
--------------------------------------------------------------------------------
SELECT player_name AS 선수명, back_no AS 백넘버 FROM player WHERE team_id = 'K02'
UNION
SELECT player_name AS 선수명, back_no AS 백넘버 FROM player WHERE team_id = 'K07'
ORDER BY 1;

SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02'
UNION
SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K07';

SELECT DISTINCT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
                back_no AS 백넘버, height AS 키
FROM player WHERE team_id IN ('K02', 'K07');

SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02'
UNION
SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE position = 'GK';

SELECT DISTINCT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
                back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02' OR position = 'GK';

SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02'
UNION ALL
SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE position = 'GK';

SELECT 팀코드, 선수명, 포지션, 백넘버, 키, COUNT(*) AS 중복수
FROM (SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
             back_no AS 백넘버, height AS 키
      FROM player WHERE team_id = 'K02'
      UNION ALL
      SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
             back_no AS 백넘버, height AS 키
      FROM player WHERE position = 'GK')
GROUP BY 팀코드, 선수명, 포지션, 백넘버, 키 HAVING COUNT(*) > 1;

SELECT 'P' AS 구분코드, position AS 포지션, ROUND(AVG(height), 3) AS 평균키
FROM player GROUP BY position
UNION ALL
SELECT 'T' AS 구분코드, team_id AS 팀명, ROUND(AVG(height), 3) AS 평균키
FROM player GROUP BY team_id
ORDER BY 1;

SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02'
MINUS
SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player WHERE position = 'MF'
ORDER BY 1, 2, 3, 4, 5;

SELECT DISTINCT a.team_id AS 팀코드, a.player_name AS 선수명,
                a.position AS 포지션, a.back_no AS 백넘버, a.height AS 키
FROM player a WHERE a.team_id = 'K02'
                    AND NOT EXISTS (SELECT 1 FROM player x
                                    WHERE x.player_id = a.player_id
                                          AND x.position = 'MF')
ORDER BY 1, 2, 3, 4, 5;

SELECT DISTINCT team_id AS 팀코드, player_name AS 선수명,
                position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02'
                  AND player_id NOT IN (SELECT player_id FROM player
                                        WHERE position = 'MF')
ORDER BY 1, 2, 3, 4, 5;

SELECT DISTINCT team_id AS 팀코드, player_name AS 선수명,
                position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02' AND position <> 'MF'
ORDER BY 1, 2, 3, 4, 5;

SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player a WHERE team_id = 'K02'
INTERSECT
SELECT team_id AS 팀코드, player_name AS 선수명, position AS 포지션,
       back_no AS 백넘버, height AS 키
FROM player a WHERE position = 'GK'
ORDER BY 1, 2, 3, 4, 5;

SELECT DISTINCT a.team_id AS 팀코드, a.player_name AS 선수명,
       a.position AS 포지션, a.back_no AS 백넘버, a.height AS 키
FROM player a WHERE a.team_id = 'K02'
                    AND EXISTS (SELECT 1 FROM player x
                                WHERE x.player_id = a.player_id
                                      AND x.position = 'GK')
ORDER BY 1, 2, 3, 4, 5;

SELECT DISTINCT team_id AS 팀코드, player_name AS 선수명,
                position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02'
                  AND player_id IN (SELECT player_id FROM player
                                    WHERE position = 'GK')
ORDER BY 1, 2, 3, 4, 5;

SELECT DISTINCT team_id AS 팀코드, player_name AS 선수명,
                position AS 포지션, back_no AS 백넘버, height AS 키
FROM player WHERE team_id = 'K02' AND position = 'GK'
ORDER BY 1, 2, 3, 4, 5;
--------------------------------------------------------------------------------
-- 2.2.3 그룹 함수
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.3.2 ROLLUP 함수
--------------------------------------------------------------------------------
SELECT b.dname, a.job, COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY b.dname, a.job;

SELECT b.dname, a.job, COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY b.dname, a.job ORDER BY b.dname, a.job;

SELECT b.dname, a.job, COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY ROLLUP (b.dname, a.job);

SELECT b.dname, a.job, COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY ROLLUP (b.dname, a.job)
ORDER BY b.dname, a.job;

SELECT b.dname, GROUPING(b.dname) AS dname_grp,
       a.job, GROUPING(a.job) AS job_grp,
       COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY ROLLUP (b.dname, a.job)
ORDER BY b.dname, a.job;

SELECT CASE GROUPING(b.dname) WHEN 1 THEN 'All Departments'
                              ELSE b.dname END AS dname,
       CASE GROUPING(a.job)   WHEN 1 THEN 'All Jobs'
                              ELSE a.job END AS job,
       COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY ROLLUP (b.dname, a.job)
ORDER BY b.dname, a.job;

SELECT DECODE(GROUPING(b.dname), 1, 'All Departments', b.dname) AS dname,
       DECODE(GROUPING(a.job), 1, 'All Jobs', a.job) AS job,
       COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY ROLLUP (b.dname, a.job)
ORDER BY b.dname, a.job;

SELECT CASE GROUPING(b.dname) WHEN 1 THEN 'All Departments'
                              ELSE b.dname END AS dname,
       CASE GROUPING(a.job)   WHEN 1 THEN 'All Jobs'
                              ELSE a.job END AS job,
       COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY b.dname, ROLLUP (a.job)
ORDER BY b.dname, a.job;

SELECT b.dname, a.job, a.mgr, COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY ROLLUP (b.dname, (a.job, a.mgr))
ORDER BY b.dname, a.job, a.mgr;
--------------------------------------------------------------------------------
-- 2.2.3.3 CUBE 함수
--------------------------------------------------------------------------------
SELECT CASE GROUPING(b.dname) WHEN 1 THEN 'All Departments'
                              ELSE b.dname END AS dname,
       CASE GROUPING(a.job)   WHEN 1 THEN 'All Jobs'
                              ELSE a.job END AS job,
       COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY CUBE (b.dname, a.job) ORDER BY b.dname, a.job;

SELECT dname, job, COUNT(*) AS emp_cnt, SUM(sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno GROUP BY dname, job
UNION ALL
SELECT dname, 'All Jobs' AS job, COUNT(*) AS emp_cnt,
       SUM(sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno GROUP BY dname
UNION ALL
SELECT 'All Departments' AS dname,job, COUNT(*) AS emp_cnt,
       SUM(sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno GROUP BY job
UNION ALL
SELECT 'All Departments' AS dname, 'All Jobs' AS job,
       COUNT(*) AS emp_cnt, SUM(sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno;
--------------------------------------------------------------------------------
-- 2.2.3.4 GROUPING SETS 함수
--------------------------------------------------------------------------------
SELECT dname, 'All Jobs' AS job, COUNT(*) AS emp_cnt, SUM(sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno GROUP BY dname
UNION ALL
SELECT 'All Departments' AS dname, job, COUNT(*) AS emp_cnt,
       SUM(sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno GROUP BY job;

SELECT CASE GROUPING(b.dname) WHEN 1 THEN 'All Departments'
                              ELSE b.dname END AS dname,
       CASE GROUPING(a.job)   WHEN 1 THEN 'All Jobs'
                              ELSE a.job END AS job,
       COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY GROUPING SETS (b.dname, a.job) ORDER BY b.dname, a.job;

SELECT CASE GROUPING(b.dname) WHEN 1 THEN 'All Departments'
                              ELSE b.dname END AS dname,
       CASE GROUPING(a.job)   WHEN 1 THEN 'All Jobs'
                              ELSE a.job END AS job,
       COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY GROUPING SETS (a.job, b.dname) ORDER BY b.dname, a.job;

SELECT b.dname, a.job, a.mgr, COUNT(*) AS emp_cnt, SUM(a.sal) AS sal_sum
FROM emp a, dept b WHERE b.deptno = a.deptno
GROUP BY GROUPING SETS ((b.dname, a.job, a.mgr), (b.dname, a.job),
                        (a.job, a.mgr));
--------------------------------------------------------------------------------
-- 2.2.4 윈도우 함수
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.4.2 그룹 내 순위 함수
--------------------------------------------------------------------------------
SELECT job, ename, sal,
       RANK () OVER (ORDER BY sal DESC) AS all_rk,
       RANK () OVER (PARTITION BY job ORDER BY sal DESC) AS job_rk
FROM emp;

SELECT job, ename, sal,
       RANK () OVER (PARTITION BY job ORDER BY sal DESC) AS job_rk
FROM emp;

SELECT job, ename, sal,
       RANK () OVER (ORDER BY sal DESC) AS rk,
       DENSE_RANK() OVER (ORDER BY sal DESC) AS dr
FROM emp;

SELECT job, ename, sal,
       RANK () OVER (ORDER BY sal DESC) AS rk,
       ROW_NUMBER () OVER (ORDER BY sal DESC) AS rn
FROM emp;
--------------------------------------------------------------------------------
-- 2.2.4.3 일반 집계함수
--------------------------------------------------------------------------------
SELECT mgr, ename, sal, SUM(sal) OVER (PARTITION BY mgr) AS sal_sum
FROM emp;

SELECT mgr, ename, sal, SUM(sal) OVER (PARTITION BY mgr ORDER BY sal
                                       RANGE UNBOUNDED PRECEDING) AS sal_sum
FROM emp;

SELECT mgr, ename, sal, MAX(sal) OVER (PARTITION BY mgr) AS max_sal
FROM emp;

SELECT mgr, ename, sal
FROM (SELECT mgr, ename, sal, MAX(sal) OVER (PARTITION BY mgr) AS max_sal
      FROM emp)
WHERE sal = max_sal;

SELECT mgr, ename, sal
FROM (SELECT mgr, ename, sal,
             RANK () OVER (PARTITION BY mgr ORDER BY sal DESC) AS sal_rk
      FROM emp)
WHERE sal_rk = 1;

SELECT mgr, ename, hiredate, sal,
       MIN (sal) OVER (PARTITION BY mgr ORDER BY hiredate) AS min_sal
FROM emp;

SELECT mgr, ename, hiredate, sal,
       ROUND(AVG (sal) OVER (PARTITION BY mgr ORDER BY hiredate
                             ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING ))
       AS avg_sal
FROM emp;

SELECT ename, sal,
       COUNT(*) OVER (ORDER BY sal RANGE BETWEEN 50 PRECEDING
                                         AND 150 FOLLOWING) AS emp_cnt
FROM emp;
--------------------------------------------------------------------------------
-- 2.2.4.4 그룹 내 행 순서 함수
--------------------------------------------------------------------------------
SELECT deptno, ename, sal,
       FIRST_VALUE (ename) OVER (PARTITION BY deptno ORDER BY SAL DESC
                                 ROWS UNBOUNDED PRECEDING) AS ename_fv
FROM emp;

SELECT deptno, ename, sal,
       FIRST_VALUE (ename) OVER (PARTITION BY deptno
                                 ORDER BY SAL DESC, ename
                                 ROWS UNBOUNDED PRECEDING) AS ename_fv
FROM emp;

SELECT deptno, ename, sal,
       LAST_VALUE (ename) OVER (PARTITION BY deptno
                                ORDER BY sal DESC
                                ROWS BETWEEN CURRENT ROW
                                     AND UNBOUNDED FOLLOWING) AS ename_lv
FROM emp;

SELECT deptno, ename, sal,
       LAST_VALUE (ename) OVER (PARTITION BY deptno
                                ORDER BY sal DESC
                                ROWS BETWEEN CURRENT ROW
                                     AND UNBOUNDED FOLLOWING) AS ename_lv
FROM emp;

SELECT ename, hiredate, sal,
       LAG (sal) OVER (ORDER BY hiredate) AS lag_sal
FROM emp WHERE job = 'SALESMAN';

SELECT ename, hiredate, sal,
       LAG (sal, 2, 0) OVER (ORDER BY hiredate) AS lag_sal
FROM emp WHERE job = 'SALESMAN';

SELECT ename, hiredate,
       LEAD (hiredate, 1) OVER (ORDER BY hiredate) AS lead_hiredate
FROM emp WHERE job = 'SALESMAN';
--------------------------------------------------------------------------------
-- 2.2.4.5 그룹 내 비율 함수
--------------------------------------------------------------------------------
SELECT ename, sal, ROUND(RATIO_TO_REPORT (sal) OVER (), 2) AS sal_rr
FROM emp WHERE job = 'SALESMAN';

SELECT deptno, ename, sal,
       PERCENT_RANK () OVER (PARTITION BY deptno ORDER BY sal DESC) AS pr
FROM emp;

SELECT deptno, ename, sal,
       CUME_DIST () OVER (PARTITION BY deptno ORDER BY sal DESC) AS cd
FROM emp;

SELECT ename, sal, NTILE (4) OVER (ORDER BY sal DESC) AS nt FROM emp;
--------------------------------------------------------------------------------
-- 2.2.5 Top N 쿼리
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.5.1 ROWNUM 슈도 칼럼
--------------------------------------------------------------------------------
SELECT ename, sal FROM emp WHERE ROWNUM < 4 ORDER BY sal DESC;

SELECT ename, sal FROM (SELECT ename, sal FROM emp ORDER BY sal DESC)
WHERE ROWNUM <= 3;

SELECT ename, sal FROM emp ORDER BY sal, empno FETCH FIRST 5 ROWS ONLY;

SELECT ename, sal FROM emp ORDER BY sal, empno OFFSET 5 ROWS;
--------------------------------------------------------------------------------
-- 2.2.6 계층형 질의와 셀프 조인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.6.2 셀프 조인
--------------------------------------------------------------------------------
SELECT worker.empno AS 사원번호, worker.ename AS 사원명,
       manager.ename AS 관리자명 FROM emp worker, emp manager
WHERE manager.empno = worker.mgr;

SELECT b.empno, b.ename, b.mgr FROM emp a, emp b
WHERE a.ename = 'JONES' AND b.mgr = a.empno;

SELECT c.empno, c.ename, c.mgr FROM emp a, emp b, emp c
WHERE a.ename = 'JONES' AND b.mgr = a.empno AND c.mgr = b.empno;

SELECT b.empno, b.ename, b.mgr FROM emp a, emp b
WHERE a.ename = 'SMITH' AND b.empno = a.mgr;

SELECT c.empno, c.ename, c.mgr FROM emp a, emp b, emp c
WHERE a.ename = 'SMITH' AND b.empno = a.mgr AND c.empno = b.mgr;
--------------------------------------------------------------------------------
-- 2.2.6.3 계층형 질의
--------------------------------------------------------------------------------
SELECT LEVEL as lv, LPAD(' ', (LEVEL - 1) * 2) || empno AS empno, mgr,
       CONNECT_BY_ISLEAF AS isleaf
FROM emp START WITH mgr IS NULL CONNECT BY mgr = PRIOR empno;

SELECT LEVEL as lv, LPAD(' ', (LEVEL - 1) * 2) || empno AS empno, mgr,
       CONNECT_BY_ISLEAF AS isleaf
FROM emp START WITH empno = 7876 CONNECT BY empno = PRIOR mgr;

SELECT CONNECT_BY_ROOT empno AS root_empno,
       SYS_CONNECT_BY_PATH(empno, ',') AS path, empno, mgr
FROM emp START WITH mgr IS NULL CONNECT BY mgr = PRIOR empno;
--------------------------------------------------------------------------------
-- 2.2.7 PIVOT 절과 UNPIVOT 절
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.7.2 PIVOT 절
--------------------------------------------------------------------------------
SELECT * FROM (SELECT job, deptno, sal FROM emp)
PIVOT (SUM(sal) FOR deptno IN (10, 20, 30))
ORDER BY 1;

SELECT * FROM (SELECT TO_CHAR(hiredate, 'YYYY') AS yyyy, job, deptno, sal
               FROM emp)
PIVOT (SUM(sal) FOR deptno IN (10, 20, 30))
ORDER BY 1, 2;

SELECT * FROM (SELECT job, deptno, sal FROM emp)
PIVOT (SUM(sal) AS sal FOR deptno IN (10 AS d10, 20 AS d20, 30 AS d30))
ORDER BY 1;

SELECT job, d20_sal FROM (SELECT job, deptno, sal FROM emp)
PIVOT (SUM(sal) AS sal FOR deptno IN (10 AS d10, 20 AS d20, 30 AS d30))
WHERE d20_sal > 2500 ORDER BY 1;

SELECT * FROM (SELECT job, deptno, sal FROM emp)
PIVOT (SUM(sal) AS sal, COUNT(*) AS cnt
       FOR deptno IN (10 AS d10, 20 AS d20))
ORDER BY 1;

SELECT * FROM (SELECT TO_CHAR(hiredate, 'YYYY') AS yyyy, job, deptno, sal
               FROM emp)
PIVOT (SUM(sal) AS sal, COUNT(*) AS cnt
       FOR (deptno, job) IN ((10, 'ANALYST') AS d10a,
                             (10, 'CLERK') AS d10c,
                             (20, 'ANALYST') AS d20a,
                             (20, 'CLERK') AS d20c))
ORDER BY 1;

SELECT job, SUM(CASE deptno WHEN 10 THEN sal END) AS d10_sal,
            SUM(CASE deptno WHEN 20 THEN sal END) AS d20_sal,
            SUM(CASE deptno WHEN 30 THEN sal END) AS d30_sal
FROM emp GROUP BY job ORDER BY job;
--------------------------------------------------------------------------------
-- 2.2.7.3 UNPIVOT 절
--------------------------------------------------------------------------------
DROP TABLE t1 PURGE;

CREATE TABLE t1 AS
    SELECT job, d10_sal, d20_sal, d10_cnt, d20_cnt
    FROM (SELECT job, deptno, sal FROM emp
          WHERE job IN ('ANALYST', 'CLERK'))
    PIVOT (SUM(sal) AS sal, COUNT(*) AS cnt
        FOR deptno IN (10 AS d10, 20 AS d20));

SELECT * FROM t1 ORDER BY job;

SELECT job, deptno, sal FROM t1
UNPIVOT (sal FOR deptno IN (d10_sal, d20_sal))
ORDER BY 1, 2;

SELECT job, deptno, sal FROM t1
UNPIVOT (sal FOR deptno IN (d10_sal AS 10, d20_sal AS 20))
ORDER BY 1, 2;

SELECT job, deptno, sal FROM t1
UNPIVOT INCLUDE NULLS (sal FOR deptno IN (d10_sal AS 10, d20_sal AS 20))
ORDER BY 1, 2;

SELECT * FROM t1
UNPIVOT ((sal, cnt) FOR deptno IN (
    (d10_sal, d10_cnt) AS 10, (d20_sal, d20_cnt) AS 20))
ORDER BY 1, 2;

SELECT * FROM t1
UNPIVOT ((sal, cnt) FOR (deptno, dname) IN (
    (d10_sal, d10_cnt) AS (10, 'ACCOUNTING'),
    (d20_sal, d20_cnt) AS (20, 'RESEARCH')))
ORDER BY 1, 2;

SELECT a.job, CASE b.lv WHEN 1 THEN 10 WHEN 2 THEN 20 END AS deptno,
       CASE b.lv WHEN 1 THEN a.d10_sal WHEN 2 THEN a.d20_sal END AS sal,
       CASE b.lv WHEN 1 THEN a.d10_cnt WHEN 2 THEN a.d20_cnt END AS cnt
FROM t1 a, (SELECT LEVEL AS lv FROM dual CONNECT BY LEVEL <= 2) b
ORDER BY 1, 2;

SELECT a.job, b.lv, a.d10_sal, a.d20_sal, a.d10_cnt, a.d20_cnt
FROM t1 a, (SELECT LEVEL AS lv FROM dual CONNECT BY LEVEL <= 2) b
ORDER BY a.job, b.lv;
--------------------------------------------------------------------------------
-- 2.2.8 정규 표현식
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.8.2 기본 문법
--------------------------------------------------------------------------------
SELECT REGEXP_SUBSTR('aab', 'a.b') AS c1, REGEXP_SUBSTR('abb', 'a.b') AS c2,
       REGEXP_SUBSTR('acb', 'a.b') AS c3, REGEXP_SUBSTR('adc', 'a.b') AS c4
FROM dual;

SELECT REGEXP_SUBSTR('a', 'a|b') AS c1, REGEXP_SUBSTR('b', 'a|b') AS c2,
       REGEXP_SUBSTR('c', 'a|b') AS c3, REGEXP_SUBSTR('ab', 'ab|cd') AS c4,
       REGEXP_SUBSTR('cd', 'ab|cd') AS c5, REGEXP_SUBSTR('bc', 'ab|cd') AS c6,
       REGEXP_SUBSTR('aa', 'a|aa') AS c7, REGEXP_SUBSTR('aa', 'aa|a') AS c8
FROM dual;

SELECT REGEXP_SUBSTR('a|b', 'a|b') AS c1, REGEXP_SUBSTR('a|b', 'a\|b') AS c2
FROM dual;

SELECT REGEXP_SUBSTR('ab' || CHR(10) || 'cd', '^.', 1, 1) AS c1,
       REGEXP_SUBSTR('ab' || CHR(10) || 'cd', '^.', 1, 2) AS c2,
       REGEXP_SUBSTR('ab' || CHR(10) || 'cd', '.$', 1, 1) AS c3,
       REGEXP_SUBSTR('ab' || CHR(10) || 'cd', '.$', 1, 2) AS c4
FROM dual;

SELECT REGEXP_SUBSTR('ac', 'ab?c') AS c1,
       REGEXP_SUBSTR('abc', 'ab?c') AS c2,
       REGEXP_SUBSTR('abbc', 'ab?c') AS c3,
       REGEXP_SUBSTR('ac', 'ab*c') AS c4,
       REGEXP_SUBSTR('abc', 'ab*c') AS c5,
       REGEXP_SUBSTR('abbc', 'ab*c') AS c6,
       REGEXP_SUBSTR('ac', 'ab+c') AS c7,
       REGEXP_SUBSTR('abc', 'ab+c') AS c8,
       REGEXP_SUBSTR('abbc', 'ab+c') AS c9
FROM dual;

SELECT REGEXP_SUBSTR('ab', 'a{2}') AS c1,
       REGEXP_SUBSTR('aab', 'a{2}') AS c2,
       REGEXP_SUBSTR('aab', 'a{3,}') AS c3,
       REGEXP_SUBSTR('aaab', 'a{3,}') AS c4,
       REGEXP_SUBSTR('aaab', 'a{4,5}') AS c5,
       REGEXP_SUBSTR('aaaab', 'a{4,5}') AS c6
FROM dual;

SELECT REGEXP_SUBSTR('ababc', '(ab)+c') AS c1,
       REGEXP_SUBSTR('ababc', 'ab+c') AS c2,
       REGEXP_SUBSTR('abd', 'a(b|c)d') AS c3,
       REGEXP_SUBSTR('abd', 'ab|cd') AS c4
FROM dual;

SELECT REGEXP_SUBSTR('abxab', '(ab|cd)x\1') AS c1,
       REGEXP_SUBSTR('cdxcd', '(ab|cd)x\1') AS c2,
       REGEXP_SUBSTR('abxef', '(ab|cd)x\1') AS c3,
       REGEXP_SUBSTR('ababab', '(.*)\1+') AS c4,
       REGEXP_SUBSTR('abcabc', '(.*)\1+') AS c5,
       REGEXP_SUBSTR('abcabd', '(.*)\1+') AS c6
FROM dual;

SELECT REGEXP_SUBSTR('ac', '[ab]c') AS c1,
       REGEXP_SUBSTR('bc', '[ab]c') AS c2,
       REGEXP_SUBSTR('cc', '[ab]c') AS c3,
       REGEXP_SUBSTR('ac', '[^ab]c') AS c4,
       REGEXP_SUBSTR('bc', '[^ab]c') AS c5,
       REGEXP_SUBSTR('cc', '[^ab]c') AS c6
FROM dual;

SELECT REGEXP_SUBSTR('1a', '[0-9][a-z]') AS c1,
       REGEXP_SUBSTR('9z', '[0-9][a-z]') AS c2,
       REGEXP_SUBSTR('aA', '[^0-9][^a-z]') AS c3,
       REGEXP_SUBSTR('Aa', '[^0-9][^a-z]') AS c4
FROM dual;

SELECT REGEXP_SUBSTR('gF1,', '[[:digit:]]') AS c1,
       REGEXP_SUBSTR('gF1,', '[[:alpha:]]') AS c2,
       REGEXP_SUBSTR('gF1,', '[[:lower:]]') AS c3,
       REGEXP_SUBSTR('gF1,', '[[:upper:]]') AS c4,
       REGEXP_SUBSTR('gF1,', '[[:alnum:]]') AS c5,
       REGEXP_SUBSTR('gF1,', '[[:xdigit:]]') AS c6,
       REGEXP_SUBSTR('gF1,', '[[:punct:]]') AS c7
FROM dual;

SELECT REGEXP_SUBSTR('(650) 555-0100', '^\(\d{3}\) \d{3}-\d{4}$') AS c1,
       REGEXP_SUBSTR('650-555-0100', '^\(\d{3}\) \d{3}-\d{4}$') AS c2,
       REGEXP_SUBSTR('b2b', '\w\d\D') AS c3,
       REGEXP_SUBSTR('b2_', '\w\d\D') AS c4,
       REGEXP_SUBSTR('b22', '\w\d\D') AS c5
FROM dual;

SELECT REGEXP_SUBSTR('jdoe@company.co.uk', '\w+@\w+(\.\w+)+') AS c1,
       REGEXP_SUBSTR('jdoe@company', '\w+@\w+(\.\w+)+') AS c2,
       REGEXP_SUBSTR('to: bill', '\w+\W\s\w+') AS c3,
       REGEXP_SUBSTR('to bill', '\w+\W\s\w+') AS c4
FROM dual;

SELECT REGEXP_SUBSTR('(a b )', '\(\w\s\w\s\)') AS c1,
       REGEXP_SUBSTR('(a b )', '\(\w\S\w\S\)') AS c2,
       REGEXP_SUBSTR('(a,b.)', '\(\w\s\w\s\)') AS c3,
       REGEXP_SUBSTR('(a,b.)', '\(\w\S\w\S\)') AS c4
FROM dual;

SELECT REGEXP_SUBSTR('aaaa', 'a??aa') AS c1,
       REGEXP_SUBSTR('aaaa', 'a?aa') AS c2,
       REGEXP_SUBSTR('xaxbxc', '\w*?x\w') AS c3,
       REGEXP_SUBSTR('xaxbxc', '\w*x\w') AS c4,
       REGEXP_SUBSTR('abxcxd', '\w+?x\w') AS c5,
       REGEXP_SUBSTR('abxcxd', '\w+x\w') AS c6
FROM dual;

SELECT REGEXP_SUBSTR('aaaa', 'a{2}?') AS c1,
       REGEXP_SUBSTR('aaaa', 'a{2}') AS c2,
       REGEXP_SUBSTR('aaaaa', 'a{2,}?') AS c3,
       REGEXP_SUBSTR('aaaaa', 'a{2,}') AS c4,
       REGEXP_SUBSTR('aaaaa', 'a{2,4}?') AS c5,
       REGEXP_SUBSTR('aaaaa', 'a{2,4}') AS c6
FROM dual;
--------------------------------------------------------------------------------
-- 2.2.8.3 정규 표현식 조건과 함수
--------------------------------------------------------------------------------
SELECT first_name, last_name FROM hr.employees
WHERE REGEXP_LIKE(first_name, '^Ste(v|ph)en$');

SELECT phone_number,
       REGEXP_REPLACE(phone_number,
                      '([[:digit:]]{3})\.([[:digit:]]{3})\.([[:digit:]]{4})',
                      '(\1) \2-\3') AS c1
FROM hr.employees WHERE employee_id IN (144, 145);

SELECT REGEXP_SUBSTR('http://www.example.com/products',
                     'http://([[:alnum:]]+\.?){3,4}/?') AS c1
FROM dual;

SELECT REGEXP_SUBSTR('1234567890', '(123)(4(56)(78))', 1, 1, 'i', 1) AS c1,
       REGEXP_SUBSTR('1234567890', '(123)(4(56)(78))', 1, 1, 'i', 4) AS c2
FROM dual;

SELECT REGEXP_INSTR('1234567890', '(123)(4(56)(78))', 1, 1, 0, 'i', 1) AS c1,
       REGEXP_INSTR('1234567890', '(123)(4(56)(78))', 1, 1, 0, 'i', 2) AS c2,
       REGEXP_INSTR('1234567890', '(123)(4(56)(78))', 1, 1, 0, 'i', 4) AS c3
FROM dual;

SELECT REGEXP_COUNT('123123123123123', '123', 1) AS c1,
       REGEXP_COUNT('123123123123', '123', 3) AS c2
FROM dual;