--------------------------------------------------------------------------------
-- 5장 - 소트 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 5.1 소트 연산에 대한 이해
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 5.1.2 소트 오퍼레이션
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- (1) sort aggregate
--------------------------------------------------------------------------------
select /*+ gather_plan_statistics */ sum(sal), max(sal), min(sal), avg(sal)
from emp;

select * from table(dbms_xplan.display_cursor());
--------------------------------------------------------------------------------
-- (2) sort order by
--------------------------------------------------------------------------------
select /*+ gather_plan_statistics */ * from emp order by sal desc;

select * from table(dbms_xplan.display_cursor());
--------------------------------------------------------------------------------
-- (3) sort group by
--------------------------------------------------------------------------------
select /*+ gather_plan_statistics */
    deptno, sum(sal), max(sal), min(sal), avg(sal)
from emp
group by deptno
order by deptno;

select * from table(dbms_xplan.display_cursor());

select /*+ gather_plan_statistics */
    deptno, sum(sal), max(sal), min(sal), avg(sal)
from emp
group by deptno;

select * from table(dbms_xplan.display_cursor());
--------------------------------------------------------------------------------
-- 그룹핑 결과의 정렬 순서
--------------------------------------------------------------------------------
select /*+ gather_plan_statistics no_use_hash_aggregation */
    deptno, job, sum(sal), max(sal), min(sal)
from emp
group by deptno, job;

select * from table(dbms_xplan.display_cursor());
--------------------------------------------------------------------------------
-- (4) sort unique
--------------------------------------------------------------------------------
create index emp_job_idx on emp(job);

select /*+ gather_plan_statistics no_nlj_prefetch(dept) opt_param('_nlj_batching_enabled', 0)
           ordered use_nl(dept) */ *
from dept
where deptno in (select /*+ unnest no_batch_table_access_by_rowid(emp) */ deptno
                 from emp where job = 'CLERK');

select * from table(dbms_xplan.display_cursor(format=>'alias'));

drop index emp_job_idx;

select /*+ gather_plan_statistics */ job, mgr from emp where deptno = 10
union
select job, mgr from emp where deptno = 20;

select * from table(dbms_xplan.display_cursor());

select /*+ gather_plan_statistics */ job, mgr from emp where deptno = 10
minus
select job, mgr from emp where deptno = 20;

select * from table(dbms_xplan.display_cursor());

select /*+ gather_plan_statistics */ distinct deptno from emp order by deptno;

select * from table(dbms_xplan.display_cursor());

select /*+ gather_plan_statistics */ distinct deptno from emp;

select * from table(dbms_xplan.display_cursor());
--------------------------------------------------------------------------------
-- (5) sort join
--------------------------------------------------------------------------------
select /*+ gather_plan_statistics
           ordered use_merge(e) full(d) full(e) */ *
from dept d, emp e
where d.deptno = e.deptno;

select * from table(dbms_xplan.display_cursor());
--------------------------------------------------------------------------------
-- (6) window sort
--------------------------------------------------------------------------------
select /*+ gather_plan_statistics */
    empno, ename, job, mgr, sal, avg(sal) over (partition by deptno)
from emp;

select * from table(dbms_xplan.display_cursor());
--------------------------------------------------------------------------------
-- 5.2 소트가 발생하지 않도록 SQL 작성
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 5.2.1 union vs. union all
--------------------------------------------------------------------------------
create table 결제(
    결제번호 number(10) constraint 결제_pk primary key,
    결제수단코드 varchar2(1),
    주문번호 number(10),
    결제금액 number(10),
    결제일자 varchar2(8),
    주문일자 varchar2(8)
);

create index 결제_n11 on 결제(결제수단코드);

explain plan for
select /*+ no_batch_table_access_by_rowid(결제) */ 결제번호, 주문번호, 결제금액, 주문일자
from 결제
where 결제수단코드 = 'M' and 결제일자 = '20180316'
union
select /*+ no_batch_table_access_by_rowid(결제) */ 결제번호, 주문번호, 결제금액, 주문일자
from 결제
where 결제수단코드 = 'C' and 결제일자 = '20180316';

select * from table(dbms_xplan.display);

create index 결제_n22 on 결제(결제일자);
create index 결제_n33 on 결제(주문일자);

explain plan for
select /*+ no_batch_table_access_by_rowid(결제) */ 결제번호, 주문번호, 결제금액, 주문일자
from 결제
where 결제일자 = '20180316'
union
select /*+ no_batch_table_access_by_rowid(결제) */ 결제번호, 주문번호, 결제금액, 주문일자
from 결제
where 주문일자 = '20180316';

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(결제) */ 결제번호, 주문번호, 결제금액, 주문일자
from 결제
where 결제일자 = '20180316'
union all
select /*+ no_batch_table_access_by_rowid(결제) */ 결제번호, 주문번호, 결제금액, 주문일자
from 결제
where 주문일자 = '20180316'
and (결제일자 <> '20180316' or 결제일자 is null);

select * from table(dbms_xplan.display);

drop table 결제;
--------------------------------------------------------------------------------
-- 5.2.2 exists 활용
--------------------------------------------------------------------------------
create table 상품(
    상품번호 number(10) constraint 상품_pk primary key,
    상품명 varchar2(10),
    상품가격 number(10),
    상품유형코드 varchar2(10)
);

create index 상품_x1 on 상품(상품유형코드);

create table 계약(
    상품번호 number(10) constraint 계약_상품_fk references 상품(상품번호),
    계약일자 varchar2(8),
    계약구분코드 varchar2(10)
);

create index 계약_x2 on 계약(상품번호, 계약일자);

explain plan for
select /*+ leading(p) index(p) index(c) no_batch_table_access_by_rowid(p) */
    distinct p.상품번호, p.상품명, p.상품가격
from 상품 p, 계약 c
where p.상품유형코드 = :pclscd
and c.상품번호 = p.상품번호
and c.계약일자 between :dt1 and :dt2
and c.계약구분코드 = :ctpcd;

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(p) */
    p.상품번호, p.상품명, p.상품가격
from 상품 p
where p.상품유형코드 = :pclscd
and exists (
    select /*+ no_batch_table_access_by_rowid(c) */ 'x'
    from 계약 c
    where c.상품번호 = p.상품번호
    and c.계약일자 between :dt1 and :dt2
    and c.계약구분코드 = :ctpcd
);

select * from table(dbms_xplan.display);

drop table 계약;
drop table 상품;

create table 관제진행상황(
    상황접수번호 number(10) constraint 관제진행상황_pk primary key,
    관제일련번호 number(10),
    상황코드 varchar2(4),
    관제일시 varchar2(14)
);

create index 관제진행상황_idx on 관제진행상황(상황코드, 관제일시);

create table 구조활동(
    상황접수번호 number(10) constraint 구조활동_관제진행상황_fk references 관제진행상황(상황접수번호),
    출동센터id varchar2(10)
);

create index 구조활동_idx on 구조활동(상황접수번호, 출동센터id);

explain plan for
select /*+ no_batch_table_access_by_rowid(st) */
    st.상황접수번호, st.관제일련번호, st.상황코드, st.관제일시
from 관제진행상황 st
where 상황코드 = '0001'
and 관제일시 between :v_timefrom || '000000' and :v_timeto || '235959'
minus
select /*+ no_batch_table_access_by_rowid(st) leading(st) use_nl(rpt) */
    st.상황접수번호, st.관제일련번호, st.상황코드, st.관제일시
from 관제진행상황 st, 구조활동 rpt
where 상황코드 = '0001'
and 관제일시 between :v_timefrom || '000000' and :v_timeto || '235959'
and rpt.출동센터id = :v_cntr_id
and st.상황접수번호 = rpt.상황접수번호
order by 상황접수번호, 관제일시;

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(st) */
    st.상황접수번호, st.관제일련번호, st.상황코드, st.관제일시
from 관제진행상황 st
where 상황코드 = '0001'
and 관제일시 between :v_timefrom || '000000' and :v_timeto || '235959'
and not exists (
    select 'x' from 구조활동
    where 출동센터id = :v_cntr_id
    and 상황접수번호 = st.상황접수번호)
order by 상황접수번호, 관제일시;

select * from table(dbms_xplan.display);

drop table 구조활동;
drop table 관제진행상황;
--------------------------------------------------------------------------------
-- 5.2.3 조인 방식 변경
--------------------------------------------------------------------------------
