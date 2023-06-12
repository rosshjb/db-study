--------------------------------------------------------------------------------
-- 부록 - SQL 분석 도구
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1. 실행계획 확인
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- PLAN_TABLE 생성
--------------------------------------------------------------------------------
-- plan_table 생성
@?/rdbms/admin/utlxplan.sql

-- sys.plan_table$에 대한 synonym 조회
select owner, synonym_name, table_owner, table_name
from all_synonyms
where synonym_name = 'PLAN_TABLE';

-- plan_table 조회
select owner, table_name
from dba_tables
where table_name like 'PLAN_TABLE%';
--------------------------------------------------------------------------------
-- sql*plus에서 실행계획 확인
--------------------------------------------------------------------------------
explain plan for
select * from emp where empno = 7900;

set linesize 200;
@?/rdbms/admin/utlxpls
--------------------------------------------------------------------------------
-- 더 많은 정보 확인하기
/*
DBMS_XPLAN.DISPLAY(
   table_name    IN  VARCHAR2  DEFAULT 'PLAN_TABLE',
   statement_id  IN  VARCHAR2  DEFAULT  NULL,
   format        IN  VARCHAR2  DEFAULT  'TYPICAL',
   filter_preds  IN  VARCHAR2 DEFAULT NULL);
*/
-- https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_XPLAN.html#GUID-2E479BE4-FEEA-400E-A218-DC779A2181CF
--------------------------------------------------------------------------------
explain plan for
select * from emp where empno = 7900;

-- with most recent explained statement (format levels of detail)
select * from table(dbms_xplan.display(null, null, 'basic'));    -- minimum
select * from table(dbms_xplan.display(null, null, 'typical'));  -- default
select * from table(dbms_xplan.display(null, null, 'serial'));   -- 'typical -parallel'
select * from table(dbms_xplan.display(null, null, 'all'));      -- 'typical +projection +alias +remote'
select * from table(dbms_xplan.display(null, null, 'advanced')); -- undocumented

explain plan set statement_id = 'sql_test' for
select * from dept;

-- with specific explained statement
select * from table(dbms_xplan.display('plan_table', 'sql_test', 'basic')); -- for specific statement

explain plan for
select * from emp where empno = 7788;

-- with format option keywords
select * from table(dbms_xplan.display(null, null, '-rows'));                      -- 'typical -rows'
select * from table(dbms_xplan.display(null, null, 'basic bytes cost'));           -- 'basic +bytes +cost'
select * from table(dbms_xplan.display(null, null, 'basic +partition +parallel')); -- 'basic partition parallel'
select * from table(dbms_xplan.display(null, null, 'typical -predicate'));
select * from table(dbms_xplan.display(null, null, '+projection +alias +remote')); -- 'typical projection alias remote'
select * from table(dbms_xplan.display(null, null, 'basic, note'));                -- 'basic +note'
select * from table(dbms_xplan.display(null, null, 'advanced -outline'));          -- 'outline' is undocumented
--------------------------------------------------------------------------------
-- 2. auto trace
--------------------------------------------------------------------------------
set autotrace on;

select * from scott.emp where empno = 7900;

set autotrace on;
set autotrace on explain;
set autotrace on statistics;

set autotrace traceonly;
set autotrace traceonly explain;
set autotrace traceonly statistics;

set autotrace off;

@?/sqlplus/admin/plustrce.sql
grant plustrace to scott;
--------------------------------------------------------------------------------
-- 3. sql 트레이스
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- sql 트레이스 수집 및 파일 찾기
--------------------------------------------------------------------------------
alter session set sql_trace = true;
select * from emp where empno = 7900;
select * from dual; -- 다른 쿼리를 실행해 커서가 닫히게 함(정상적인 트레이스 결과를 얻기 위함)
alter session set sql_trace = false;

select value from v$diag_info where name = 'Diag Trace';

-- resolve trace file in 11g+
select value from v$diag_info where name = 'Default Trace File';

-- resolve trace file in 10g
select r.value || '/' || lower(t.instance_name) || '_ora_'
    || ltrim(to_char(p.spid)) || '.trc' trace_file
from v$process p, v$session s, v$parameter r, v$instance t
where p.addr = s.paddr
and r.name = 'user_dump_dest'
and s.sid = (select sid from v$mystat where rownum <= 1);
--------------------------------------------------------------------------------
-- 4. dbms_xplan 패키지
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 예상 실행계획 출력
--------------------------------------------------------------------------------
-- @?/rdbms/admin/utlxpls.sql
set markup html preformat on;
select plan_table_output from table(dbms_xplan.display('plan_table',null,'serial'));

explain plan set statement_id = 'SQL1' for
select *
from emp e, dept d
where d.deptno = e.deptno
and e.sal >= 1000;

select * from table(dbms_xplan.display('plan_table', 'SQL1', 'basic'));

select * from table(dbms_xplan.display('plan_table', 'SQL1', 'basic rows bytes cost'));
--------------------------------------------------------------------------------
-- 캐싱된 커서의 실제 실행계획 출력
/*
DBMS_XPLAN.DISPLAY_CURSOR(
   sql_id            IN  VARCHAR2  DEFAULT  NULL,
   cursor_child_no   IN  NUMBER    DEFAULT  0, 
   format            IN  VARCHAR2  DEFAULT  'TYPICAL');
*/
-- https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_XPLAN.html#GUID-0EE333AF-E9AC-40A4-87D5-F6CF59D6C47B
-- DBMS_XPLAN.DISPLAY의 format 및 format option keywords에 더해서 추가적인 값 지정 가능
--------------------------------------------------------------------------------
select * from emp;

-- 직전에 수행한 sql에 대한 sql_id와 child_number 조회
select prev_sql_id as sql_id, prev_child_number as child_no
from v$session
where sid = userenv('sid')
and username is not null
and prev_hash_value <> 0;

select * /* rosshjb */ from emp;

-- sql 텍스트로, 앞서 수행된 sql에 대한 sql_id와 child_number 조회
select sql_id, child_number, sql_fulltext, last_active_time
from v$sql
where sql_text like '%rosshjb%';

-- 직접 v$sql_plan 뷰에서 실행계획 조회
select * from v$sql_plan where sql_id = 'ahqau6gwja14p' and child_number = 0;

-- dbms_xplan.display_cursor로, 특정 sql_id, child_number에 대한 실제 실행계획 조회
select * from table(dbms_xplan.display_cursor('ahqau6gwja14p', 0, 'advanced'));

-- dbms_xplan.display_cursor로, 직전에 수행된 sql에 대한 실제 실행계획 조회
select * from table(dbms_xplan.display_cursor(null, null, 'basic rows bytes cost predicate'));

-- dbms_xplan.display에 더해서 추가적으로 이용 가능한 format (level of details for the plan)
select * from table(dbms_xplan.display_cursor(null, null, 'adaptive'));

grant select on v_$session to scott;
grant select on v_$sql to scott;
grant select on v_$sql_plan to scott;

set serveroutput off;
select * from emp;
select * from table(dbms_xplan.display_cursor(null, null, 'serial'));
--------------------------------------------------------------------------------
-- 캐싱된 커서의 Row Source별 수행 통계 출력
--------------------------------------------------------------------------------
alter session set statistics_level = all;

select /*+ ordered use_nl(d) no_nlj_prefetch(d) opt_param('_nlj_batching_enabled', 0) 
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(d) */
       /* rosshjb */
    e.empno, e.ename, d.dname, d.loc
from emp e, dept d
where e.deptno = d.deptno
and e.sal >= 1000;

select sql_id, child_number, sql_fulltext, last_active_time
from v$sql
where sql_text like '%rosshjb%';

select * from table(dbms_xplan.display_cursor('cdu5jzkmfft7p', 0, 'iostats'));  -- 'typical iostats'
select * from table(dbms_xplan.display_cursor('cdu5jzkmfft7p', 0, 'memstats')); -- 'typical +memstats'
select * from table(dbms_xplan.display_cursor('cdu5jzkmfft7p', 0, 'allstats')); -- 'typical +iostats +memstats'
select * from table(dbms_xplan.display_cursor(null, null, 'allstats'));         -- 'typical +allstats'
select * from table(dbms_xplan.display_cursor(null, null, 'last'));             -- 'typical +last'

alter session set statistics_level = typical;

select /*+ gather_plan_statistics
           ordered use_nl(d) no_nlj_prefetch(d) opt_param('_nlj_batching_enabled', 0) 
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(d) */
    e.empno, e.ename, d.dname, d.loc
from emp e, dept d
where e.deptno = d.deptno
and e.sal >= 1000;

select * from table(dbms_xplan.display_cursor(null, 0, 'advanced allstats last')); -- 'advanced +allstats +last'

grant select on v_$session to scott;
grant select on v_$sql to scott;
grant select on v_$sql_plan_statistics_all to scott;

set serveroutput off;
select * from emp;
select * from table(dbms_xplan.display_cursor(null, null, 'allstats last'));
--------------------------------------------------------------------------------
-- 5. 실시간 sql 모니터링
-- https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_SQLTUNE.html#GUID-CFA1F851-1FC1-44D6-BB5C-76C3ADE1A483
--------------------------------------------------------------------------------
select /*+ monitor
           ordered use_nl(d) no_nlj_prefetch(d) opt_param('_nlj_batching_enabled', 0) 
           no_batch_table_access_by_rowid(e) no_batch_table_access_by_rowid(d) */
       /* rosshjb2 */
    e.empno, e.ename, d.dname, d.loc
from emp e, dept d
where e.deptno = d.deptno
and e.sal >= 1000;

-- 직접 v$sql_monitor에서 앞서 모니터링된 sql에 대한 sql_id 조회
select sql_id, sql_text from v$sql_monitor where sql_text like '%rosshjb2%';

-- 직접 v$sql_plan_monitor에서 특정 sql에 대한 실행계획 조회
select * from v$sql_plan_monitor where sql_id = '3rn1a26q2t9mz' order by plan_line_id asc;

-- dbms_sqltune.report_sql_monitor로 특정 sql에 대한 실행계획 조회
select dbms_sqltune.report_sql_monitor(sql_id => '3rn1a26q2t9mz') from dual;
select dbms_sqltune.report_sql_monitor(sql_id => '3rn1a26q2t9mz', type => 'html') from dual;

-- dbms_sqltune.report_sql_monitor로 가장 최근 모니터링된 sql에 대한 실행계획 조회
select dbms_sqltune.report_sql_monitor() from dual;