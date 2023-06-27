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
create table 상품(
    상품코드 varchar2(10) constraint 상품_pk primary key,
    상품명 varchar2(10),
    상품구분코드 varchar2(10)
);

create table 계약(
    계약번호 number(10) constraint 계약_pk primary key,
    상품코드 varchar2(10) constraint 상품_fk references 상품(상품코드),
    계약일시 varchar2(8),
    계약금액 number(10),
    지점id varchar2(10)
);

create index 계약_x01 on 계약(지점id, 계약일시);

explain plan for
select /*+ full(p) leading(p) use_hash(c) no_batch_table_access_by_rowid(c) */
    c.계약번호, c.상품코드, p.상품명, p.상품구분코드, c.계약일시, c.계약금액
from 계약 c, 상품 p
where c.지점id = :brch_id
and p.상품코드 = c.상품코드
order by c.계약일시 desc;

select * from table(dbms_xplan.display);

explain plan for
select /*+ leading(c) use_nl(p) */
    c.계약번호, c.상품코드, p.상품명, p.상품구분코드, c.계약일시, c.계약금액
from 계약 c, 상품 p
where c.지점id = :brch_id
and p.상품코드 = c.상품코드
order by c.계약일시 desc;

select * from table(dbms_xplan.display);

drop table 계약;
drop table 상품;
--------------------------------------------------------------------------------
-- 5.3 인덱스를 이용한 소트 연산 생략
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 5.3.1 sort order by 생략
--------------------------------------------------------------------------------
create table 종목거래(
    종목코드 varchar2(8),
    거래일시 varchar2(8),
    체결건수 number(10),
    체결수량 number(10),
    거래대금 number(10)
);

create index 종목거래_n1 on 종목거래(종목코드);

explain plan for
select 거래일시, 체결건수, 체결수량, 거래대금
from 종목거래
where 종목코드 = 'KR123456'
order by 거래일시;

select * from table(dbms_xplan.display);

drop index 종목거래_n1;

alter table 종목거래 add constraint 종목거래_pk primary key (종목코드, 거래일시);

explain plan for
select 거래일시, 체결건수, 체결수량, 거래대금
from 종목거래
where 종목코드 = 'KR123456'
order by 거래일시;

select * from table(dbms_xplan.display);

drop table 종목거래;
--------------------------------------------------------------------------------
-- 5.3.2 top n 쿼리
--------------------------------------------------------------------------------
create table 종목거래(
    종목코드 varchar2(8),
    거래일시 varchar2(8),
    체결건수 number(10),
    체결수량 number(10),
    거래대금 number(10),
    constraint 종목거래_pk primary key (종목코드, 거래일시)
);

explain plan for
select * from (
    select 거래일시, 체결건수, 체결수량, 거래대금
    from 종목거래
    where 종목코드 = 'KR123456'
    and 거래일시 >= '20180304'
    order by 거래일시
)
where rownum <= 10;

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 페이징 처리
--------------------------------------------------------------------------------
explain plan for
select *
from (
    select rownum no, a.*
    from (
        select 거래일시, 체결건수, 체결수량, 거래대금
        from 종목거래
        where 종목코드 = 'KR123456'
        and 거래일시 >= '20180304'
        order by 거래일시
    ) a
    where rownum <= (:page * 10)
)
where no >= (:page - 1) * 10 + 1;

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 페이징 처리 anti 패턴
--------------------------------------------------------------------------------
explain plan for
select *
from (
    select rownum no, a.*
    from (
        select 거래일시, 체결건수, 체결수량, 거래대금
        from 종목거래
        where 종목코드 = 'KR123456'
        and 거래일시 >= '20180304'
        order by 거래일시
    ) a
)
where no between (:page - 1) * 10 + 1 and (:page * 10);

select * from table(dbms_xplan.display);

drop table 종목거래;
--------------------------------------------------------------------------------
-- 부분범위 처리 가능하도록 sql 작성하기
--------------------------------------------------------------------------------
create table 거래(
    거래일자 varchar2(8),
    계좌번호 varchar2(10),
    거래순번 number(10),
    주문금액 number(10),
    주문수량 number(10),
    결제구분코드 varchar2(10),
    주문매체구분코드 varchar2(10),
    constraint 거래_pk primary key (거래일자, 계좌번호, 거래순번)
);

create index 거래_x01 on 거래(계좌번호, 거래순번, 결제구분코드);

explain plan for
select * from (
    select /*+ index_rs(거래 거래_pk) no_batch_table_access_by_rowid(거래) */
        계좌번호, 거래순번, 주문금액, 주문수량, 결제구분코드, 주문매체구분코드
    from 거래
    where 거래일자 = :ord_dt
    order by 계좌번호, 거래순번, 결제구분코드
)
where rownum <= 50;

select * from table(dbms_xplan.display);

explain plan for
select * from (
    select /*+ index_rs(거래 거래_pk) no_batch_table_access_by_rowid(거래) */
        계좌번호, 거래순번, 주문금액, 주문수량, 결제구분코드, 주문매체구분코드
    from 거래
    where 거래일자 = :ord_dt
    order by 계좌번호, 거래순번
)
where rownum <= 50;

select * from table(dbms_xplan.display);

drop table 거래;
--------------------------------------------------------------------------------
-- 5.3.3 최소값/최대값 구하기
--------------------------------------------------------------------------------
select /*+ gather_plan_statistics */ max(sal) from emp;

select * from table(dbms_xplan.display_cursor);

create index emp_x1 on emp(sal);

select /*+ gather_plan_statistics */ max(sal) from emp;

select * from table(dbms_xplan.display_cursor);

drop index emp_x1;
--------------------------------------------------------------------------------
-- 인덱스 이용해 최소/최대값 구하기 위한 조건
--------------------------------------------------------------------------------
create index emp_x1 on emp(deptno, mgr, sal);

select /*+ gather_plan_statistics */ max(sal)
from emp where deptno = 30 and mgr = 7698;

select * from table(dbms_xplan.display_cursor);

drop index emp_x1;

create index emp_x1 on emp(deptno, sal, mgr);

select /*+ gather_plan_statistics */ max(sal)
from emp where deptno = 30 and mgr = 7698;

select * from table(dbms_xplan.display_cursor);

drop index emp_x1;

create index emp_x1 on emp(sal, deptno, mgr);

select /*+ gather_plan_statistics */ max(sal)
from emp where deptno = 30 and mgr = 7698;

select * from table(dbms_xplan.display_cursor);

drop index emp_x1;

create index emp_x1 on emp(deptno, sal);

select /*+ gather_plan_statistics no_batch_table_access_by_rowid(emp) */ max(sal)
from emp where deptno = 30 and mgr = 7698;

select * from table(dbms_xplan.display_cursor);

drop index emp_x1;
--------------------------------------------------------------------------------
-- top n 쿼리 이용해 최소/최대값 구하기
--------------------------------------------------------------------------------
create index emp_x1 on emp(deptno, sal);

select /*+ gather_plan_statistics */ *
from (
    select sal
    from emp
    where deptno = 30
    and mgr = 7698
    order by sal desc
)
where rownum <= 1;

select * from table(dbms_xplan.display_cursor);

drop index emp_x1;
--------------------------------------------------------------------------------
-- 5.3.4 이력 조회
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 가장 단순한 이력 조회
--------------------------------------------------------------------------------
create table 장비(
    장비번호 number(10) constraint 장비_pk primary key,
    장비명 varchar2(10),
    장비구분코드 varchar2(4),
    상태코드 varchar2(4),
    최종변경일자 varchar2(8)
);

create index 장비_n1 on 장비(장비구분코드);

create table 상태변경이력(
    장비번호 number(10),
    변경일자 varchar2(8),
    변경순번 number(10),
    상태코드 varchar2(4),
    메모 varchar2(10),
    constraint 상태변경이력_pk primary key (장비번호, 변경일자, 변경순번)
);

explain plan for
select /*+ no_batch_table_access_by_rowid(p) */
       장비번호, 장비명, 상태코드,
       (select /*+ no_unnest index(상태변경이력) */ max(변경일자)
        from 상태변경이력
        where 장비번호 = p.장비번호) 최종변경일자
from 장비 p
where 장비구분코드 = 'A001';

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 점점 복잡해지는 이력 조회
--------------------------------------------------------------------------------
explain plan for
select 장비번호, 장비명, 상태코드,
       substr(최종이력, 1, 8) 최종변경일자,
       to_number(substr(최종이력, 9, 4)) 최종변경순번
from (
    select 장비번호, 장비명, 상태코드,
           (select max(h.변경일자 || lpad(h.변경순번, 4))
            from 상태변경이력 h
            where 장비번호 = p.장비번호) 최종이력
    from 장비 p
    where 장비구분코드 = 'A001'
);

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(p) */
       장비번호, 장비명, 상태코드,
       (select /*+ no_unnest index(h) */ max(h.변경일자)
        from 상태변경이력 h
        where 장비번호 = p.장비번호) 최종변경일자,
       (select /*+ no_unnest index(h) */ max(h.변경순번)
        from 상태변경이력 h
        where 장비번호 = p.장비번호
        and 변경일자 = (select /*+ index(h) */ max(h.변경일자)
                       from 상태변경이력 h
                       where 장비번호 = p.장비번호)) 최종변경순번
from 장비 p
where 장비구분코드 = 'A001';

select * from table(dbms_xplan.display);

explain plan for
select /*+ no_batch_table_access_by_rowid(p) */
       장비번호, 장비명,
       (select /*+ no_unnest index(h) */ max(h.변경일자)
        from 상태변경이력 h
        where 장비번호 = p.장비번호) 최종변경일자,
       (select /*+ no_unnest index(h1) */ max(h1.변경순번)
        from 상태변경이력 h1
        where 장비번호 = p.장비번호
        and 변경일자 = (select /*+ index(h2) */ max(h2.변경일자)
                       from 상태변경이력 h2
                       where 장비번호 = p.장비번호)) 최종변경순번,
       (select /*+ no_unnest index(h1) */ h1.상태코드
        from 상태변경이력 h1
        where 장비번호 = p.장비번호
        and 변경일자 = (select /*+ index(h2) */ max(h2.변경일자)
                       from 상태변경이력 h2
                       where 장비번호 = p.장비번호)
        and 변경순번 = (select /*+ index(h3) */ max(h3.변경순번)
                       from 상태변경이력 h3
                       where 장비번호 = p.장비번호
                       and 변경일자 = (select /*+ index(h4) */ max(h4.변경일자)
                                      from 상태변경이력 h4
                                      where 장비번호 = p.장비번호))) 최종상태코드
from 장비 p
where 장비구분코드 = 'A001';

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- index_desc 힌트 활용
--------------------------------------------------------------------------------
explain plan for
select 장비번호, 장비명,
       substr(최종이력, 1, 8) 최종변경일자,
       to_number(substr(최종이력, 9, 4)) 최종변경순번,
       substr(최종이력, 13) 최종상태코드
from (
    select /*+ no_batch_table_access_by_rowid(p) */
           장비번호, 장비명,
           (select /*+ index_desc(x 상태변경이력_pk)
                       no_batch_table_access_by_rowid(x) */
                   변경일자 || lpad(변경순번, 4) || 상태코드
            from 상태변경이력 x
            where 장비번호 = p.장비번호
            and rownum <= 1) 최종이력
    from 장비 p
    where 장비구분코드 = 'A001'
);

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 11g/12c 신기능 활용
--------------------------------------------------------------------------------
explain plan for
select 장비번호, 장비명,
       substr(최종이력, 1, 8) 최종변경일자,
       to_number(substr(최종이력, 9, 4)) 최종변경순번,
       substr(최종이력, 13) 최종상태코드
from (
    select /*+ no_batch_table_access_by_rowid(p) */
           장비번호, 장비명,
           (select 변경일자 || lpad(변경순번, 4) || 상태코드
            from (
                select 장비번호, 변경일자, 변경순번, 상태코드
                from 상태변경이력
                order by 변경일자 desc, 변경순번 desc)
            where 장비번호 = p.장비번호
            and rownum <= 1) 최종이력
    from 장비 p
    where 장비구분코드 = 'A001'
);

select * from table(dbms_xplan.display);

explain plan for
select 장비번호, 장비명,
       substr(최종이력, 1, 8) 최종변경일자,
       to_number(substr(최종이력, 9, 4)) 최종변경순번,
       substr(최종이력, 13) 최종상태코드
from (
    select /*+ no_batch_table_access_by_rowid(p) */
           장비번호, 장비명,
           (select 변경일자 || lpad(변경순번, 4) || 상태코드
            from (
                select 변경일자, 변경순번, 상태코드
                from 상태변경이력
                where 장비번호 = p.장비번호
                order by 변경일자 desc, 변경순번 desc)
            where rownum <= 1) 최종이력
    from 장비 p
    where 장비구분코드 = 'A001'
);

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 윈도우 함수와 row limiting 절
--------------------------------------------------------------------------------
-- (1) 이력 조회
explain plan for
select 장비번호, 장비명,
       substr(최종이력, 1, 8) 최종변경일자,
       to_number(substr(최종이력, 9, 4)) 최종변경순번,
       substr(최종이력, 13) 최종상태코드
from (
    select 장비번호, 장비명,
           (select 변경일자 || lpad(변경순번, 4) || 상태코드
            from (
                select 변경일자, 변경순번, 상태코드,
                       row_number() over (order by 변경일자 desc, 변경순번 desc) no
                from 상태변경이력
                where 장비번호 = p.장비번호)
            where no = 1) 최종이력
    from 장비 p
    where 장비구분코드 = 'A001'
);

select * from table(dbms_xplan.display);

explain plan for
select 장비번호, 장비명,
       substr(최종이력, 1, 8) 최종변경일자,
       to_number(substr(최종이력, 9, 4)) 최종변경순번,
       substr(최종이력, 13) 최종상태코드
from (
    select 장비번호, 장비명,
           (select 변경일자 || lpad(변경순번, 4) || 상태코드
            from 상태변경이력
            where 장비번호 = p.장비번호
            order by 변경일자 desc, 변경순번 desc
            fetch first 1 rows only) 최종이력
    from 장비 p
    where 장비구분코드 = 'A001'
);

select * from table(dbms_xplan.display);
-- (2) 페이징 처리
explain plan for
select 변경일자, 변경순번, 상태코드
from (
    select 변경일자, 변경순번, 상태코드,
           row_number() over (order by 변경일자, 변경순번) no
    from 상태변경이력
    where 장비번호 = :eqp_no)
where no between 1 and 10;

select * from table(dbms_xplan.display(format => 'advanced'));

explain plan for
select 변경일자, 변경순번, 상태코드
from (
    select rownum no, 변경일자, 변경순번, 상태코드
    from (
        select 변경일자, 변경순번, 상태코드
        from 상태변경이력
        where 장비번호 = :eqp_no
        order by 변경일자, 변경순번
        fetch first 10 rows only)
)
where no >= 1;

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 상황에 따라 달라져야 하는 이력 조회 패턴
--------------------------------------------------------------------------------
explain plan for
select /*+ ordered use_hash(h) full(p) */
       p.장비번호, p.장비명,
       h.변경일자 as 최종변경일자,
       h.변경순번 as 최종변경순번,
       h.상태코드 as 최종상태코드
from 장비 p,
     (select /*+ full(상태변경이력) */
             장비번호, 변경일자, 변경순번, 상태코드,
             row_number() over (partition by 장비번호
                                order by 변경일자 desc, 변경순번 desc) rnum
      from 상태변경이력) h
where h.장비번호 = p.장비번호
and h.rnum = 1;

select * from table(dbms_xplan.display);

explain plan for
select /*+ ordered use_hash(h) full(p) */
       p.장비번호, p.장비명,
       h.변경일자 as 최종변경일자,
       h.변경순번 as 최종변경순번,
       h.상태코드 as 최종상태코드
from 장비 p,
     (select /*+ full(상태변경이력) */
             장비번호,
             max(변경일자) 변경일자,
             max(변경순번) keep (dense_rank last order by 변경일자, 변경순번) 변경순번,
             max(상태코드) keep (dense_rank last order by 변경일자, 변경순번) 상태코드
      from 상태변경이력
      group by 장비번호) h
where h.장비번호 = p.장비번호;

select * from table(dbms_xplan.display);

drop table 상태변경이력;
drop table 장비;
--------------------------------------------------------------------------------
-- 선분 이력 맛보기
--------------------------------------------------------------------------------
create table 장비(
    장비번호 number(10) constraint 장비_pk primary key,
    장비명 varchar2(10),
    장비구분코드 varchar2(4),
    상태코드 varchar2(4),
    최종변경일자 varchar2(8)
);

create index 장비_n1 on 장비(장비구분코드);

create table 상태변경이력(
    장비번호 number(10),
    유효시작일자 varchar2(8),
    유효종료일자 varchar2(8),
    변경순번 number(10),
    상태코드 varchar2(4),
    메모 varchar2(10),
    constraint 상태변경이력_pk primary key (장비번호, 유효시작일자, 유효종료일자, 변경순번)
);

explain plan for
select /*+ index(p) index(h) */
       p.장비번호, p.장비명,
       h.상태코드, h.유효시작일자, h.유효종료일자, h.변경순번
from 장비 p, 상태변경이력 h
where p.장비구분코드 = 'A001'
and h.장비번호 = p.장비번호
and h.유효종료일자 = '99991231';

select * from table(dbms_xplan.display);

explain plan for
select /*+ index(p) index(h) */
       p.장비번호, p.장비명,
       h.상태코드, h.유효시작일자, h.유효종료일자, h.변경순번
from 장비 p, 상태변경이력 h
where p.장비구분코드 = 'A001'
and h.장비번호 = p.장비번호
and :base_dt between h.유효시작일자 and h.유효종료일자;

select * from table(dbms_xplan.display);
--------------------------------------------------------------------------------
-- 5.3.5 sort group by 생략
--------------------------------------------------------------------------------