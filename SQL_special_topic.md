## 专题： timestamp
```
#时间戳转换为日期时间字符串
from_unixtime(int unixtime)
#example
from_unixtime(0) = "1970-01-01 00:00:00"
```
```
#日期时间字符串返回日期字符串
to_date(string timestamp)
#example
to_date("1970-01-01 00:00:00") = "1970-01-01"
```
```
#返回年
year(string date)
#example
year("1970-01-01 00:00:00") = 1970
year("1970-01-01") = 1970

#同理
month(string date)
day(string date)
hour(string date)
minute(string date)
second(string date)
```
```
#返回不同格式的时间
DATE_FORMATE(DATE,format)
#example
DATE_FORMATE("2017-06-15","%Y")
#格式
%Y%m%d 2017-06-15
%H%i%s 16:35:41

month(qpd.date) = 8
```
```
#算时间差
datediff(string enddate, string startdate)
#example
datediff('2009-03-01','2009-02-27') = 2
```
```
#增加天
date_add(string startdate, int days)
#example
date_add('2008-12-31', 1) = '2009-01-01'

#其他格式
DATE_ADD(date, INTERVAL value addunit)
DATE_ADD("2017-06-24", INTERVAL 10 DAY)
DATE_ADD("2017-06-15 09:34:21", INTERVAL 15 MINUTE)
```
```
#减少天
datesub(string startdaye, int days)
#example
date_sub('2008-12-31', 1) = '2008-12-30'
```
**实例**
**timestamp 类型：in_time ="2021-11-01 10:00:00"**

获取 “2021-11-01”
```
date(in_time)
```
获取两个timestamp之间的秒数时间差
```
timestampdiff(second,in_time,out_time)
```
获取年月 “2021-11”
```
date_format(in_time,"%Y-%m")
```
留存率，第二天依旧活跃，使用left join条件 第二天-1 = 第一天
```
t1.dt = date_sub(t2.dt, INTERVAL 1 day)
```

**时间函数例题**
***VQ30 广告点击的高峰期***
牛客购买点击表`user_ad_click_time`, 支付成功表`user_payment_time`，求出哪个小时为广告点击的高峰期,以及发生的点击次数，查询返回结果名称和顺序
```
select 
    hour(click_time) as click_hour,
    count(click_time) as click_cnt
from
    user_ad_click_time
group by hour(click_time)
limit 1
```

***VQ31  输出在5min内完成点击购买的用户ID***
```
SELECT
    distinct user_id as uid
FROM
    user_ad_click_time
JOIN
    user_payment_time
USING(user_id,trace_id)
WHERE  TIMESTAMPDIFF(MINUTE,click_time,pay_time) < 5
order by uid
```
&nbsp;
### 专题：字符串函数
```
#合并字符串
concat(string A, string B)
#example
concat('foo','bar') = 'foobar'
```


```
#返回字符串
substr(string A, int start, in len)
#example
substr('foobar', 1, 2) =  'fo' #从第一个字符开始取两个字符
```

```
#返回字符串
substr(string A, int start)
#example
substr('foobar', 4) =  'bar' #从第4个字符开始取到最后
```

**substring_index字符串截取**
```
性别给在了profile里面，我们需要学会取出 gender
profile: 180cm,75kg,27,male

substring_index(str,delim,count)
str:要处理的字符串
delim:分隔符
count:计数

str=www.wikibt.com
substring_index(str,'.',-1)
结果：com

如果要中间的
substring_index(substring_index(str,'.',-2),'.',1)
```

**LIKE 字符串截取**
```
同样profile的另一种写法

if(profile LIKE '%female','female','male') as gender
```


***字符转换函数***
- ASCII() 返回字符表达式最左端字符的ASCII 码值。
- CHAR() 将ASCII 码转换为字符。如果没有输入0 ~ 255 之间的ASCII 码值，CHAR（） 返回NULL 。
- STR() 把数值型数据转换为字符型数据。

***去空格函数***
- LTRIM() 把字符串头部的空格去掉。
- RTRIM() 把字符串尾部的空格去掉。


***取子串函数***
- LEFT (<character_expression>， <integer_expression>) 返回character_expression 左起 integer_expression 个字符。
- RIGHT (<character_expression>， <integer_expression>)
返回character_expression 右起 integer_expression 个字符。
- SUBSTRING (<expression>， <starting_ position>， length)
返回从字符串左边第starting_ position 个字符起length个字符的部分。

***操作***
- concat字符串拼接
- COALESCE (expression_1, expression_2, ...,expression_n)依次参考各参数表达式，遇到非null值即停止并返回该值。 如果所有的表达式都是空值，最终将返回一个空值。

```
SELECT 
	first_name, 
    last_name, 
    lower(concat(substring(first_name, 1, 3),'.', substring(colesce(last_name,'SNOW'),1,5))) as amazon_email
    from amzn_employees;
```

&nbsp;

**字符函数例题**
***VQ32 字符串正则匹配1***
牛客有评论记录表`comment_detail`，输出 comment中包含 "是"，或"试"，或"报名"的 id，comment列，查询返回结果名称和顺序
```
select 
    id,
    comment
from 
    comment_detail
where comment regexp  '是|试|报名'
```
牛客有评论记录表`comment_detail`，输出 comment 以 '是' 或 '求' 开头的的 id，comment列，查询返回结果名称和顺序
```
SELECT 
    id,
    comment 
FROM comment_detail 
WHERE comment regexp '^[是|求]'
```

&nbsp;
### case when 分支
case函数
```
CASE 测试表达式
WHEN 简单表达式1 THEN 结果表达式1
WHEN 简单表达式2 THEN 结果表达式2 …
WHEN 简单表达式n THEN 结果表达式n
[ ELSE 结果表达式n+1 ]
END
```
例子1：
```
SELECT 学号,课程号,
CASE
WHEN 成绩 >= 90 THEN '优'
WHEN 成绩 BETWEEN 80 AND 89 THEN '良'
WHEN 成绩 BETWEEN 70 AND 79 THEN '中'
WHEN 成绩 BETWEEN 60 AND 69 THEN '及格'
WHEN 成绩 <60 THEN '不及格'
END 成绩
FROM 成绩表
WHERE 课程号 = 'M01F011'
```
例子2：
```
SELECT CASE WHEN age < 25 OR age IS NULL THEN '25岁以下'
            WHEN age >= 25 THEN '25岁及以上'
            END age_cut,COUNT(*)number  #这两个显示的是列名
FROM user_profile
GROUP BY age_cut
```
例子3 和sum使用
```
SELECT item_id,
IFNULL(SUM(CASE WHEN DAYOFWEEK(order_datetime) = 7 THEN order_quantity END),0) AS Saturday_Units,
IFNULL(SUM(CASE WHEN DAYOFWEEK(order_datetime) = 4 THEN order_quantity END),0) as Wednesday_Units
From orders
group by item_id;

```
&nbsp;
### 窗口函数
***排序***
```
rank()排序相同时会重复，总数不变，即会出现1、1、3这样的排序结果；
dense_rank()排序相同时会重复，总数会减少，即会出现1、1、2这样的排序结果；
row_number()排序相同时不会重复，会根据顺序排序。
```
```
select 
date,
user_id,
pass_count
from 
    (select 
    date,
    user_id,
    pass_count,
    row_number() over(partition by date order by pass_count desc) as rk
    from questions_pass_record )t
where rk <= 2
```
&nbsp;
***ROWS 子句***
ROWS BETWEEN lower_bound AND upper_bound
- UNBOUNDED PRECEDING– 当前行之前的所有行。
- n PRECEDING–当前行之前的n行。
- CURRENT ROW– 仅当前行。
- n FOLLOWING–当前行之后的n行。
- UNBOUNDED FOLLOWING– 当前行之后的所有行。


```
-- 我们要添加另一列来显示从第一个日期到当前行日期的总收入
SELECT date, revenue,
    SUM(revenue) OVER (
      ORDER BY date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running_total
FROM sales
ORDER BY date;
```

```
-- 我们要分别计算每个城市的三天移动平均温度。为了分开两个城市的计算，我们将包含该PARTITION BY子句。然后，在指定窗口框架时，我们将考虑当天和前两天：

SELECT city, date, temperature,
    ROUND(AVG(temperature) OVER (
      PARTITION BY city
      ORDER BY date DESC
      ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING), 1) mov_avg_3d_city
FROM weather
ORDER BY city, date;

```
-  lag() over() 与 lead() over() 函数是跟偏移量相关的两个分析函数，通过这两个函数可以在一次查询中取出同一字段的前 N 行的数据 (lag) 和后 N 行的数据 (lead) 作为独立的列, 从而更方便地进行进行数据过滤。
```
-- Monthly Percentage Difference
-- Month-over-month percentage in revenue
Select data_format(created_at, '%Y-%m') as ym,
	round((sum(value) - LAG(sum(value)) over())/ LAG(SUM(VALUE)) OVER () * 100, 2) AS REVENUE_DIFF_PCT
FROM SF_TRANSACTIONS
GROUP BY ym
order by ym;
```
```
-- Revenue Over Time
-- 3-month rolling avarage of total revenue from purchases 
Select data, avg(puchase_amt) over (order by date rows 2 preceding) rolling 
from 
(select date_format(create_at, '%Y-%m') date, sum(purchase_amt) as purchase_amt
	from amazon_purchases
where purchase_amt > 0
group by 1)t;
```
&nbsp;
&nbsp;
### 聚合函数
- COUNT：统计行数量
- SUM：获取单个列的合计值
- AVG：计算某个列的平均值
- MAX：计算列的最大值
- MIN：计算列的最小值

&nbsp;
### HAVING
执行顺序为：WHERE过滤→分组→聚合函数
在聚合之后执行过滤条件: HAVING
```
SELECT student_class,AVG(student_age) AS 平均年龄 
FROM t_student 
GROUP BY (student_class) 
HAVING AVG(student_age)>20; 
```
- 聚合语句(sum,min,max,avg,count)要比having子句优先执行，所有having后面可以使用聚合函数。 
- where子句在查询过程中执行优先级别优先于聚合语句(sum,min,max,avg,count)，所有where条件中不能使用聚合函数。

&nbsp;
### 子查询

***where 中嵌套***
```
SELECT * 
FROM t_student 
WHERE student_subject='C语言' 
AND student_score>=ALL (SELECT student_score FROM t_student WHERE student_subject='C语言') ;
```
where XXX in (select XXX from XXX)
```
select customer_id, date(order_datetime) as Order_date, item_id as first_order_id
from orders 
where order_datetime in
(select  min(order_datetime) as First_order_time 
from orders 
group by customer_id)
group by customer_id
```
***子查询运算符***
- ALL运算符
　　和子查询的结果逐一比较，必须全部满足时表达式的值才为真。
- ANY运算符
　　和子查询的结果逐一比较，其中一条记录满足条件则表达式的值就为真。
- EXISTS/NOT EXISTS运算符
　　EXISTS判断子查询是否存在数据，如果存在则表达式为真，反之为假。NOT EXISTS相反。
在子查询或相关查询中，要求出某个列的最大值，通常都是用ALL来比较，大意为比其他行都要大的值即为最大值。

***With***
```
With daily_aggregate AS(
	select order_dt,customer_id, sum(unit_price_usd * qty)daily_spend
    from orders
    group by order_dt, customer_id
),

cumulative_daily_spend AS (
	select
		customer_id, order_dt, sum(daily_spend) over (partition by customer_id order by order_dt)cumulative_spend
        from daily aggreagte)

select cunstomer_id, Min(order_dt) as first_date
from cumulative_daily_spend
where cumulative_spend > 8000
group by customer_id;
```

&nbsp;
### Union
-  union和union all的区别是,union会自动压缩多个结果集合中的重复结果，而union all则将所有的结果全部显示出来，不管是不是重复。
-  列名字必须一模一样

&nbsp;
### Join
- inner join XX on
- left join
- right join
- full join