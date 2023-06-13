--------------------------------------------------------------------------------
-- 3장 - 인덱스 튜닝
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3.1 테이블 액세스 최소화
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 3.1.1 테이블 랜덤 액세스
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 인덱스 rowid는 물리적 주소? 논리적 주소?
--------------------------------------------------------------------------------
create table 고객(
    고객명 varchar2(10) not null,
    지역 varchar2(10) not null
);

create index 고객_지역_idx on 고객(지역);

explain plan for 
select /*+ no_batch_table_access_by_rowid(고객) */ *
from 고객 where 지역 = '서울';

select * from table(dbms_xplan.display());

drop table 고객;
--------------------------------------------------------------------------------
-- 3.1.3 인덱스 손익분기점
--------------------------------------------------------------------------------
create table big_table
as select level no from dual connect by level <= 100000;

select /*+ full(t) */ count(*) from big_table t where no <= 1;
select /*+ full(t) */ count(*) from big_table t where no <= 10;
select /*+ full(t) */ count(*) from big_table t where no <= 100;
select /*+ full(t) */ count(*) from big_table t where no <= 1000;
select /*+ full(t) */ count(*) from big_table t where no <= 10000;
select /*+ full(t) */ count(*) from big_table t where no <= 100000;

drop table big_table;
--------------------------------------------------------------------------------
-- 온라인 프로그램 튜닝 vs. 배치 프로그램 튜닝 (todo)
--------------------------------------------------------------------------------
create table 고객(
    고객번호 number(10) constraint 고객_pk primary key,
    고객명 varchar2(10) not null,
    실명확인번호 number(10) not null,
    고객구분코드 varchar2(4) not null
);

create index 고객_x01 on 고객(실명확인번호);
create index 고객_x02 on 고객(고객구분코드);

create table 고객변경이력(
    고객번호 number(10) not null,
    변경일시 date not null,
    전화번호 varchar2(10) not null,
    주소 varchar2(10) not null,
    상태코드 varchar2(10) not null,
    constraint 고객변경이력_pk primary key(고객번호, 변경일시)
);

-- todo : 실행계획 똑같이 안나옴
explain plan for
select /*+ leading(c) index(c 고객_x01) no_batch_table_access_by_rowid(c) */ c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
from 고객 c, 고객변경이력 h
where c.실명확인번호 = :rmnno
and h.고객번호 = c.고객번호
and h.변경일시 = (
    select /*+ index(m 고객변경이력_pk) */ max(변경일시)
    from 고객변경이력 m
    where 고객번호 = c.고객번호
    and 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
    and 변경일시 < trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display());

create table 고객_임시(
    고객번호 number(10) not null,
    고객명 varchar2(10) not null,
    변경일시 date not null,
    전화번호 varchar2(10) not null,
    주소 varchar2(10) not null,
    상태코드 varchar2(10) not null,
    constraint 고객_임시_pk primary key(고객번호, 변경일시)
);

-- todo : 실행계획 똑같이 안나옴
explain plan for
insert into 고객_임시
select /*+ leading(c) index(c 고객_x02) no_batch_table_access_by_rowid(c) */
    c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
from 고객 c, 고객변경이력 h
where c.고객구분코드 = 'A001'
and h.고객번호 = c.고객번호
and h.변경일시 = (
    select /*+ index(m 고객변경이력_pk) unnest */ max(변경일시)
    from 고객변경이력 m
    where 고객번호 = c.고객번호
    and 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
    and 변경일시 < trunc(sysdate, 'mm')
);

select * from table(dbms_xplan.display());

explain plan for
insert into 고객_임시
select /*+ full(c) full(h) index_ffs(m.고객변경이력)
           ordered no_merge(m) use_hash(m) use_hash(h) */
    c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시
from 고객 c,
    (
        select 고객번호, max(변경일시) 최종변경일시
        from 고객변경이력
        where 변경일시 >= trunc(add_months(sysdate, -12), 'mm')
        and 변경일시 < trunc(sysdate, 'mm')
        group by 고객번호
    ) m,
    고객변경이력 h
where c.고객구분코드 = 'A001'
and m.고객번호 = c.고객번호
and h.고객번호 = m.고객번호
and h.변경일시 = m.최종변경일시;

select * from table(dbms_xplan.display());

explain plan for
insert into 고객_임시
select 고객번호, 고객명, 전화번호, 주소, 상태코드, 변경일시
from (
    select /*+ full(c) full(h) leading(c) use_hash(h) */
        c.고객번호, c.고객명, h.전화번호, h.주소, h.상태코드, h.변경일시,
        rank() over (partition by h.고객번호 order by h.변경일시 desc) no
    from 고객 c, 고객변경이력 h
    where c.고객구분코드 = 'A001'
    and h.변경일시 >= trunc(add_months(sysdate, -12), 'mm')
    and h.변경일시 < trunc(sysdate, 'mm')
    and h.고객번호 = c.고객번호)
where no = 1;

select * from table(dbms_xplan.display());

drop table 고객_임시;
drop table 고객변경이력;
drop table 고객;
--------------------------------------------------------------------------------
-- 3.1.4 인덱스 컬럼 추가
--------------------------------------------------------------------------------
-- ...