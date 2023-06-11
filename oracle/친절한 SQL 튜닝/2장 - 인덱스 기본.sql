--------------------------------------------------------------------------------
-- 2장 - 인덱스 기본
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1 인덱스 구조 및 탐색
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.1.2 인덱스 구조
--------------------------------------------------------------------------------
create table 고객(
    고객id varchar2(10) constraint 고객_pk primary key,
    고객명 varchar2(10) not null
);

create index 고객_n1 on 고객(고객명);

drop index 고객_n1;
drop table 고객;
--------------------------------------------------------------------------------
-- 2.1.5 결합 인덱스 구조와 탐색
--------------------------------------------------------------------------------
create table 고객(
    고객id varchar2(10) constraint 고객_pk primary key,
    고객명 varchar2(10) not null,
    성별 varchar2(10) not null
);

create index 고객_n1 on 고객(성별, 고객명);

drop index 고객_n1;

create index 고객_n1 on 고객(고객명, 성별);
--------------------------------------------------------------------------------
-- 2.2 인덱스 기본 사용법
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2.2.2 인덱스를 Range Scan 할 수 없는 이유
--------------------------------------------------------------------------------
-- or expansion
create table 고객(
    고객id varchar2(10) constraint 고객_pk primary key,
    고객명 varchar2(10),
    전화번호 varchar2(10),
    성별 varchar2(10) not null
);

create index 고객_고객명_idx on 고객(고객명, 성별);
create index 고객_전화번호_idx on 고객(전화번호, 성별);

explain plan for
select *
from 고객 where 고객명 = :cust_nm
union all
select *
from 고객 where 전화번호 = :tel_no and (고객명 <> :cust_nm or 고객명 is null);

explain plan for
select /*+ use_concat */ *
from 고객
where (전화번호 = :tel_no or 고객명 = :cust_nm);

explain plan for
select /*+ no_expand */ *
from 고객
where (전화번호 = :tel_no or 고객명 = :cust_nm);

select * from table(dbms_xplan.display());

-- in-list iterator
explain plan for
select *
from 고객
where 전화번호 in (:tel_no1, :tel_no2);

explain plan for
select * from 고객
where 전화번호 = :tel_no1
union all
select * from 고객
where 전화번호 = :tel_no2;

select * from table(dbms_xplan.display());

drop table 고객;
--------------------------------------------------------------------------------
-- 2.2.3 더 중요한 인덱스 사용 조건
--------------------------------------------------------------------------------
create table 사원(
    사원번호 number(10) constraint 사원_pk primary key,
    소속팀 varchar2(10),
    사원명 varchar2(10) not null,
    연령 number(10),
    입사일자 date,
    전화번호 varchar2(10)
);

create index 사원_test_idx on 사원(소속팀, 사원명, 연령);

explain plan for
select /*+ index(사원 사원_test_idx) */ 사원번호, 소속팀, 연령, 입사일자, 전화번호
from 사원
where 사원명 = '홍길동';

select * from table(dbms_xplan.display());

drop table 사원;

create table txa1234(
    기준연도 varchar2(4) constraint txa1234_pk primary key,
    과세구분코드 varchar2(10),
    보고회차 number(10),
    실명확인번호 varchar2(10),
    dummy_column varchar2(10)
);

create index txa1234_ix02 on txa1234(기준연도, 과세구분코드, 보고회차, 실명확인번호);

explain plan for
select * from txa1234
where 기준연도 = :stdr_year
and substr(과세구분코드, 1, 4) = :txtn_dcd
and 보고회차 = :rpt_tmrd
and 실명확인번호 = :rnm_cnfm_no;

select * from table(dbms_xplan.display());

drop table txa1234;
--------------------------------------------------------------------------------
-- 인덱스 잘 타니까 튜닝 끝?
--------------------------------------------------------------------------------
create table 주문상품(
    dummy_column varchar2(10) constraint 주문상품_pk primary key,
    주문일자 date,
    상품번호 varchar2(10)
);

create index 주문상품_n1 on 주문상품(주문일자, 상품번호);

explain plan for
select /*+ no_batch_table_access_by_rowid(주문상품) */ *
from 주문상품
where 주문일자 = :ord_dt
and 상품번호 like '%PING%';

explain plan for
select /*+ no_batch_table_access_by_rowid(주문상품) */ *
from 주문상품
where 주문일자 = :ord_dt
and substr(상품번호, 1, 4) = 'PING';

select * from table(dbms_xplan.display());

drop table 주문상품;
--------------------------------------------------------------------------------
-- 2.2.4 인덱스를 이용한 소트 연산 생략
--------------------------------------------------------------------------------
-- 소트 생략 가능
create table 상태변경이력(
    장비번호 varchar2(1),
    변경일자 varchar2(8),
    변경순번 varchar2(6),
    dummy_column varchar2(1),
    dummy_column2 varchar2(1)
);

alter table 상태변경이력 add constraint 상태변경이력_pk primary key (장비번호, 변경일자, 변경순번);

insert into 상태변경이력 values('B', '20180505', '031583', '1', null);
insert into 상태변경이력 values('C', '20180316', '000001', '5', null);
insert into 상태변경이력 values('C', '20180316', '000002', '6', null);
insert into 상태변경이력 values('C', '20180316', '131576', '3', null);
insert into 상태변경이력 values('C', '20180316', '131577', '2', null);
insert into 상태변경이력 values('C', '20180428', '000001', '9', null);
insert into 상태변경이력 values('C', '20180428', '000002', '8', null);

select /*+ gather_plan_statistics no_batch_table_access_by_rowid(상태변경이력) */ *
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316';

select /*+ gather_plan_statistics */ *
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316'
order by 변경순번;

select * from table(dbms_xplan.display_cursor(null, 0, 'advanced allstats last'));

-- 소트 생략 불가능
alter table 상태변경이력 drop constraint 상태변경이력_pk;
alter table 상태변경이력 add constraint 상태변경이력_pk primary key (장비번호, 변경일자, dummy_column, 변경순번);

select /*+ gather_plan_statistics no_batch_table_access_by_rowid(상태변경이력) */ *
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316'
order by 변경순번;

select * from table(dbms_xplan.display_cursor(null, 0, 'advanced allstats last'));

-- 내림차순 소트 생략
alter table 상태변경이력 drop constraint 상태변경이력_pk;
alter table 상태변경이력 add constraint 상태변경이력_pk primary key (장비번호, 변경일자, 변경순번);

select /*+ gather_plan_statistics no_batch_table_access_by_rowid(상태변경이력) */ *
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316'
order by 변경순번 desc;

select * from table(dbms_xplan.display_cursor(null, 0, 'advanced allstats last'));

drop table 상태변경이력;
--------------------------------------------------------------------------------
-- 2.2.5 order by 절에서 컬럼 가공
--------------------------------------------------------------------------------
-- order by절 컬럼 가공 1
create table 상태변경이력(
    장비번호 varchar2(1),
    변경일자 varchar2(8),
    변경순번 varchar2(6),
    dummy_column varchar2(1),
    constraint 상태변경이력_pk primary key (장비번호, 변경일자, 변경순번)
);

insert into 상태변경이력 values('B', '20180505', '031583', null);
insert into 상태변경이력 values('C', '20180316', '000001', null);
insert into 상태변경이력 values('C', '20180316', '000002', null);
insert into 상태변경이력 values('C', '20180316', '131576', null);
insert into 상태변경이력 values('C', '20180316', '131577', null);
insert into 상태변경이력 values('C', '20180428', '000001', null);
insert into 상태변경이력 values('C', '20180428', '000002', null);

select /*+ gather_plan_statistics index(상태변경이력) no_batch_table_access_by_rowid(상태변경이력) */ *
from 상태변경이력
where 장비번호 = 'C'
order by 변경일자, 변경순번;

select * from table(dbms_xplan.display_cursor(null, 0, 'advanced allstats last'));

select /*+ gather_plan_statistics index(상태변경이력) no_batch_table_access_by_rowid(상태변경이력) */ *
from 상태변경이력
where 장비번호 = 'C'
order by 변경일자 || 변경순번;

select * from table(dbms_xplan.display_cursor(null, 0, 'advanced allstats last'));

drop table 상태변경이력;

-- order by절 컬럼 가공 2
create table 주문(
    주문일자 date,
    주문번호 number(10),
    업체번호 varchar2(10),
    주문금액 number(10),
    constraint 주문_pk primary key (주문일자, 주문번호)
);

explain plan for
select *
from (
    select /*+ no_batch_table_access_by_rowid(a) */
        to_char(a.주문번호, 'FM000000') as 주문번호, a.업체번호, a.주문금액
    from 주문 a
    where a.주문일자 = :dt and a.주문번호 > nvl(:next_ord_no, 0)
    order by 주문번호
)
where rownum <= 30;

select * from table(dbms_xplan.display());

explain plan for
select *
from (
    select /*+ no_batch_table_access_by_rowid(a) */
        to_char(a.주문번호, 'FM000000') as 주문번호, a.업체번호, a.주문금액
    from 주문 a
    where a.주문일자 = :dt and a.주문번호 > nvl(:next_ord_no, 0)
    order by a.주문번호
)
where rownum <= 30;

select * from table(dbms_xplan.display());

drop table 주문;
--------------------------------------------------------------------------------
-- 2.2.6 SELECT-LIST에서 컬럼 가공
--------------------------------------------------------------------------------
create table 상태변경이력(
    장비번호 varchar2(1),
    변경일자 varchar2(8),
    변경순번 varchar2(6),
    dummy_column varchar2(1) not null,
    constraint 상태변경이력_pk primary key (장비번호, 변경일자, 변경순번)
);

explain plan for
select /*+ index(상태변경이력 상태변경이력_pk) */ min(변경순번)
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316';

select * from table(dbms_xplan.display());

explain plan for
select /*+ index(상태변경이력 상태변경이력_pk) */ max(변경순번)
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316';

select * from table(dbms_xplan.display());

explain plan for
select /*+ index(상태변경이력 상태변경이력_pk) */ nvl(max(to_number(변경순번)), 0)
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316';

select * from table(dbms_xplan.display());

explain plan for
select /*+ index(상태변경이력 상태변경이력_pk) */ nvl(to_number(max(변경순번)), 0)
from 상태변경이력
where 장비번호 = 'C'
and 변경일자 = '20180316';

select * from table(dbms_xplan.display());

create table 장비(
    장비번호 varchar2(1) constraint 장비_pk primary key,
    장비명 varchar2(10),
    상태코드 varchar2(10),
    장비구분코드 varchar2(4) not null
);

create index 장비_n1 on 장비(장비구분코드);

explain plan for
select /*+ no_batch_table_access_by_rowid(p) */
    장비번호, 장비명, 상태코드,
    (select /*+ no_unnest index(상태변경이력 상태변경이력_pk) */ max(변경일자)
     from 상태변경이력 where 장비번호 = p.장비번호) 최종변경일자
from 장비 p
where 장비구분코드 = 'A001';

select * from table(dbms_xplan.display());

explain plan for
select /*+ no_batch_table_access_by_rowid(p) */
    장비번호, 장비명, 상태코드,
    (select /*+ no_unnest index(상태변경이력 상태변경이력_pk) */ max(변경일자)
     from 상태변경이력 where 장비번호 = p.장비번호
    ) 최종변경일자,
    (select /*+ index(상태변경이력 상태변경이력_pk) */ max(변경순번)
     from 상태변경이력
     where 장비번호 = p.장비번호 and 변경일자 = (
        select /*+ index(상태변경이력 상태변경이력_pk) */ max(변경일자)
        from 상태변경이력 where 장비번호 = p.장비번호)
    ) 최종변경순번
from 장비 p
where 장비구분코드 = 'A001';

select * from table(dbms_xplan.display());

explain plan for
select
    장비번호, 장비명, 상태코드,
    substr(최종이력, 1, 8) 최종변경일자,
    substr(최종이력, 9) 최종변경순번
from (
    select /*+ no_batch_table_access_by_rowid(p) */
        장비번호, 장비명, 상태코드,
        (select max(변경일자 || 변경순번) from 상태변경이력 where 장비번호 = p.장비번호) 최종이력
    from 장비 p
    where 장비구분코드 = 'A001'
);

select * from table(dbms_xplan.display());

drop table 장비;
drop table 상태변경이력;
--------------------------------------------------------------------------------
-- 2.2.7 자동 형변환
--------------------------------------------------------------------------------
create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    생년월일 varchar2(20) not null,
    가입일자 date not null
);

create index 고객_생년월일_idx on 고객(생년월일);

explain plan for
select * from 고객
where 생년월일 = 19821225;

select * from table(dbms_xplan.display());

create index 고객_가입일자_idx on 고객(가입일자);

explain plan for
select * from 고객
where 가입일자 = '01-JAN-2018';

select * from table(dbms_xplan.display());

explain plan for
select * from 고객
where 가입일자 = to_date('01-JAN-2018', 'DD-MON-YYYY');

select * from table(dbms_xplan.display());

explain plan for
select * from 고객
where 고객번호 like '9410%';

select * from table(dbms_xplan.display());

drop table 고객;

create table 거래(
    계좌번호 number(10),
    거래일자 date
);

alter table 거래 add constraint 거래_pk primary key (계좌번호, 거래일자);

explain plan for
select * from 거래
where 계좌번호 = :acnt_no
and 거래일자 between :trd_dt1 and :trd_dt2;

explain plan for
select * from 거래
where 거래일자 between :trd_dt1 and :trd_dt2;

select * from table(dbms_xplan.display());

explain plan for
select * from 거래
where 계좌번호 like :acnt_no || '%'
and 거래일자 between :trd_dt1 and :trd_dt2;

select * from table(dbms_xplan.display());

alter table 거래 drop constraint 거래_pk;
alter table 거래 add constraint 거래_pk primary key (거래일자, 계좌번호);

explain plan for
select * from 거래
where 계좌번호 like :acnt_no || '%'
and 거래일자 between :trd_dt1 and :trd_dt2;

select * from table(dbms_xplan.display());

drop table 거래;
--------------------------------------------------------------------------------
-- 자동 형변환 주의
--------------------------------------------------------------------------------
create table tt(
    n_col number(10)
);
insert into tt values(10);

declare
    v_col varchar2(10) := '10abc';
    result number(10);
begin
    select n_col into result from tt where n_col = v_col;
end;
/

drop table tt;

select round(avg(sal)) avg_sal,
       min(sal) min_sal,
       max(sal) max_sal,
       max(decode(job, 'PRESIDENT', null, sal)) max_sal2
from emp;

select round(avg(sal)) avg_sal,
       min(sal) min_sal,
       max(sal) max_sal,
       max(decode(job, 'PRESIDENT', to_number(null), sal)) max_sal2
from emp;

select round(avg(sal)) avg_sal,
       min(sal) min_sal,
       max(sal) max_sal,
       max(decode(job, 'PRESIDENT', 0, sal)) max_sal2
from emp;