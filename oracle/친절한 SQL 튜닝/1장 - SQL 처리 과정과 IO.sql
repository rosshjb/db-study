--------------------------------------------------------------------------------
-- 1장 - SQL 처리 과정과 IO
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.1 SQL 파싱과 최적화
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.1.1 구조적, 집합적, 선언적 질의 언어
--------------------------------------------------------------------------------
select e.empno, e.ename, e.job, d.dname, d.loc
from emp e, dept d
where e.deptno = d.deptno
order by e.ename;
--------------------------------------------------------------------------------
-- 1.1.4 실행계획과 비용
--------------------------------------------------------------------------------
-- SQL 실행경로 미리보기
explain plan for select
    /*+ leading(d e) use_nl(e) no_nlj_prefetch(e) opt_param('_nlj_batching_enabled', 0)
        no_batch_table_access_by_rowid(d) no_batch_table_access_by_rowid(e) */
    e.empno, e.ename, e.job
from emp e, dept d
where e.deptno = d.deptno
and d.loc = 'CHICAGO';

select plan_table_output from table(dbms_xplan.display(format => 'basic cost rows bytes'));

-- 실행계획 선택 근거
create table t as
select d.no, e.* from scott.emp e, (select rownum no from dual connect by level <= 1000) d;

create index t_x01 on t(deptno, no);
create index t_x02 on t(deptno, job, no);

exec dbms_stats.gather_table_stats(user, 't');

set autotrace traceonly explain;

select * from t
where deptno = 10
and no = 1;

select /*+ index(t t_x02) no_index_ss(t t_x02) */ * from t
where deptno = 10
and no = 1;

select /*+ full(t) */ * from t
where deptno = 10
and no = 1;

set autotrace off;
--------------------------------------------------------------------------------
-- 1.1.5 옵티마이저 힌트
--------------------------------------------------------------------------------
create table 고객(
    고객ID varchar2(10) constraint 고객_pk primary key,
    고객명 varchar2(10) not null,
    연락처 varchar2(20) not null,
    주소 varchar2(100)  not null,
    가입일시 timestamp  default systimestamp not null
);

select /*+ index(a 고객_pk) */
    고객명, 연락처, 주소, 가입일시
from 고객 a
where 고객id = '000000008';

select --+ index(a 고객_pk)
    고객명, 연락처, 주소, 가입일시
from 고객 a
where 고객id = '000000008';

drop table 고객;
--------------------------------------------------------------------------------
-- 주의사항
--------------------------------------------------------------------------------
select /*+ index(a a_x01) index(b b_x03) */
    a.dummy a_dummy, b.dummy b_dummy
from dual a, dual b;

select /*+ index(c), full(d) */
    c.dummy c_dummy, d.dummy d_dummy
from dual c, dual d;

select /*+ full(scott.emp) */ *
from emp;

select /*+ full(emp) */ *
from emp e;

select * from table(dbms_xplan.display_cursor(null, 0, 'advanced allstats last'));
--------------------------------------------------------------------------------
-- 자율이냐 강제냐, 그것이 문제
--------------------------------------------------------------------------------
create table 고객(
    고객ID varchar2(10) constraint 고객_pk primary key,
    고객명 varchar2(10) not null,
    연락처 varchar2(20) not null,
    주소 varchar2(100)  not null,
    가입일시 timestamp  default systimestamp not null
);

create table 주문(
    주문번호 number(10),
    주문일자 date default sysdate not null,
    주문금액 number(10) not null,
    고객id varchar2(10) not null,
    constraint 주문번호_pk primary key(주문번호),
    constraint 고객id_fk foreign key(고객id) references 고객(고객id)
);

create index 주문_주문일자_고객id_idx on 주문(주문일자, 고객id);

select /*+ index(a (주문일자)) */
    a.주문번호, a.주문금액, b.고객명, b.연락처, b.주소
from 주문 a, 고객 b
where a.주문일자 = :ord_dt
and a.고객id = b.고객id;

select /*+ leading(a) use_nl(b) index(a (주문일자)) index(b 고객_pk) */
    a.주문번호, a.주문금액, b.고객명, b.연락처, b.주소
from 주문 a, 고객 b
where a.주문일자 = :ord_dt
and a.고객id = b.고객id;

drop table 주문;
drop table 고객;
--------------------------------------------------------------------------------
-- 1.2 SQL 공유 및 재사용
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.2.2 바인드 변수의 중요성
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 공유 가능 SQL
--------------------------------------------------------------------------------
SELECT * FROM emp WHERE empno = 7900;
select * from EMP where EMPNO = 7900;
select * from emp where empno = 7900;
select * from emp where empno = 7900 ;
select * from emp where empno = 7900  ;
select * from scott.emp where empno = 7900;
select /* comment */ * from scott.emp where empno = 7900;
select /*+ first_rows */ * from scott.emp where empno = 7900;
--------------------------------------------------------------------------------
-- 1.3 데이터 저장 구조 및 I/O 메커니즘
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1.3.2 데이터베이스 저장 구조
--------------------------------------------------------------------------------
create table my_segment as
select b.no, a.dummy
from (select * from dual) a,
     (select level no from dual connect by level <= 100000) b;

select segment_type, tablespace_name, extent_id, file_id, block_id, blocks
from dba_extents
where owner = USER
and segment_name = 'MY_SEGMENT'
order by extent_id;

drop table my_segment;
--------------------------------------------------------------------------------
-- 1.3.3 블록 단위 I/O
--------------------------------------------------------------------------------
show parameter block_size;

select value from v$parameter where name = 'db_block_size';
--------------------------------------------------------------------------------
-- 1.3.5 논리적 I/O vs. 물리적 I/O
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- DB 버퍼캐시
--------------------------------------------------------------------------------
show sga;

select * from v$sga;
--------------------------------------------------------------------------------
-- 1.3.6 Single Block I/O vs. Multiblock I/O
--------------------------------------------------------------------------------
show parameter db_file_multiblock_read_count;

alter session set db_file_multiblock_read_count = 128;