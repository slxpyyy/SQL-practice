#Grab笔试
create table test_groups (
      name varchar(40) not null,
      test_value integer not null,
      unique(name)
  );

  create table test_cases (
      id integer not null,
      group_name varchar(40) not null,
      status varchar(5) not null,
      unique(id)
  );

insert into test_groups values ('performance', 15);
insert into test_groups values ('corner cases', 10);
insert into test_groups values ('numerical stability', 20);
insert into test_groups values ('memory usage', 10);
insert into test_groups values ('partial functionality', 20);
insert into test_groups values ('full functionality', 40);


insert into test_cases values (1, 'performance', 'ERROR');
insert into test_cases values (2, 'full functionality', 'ERROR');


SELECT 
g.name, 
count(c.group_name) as all_test_cases, 
sum(case when status = 'OK' then 1 else 0 end) as passed_test_cases,
sum(case when status = 'OK' then test_value else 0 end) as total_value
from test_groups g
left join test_cases c
on c.group_name = g.name
group by g.name,c.group_name
order by total_value desc, g.name

#拼多多笔试1
DROP TABLE if exists user_pv_log ;
CREATE TABLE user_pv_log (
      uid            varchar(20)
    , page_name      varchar(20)
    , log_time       datetime 
)
;

INSERT INTO user_pv_log 
    (uid, page_name, log_time )
VALUES
     ('UID001','首页','2022-07-01 08:30:00')
    ,('UID001','搜索结果页','2022-07-01 08:31:00')
    ,('UID001','商品详情页','2022-07-01 08:32:00')

    ,('UID002','商品详情页','2022-07-01 09:32:00')
    ,('UID003','首页','2022-07-01 10:32:00')
    ,('UID003','商品详情页','2022-07-01 10:33:00')
;

select date(log_time) from user_pv_log;

#首页
select uid, min(log_time) from user_pv_log group by uid;

#结果页
select uid, max(log_time) from user_pv_log group by uid;

#首页
select page_name,count(*) as frs_view_uv 
from user_pv_log 
where (uid,log_time) in 
(select uid, min(log_time) from user_pv_log group by uid)
group by page_name
order by page_name;

#结果页
select count(*) as frs_view_uv 
from user_pv_log 
where (uid,log_time) in 
(select uid, max(log_time) from user_pv_log group by uid)
group by page_name;

#合并
select 
a.page_name, 
if(a.frs_view_uv is null, 0, a.frs_view_uv) as frs_view_uv,
if(b.lst_view_uv is null, 0, b.lst_view_uv) as lst_view_uv
from
	(select u1.page_name,count(*) as frs_view_uv 
	from user_pv_log u1
	where (u1.uid,u1.log_time) in 
		(select uid, min(log_time) from user_pv_log group by uid)
	group by u1.page_name)a 
	left join 
	(select u2.page_name,count(*) as lst_view_uv 
	from user_pv_log u2
	where (u2.uid,u2.log_time) in 
		(select uid, max(log_time) from user_pv_log group by uid)
	group by u2.page_name)b
	on a.page_name = b.page_name
order by a.page_name;




#拼多多笔试2
DROP TABLE if exists order_info;
CREATE TABLE order_info(
      order_time    datetime
    , uid           varchar(20)
    , order_id      varchar(20)
    , order_amt      double 
)
;

INSERT INTO order_info
    (order_time, uid, order_id ,order_amt )
VALUES
     ('2022-06-15 12:00:45','UID0001','ORDR-001',894.6)
    ,('2022-06-16 12:00:45','UID0001','ORDR-002',295.4)
    ,('2022-06-17 12:00:45','UID0002','ORDR-003',755.4)
    ,('2022-06-18 12:00:45','UID0002','ORDR-004',99.2)
    ,('2022-06-19 12:00:45','UID0003','ORDR-005',353.4)
;

select distinct(date(order_time)) as pt from order_info;

select 
t.pt,
round(SUM(t.order_amt) OVER(ORDER BY t.pt
                    ROWS BETWEEN unbounded preceding AND current row),1) as ordr_amt
from 
(select 
    distinct(date(order_time)) as pt,
    order_amt
from order_info
group by pt)t;


select 
distinct(date(order_time)) as pt,
order_amt
 from order_info
group by pt


#拼多多笔试3
DROP TABLE if exists usr_goods_clk_log ;
CREATE TABLE usr_goods_clk_log (
      uid           varchar(20)
    , goods_id      varchar(20)
    , scene_id      varchar(20)
    , clk_log_time      datetime 
)
;

INSERT INTO usr_goods_clk_log 
    (uid, goods_id, scene_id ,clk_log_time )
VALUES
     ('UID001','goods001','scene001','2022-07-01 08:03:00')
    ,('UID001','goods001','scene002','2022-07-01 09:00:00')
    ,('UID002','goods002','scene001','2022-07-01 11:00:01')
    ,('UID002','goods002','scene003','2022-07-01 13:05:01')
    ,('UID002','goods003','scene004','2022-07-02 14:10:01')
    ,('UID002','goods003','scene001','2022-07-02 15:03:10')
;


DROP TABLE if exists ordr_info ;
CREATE TABLE ordr_info (
      ordr_sn       varchar(20)
    , uid           varchar(20)
    , goods_id      varchar(20)
    , pay_time      datetime 
)
;

INSERT INTO ordr_info 
    (ordr_sn, uid, goods_id ,pay_time )
VALUES
     ('order0001','UID001','goods001','2022-07-01 09:05:01')
    ,('order0002','UID002','goods002','2022-07-01 12:10:01')
    ,('order0003','UID002','goods003','2022-07-02 15:05:00')
;

group by stat_dt,scene_id
