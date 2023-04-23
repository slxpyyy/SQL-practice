# SQL Practice 1

https://www.nowcoder.com/practice/96263162f69a48df9d84a93c71045753?tpId=268&tqId=2285032&ru=/exam/oj&qru=/ta/sql-factory-interview/question-ranking&sourceUrl=%2Fexam%2Foj%3Fpage%3D1%26tab%3DSQL%25E7%25AF%2587%26topicId%3D268


### SQL156 各个视频的平均完播率
问题：计算2021年里有播放记录的每个视频的完播率(结果保留三位小数)，并按完播率降序排序

注：视频完播率是指完成播放次数占总播放次数的比例。简单起见，结束观看时间与开始播放时间的差>=视频时长时，视为完成播放。

```
SELECT a.video_id ,
       round(sum(if(end_time - start_time >= duration,1,0))/count(start_time ),3) as avg_comp_play_rate
FROM tb_user_video_log a
LEFT JOIN tb_video_info b
on a.video_id = b. video_id
WHERE year(start_time) = 2021
GROUP BY a.video_id
ORDER BY avg_comp_play_rate DESC
```


### SQL157 平均播放进度大于60%的视频类别
问题：计算各类视频的平均播放进度，将进度大于60%的类别输出。

注：
播放进度=播放时长÷视频时长*100%，当播放时长大于视频时长时，播放进度均记为100%。
结果保留两位小数，并按播放进度倒序排序。

```
SELECT tag, CONCAT(avg_play_progress, "%") as avg_play_progress
FROM (
    SELECT tag, 
        ROUND(AVG(
            IF(TIMESTAMPDIFF(SECOND, start_time, end_time) > duration, 1,
               TIMESTAMPDIFF(SECOND, start_time, end_time) / duration)
        ) * 100, 2) as avg_play_progress
    FROM tb_user_video_log
    JOIN tb_video_info USING(video_id)
    GROUP BY tag
    HAVING avg_play_progress > 60
    ORDER BY avg_play_progress DESC
) as t_progress;

```
注意点：

1. 需要用timestampdiff()

### SQL158 每类视频近一个月的转发量/率

join using  和join on 的区别 :
join using 后面接 两张表中都存在的字段 (字段名称 一样)
join on    后面接 两张表中中需要关联的字段 (字段名称不需要一样 a.id = b.id )

我的错误答案：
```
select
    v.tag
    sum(if(if_retweet = "1",1,0) as retweet_cnt,
    round(sum(if(if_retweet == "1",1,0))/count(if_retweet),3) as retweet_rate
from tb_user_video_log u 
left join tb_video_info v on u.vedio_id = v.vedio_id
group by v.tag
order by retweet_rate desc
```

1. 这边的if_retweet 已经是1，0变凉了，所以直接 sum(if_retweet)就可以了，不需要这么麻烦
2. 在题目中漏掉了一个条件：每类视频在有用户互动的最近一个月（并不是对于各类视频计算最大值，而是整体的日期最大值）
   日期1 ： date( (select max(start_time) )
   日期2：date(a.start_time)
   datediff(日期1， 日期2)

正确答案：
```
SELECT b.tag, SUM(if_retweet) retweet_cnt, ROUND(SUM(if_retweet)/COUNT(*), 3) retweet_rate
FROM tb_user_video_log a
LEFT JOIN tb_video_info b
ON a.video_id = b.video_id
WHERE DATEDIFF(DATE((select max(start_time) FROM tb_user_video_log)), DATE(a.start_time)) <= 29
GROUP BY b.tag
ORDER BY retweet_rate desc
```


### SQL159 每个创作者每月的涨粉率及截止当前的总粉丝量
问题：计算2021年里每个创作者每月的涨粉率及截止当月的总粉丝量
注： 涨粉率=(加粉量 - 掉粉量) / 播放量。结果按创作者ID、总粉丝量升序排序。

我的错误答案：
```
select
    author,
    timestamp(release_time, month) as month,
    sum(case when if_follow == "1" then 1
        when if_follow == "2" then -1
        else 0 end)/count(*) fans_growth_rate,
    sum(case when if_follow == "1" then 1
        when if_follow == "2" then -1
        else 0 end) as total_fans
from tb_video_info v 
join tb_user_video_log u using(vedio_id)
group by author
order by author, total_fanse
```

注意点：
1. 转化为年月：date_format(start_time, '%Y-%m') month
2. 不要有python思维，就是if就是一个 = 
3. 注意total_fans的查询没有那么简单，需要用到开窗函数
    ```
    sum(sum(case when if_follow=1 then 1
        when if_follow=2 then -1
        else 0 end)) 
    over (partition by author order by date_format(start_time,'%Y-%m')) 
    ```
    两层sum是因为第一个sum是针对每一个月内进行计算，第二个sum是为了每一个author在不同月份的累加。
```
SELECT 
    author, 
    date_format(start_time,'%Y-%m') month,
    round(sum(case when if_follow=1 then 1
             when if_follow=2 then -1
             else 0 end)/count(author),3) fans_growth_rate,
     sum(sum(case when if_follow=1 then 1
             when if_follow=2 then -1
             else 0 end)) over(partition by author order by date_format(start_time,'%Y-%m')) total_fans
FROM tb_user_video_log log 
left join tb_video_info info on log.video_id=info.video_id
where year(start_time)=2021
group by author,month
order by author,total_fans  
```

### SQL160 国庆期间每类视频点赞量和转发量

问题：统计2021年国庆头3天每类视频每天的近一周总点赞量和一周内最大单天转发量，结果按视频类别降序、日期升序排序。假设数据库中数据足够多，至少每个类别下国庆头3天及之前一周的每天都有播放记录。

简化：统计每类视频，2021年10月1号到3号，这三天，每天往前7天的总点赞量，以及7天内【单天转发量】的最大值

拆解步骤：

***一、先按天进行聚合统计***

因为原数据是以天为单位的统计数据，每一天都会有多条if_like和if_retweet记录，所以先要按照tag，date进行统计，得到每天的总点赞量like_cnt，和总转发量retweet_cnt
```
SELECT
    tag,
    DATE(start_time) dt,
    SUM(if_like) like_cnt,
    SUM(if_retweet) retweet_cnt
FROM tb_video_info
LEFT JOIN tb_user_video_log USING(video_id)
WHERE DATE(start_time) BETWEEN '2021-09-25' AND '2021-10-03'
group by 1,2) t1  
```

***二、滑动窗口的设置(ROWS BETWEEN CURRENT ROW AND 6 PRECEDING)***

思路：在09.25-10.03这个区间内，按tag聚合，dt逆序，统计得到CURRENT ROW及后6行的点赞量统计sum_like_cnt_7d，和转发量sum_retweet_cnt_7d
```
SELECT
    tag,
    dt,
    SUM(like_cnt) OVER w sum_like_cnt_7d,
    MAX(retweet_cnt) OVER w sum_retweet_cnt_7d
FROM
    t1
WINDOW w AS (PARTITION BY tag ORDER BY dt DESC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING
```
注意一下这边的写法，可以单独一列，专门设置一个WINDOW w as

***三、加总得到正确答案：***
```
SELECT
  *
FROM (
  SELECT
    tag,
    dt,
    SUM(like_cnt) OVER w sum_like_cnt_7d,
    MAX(retweet_cnt) OVER w sum_retweet_cnt_7d
  FROM (
    SELECT
      tag,
      DATE(start_time) dt,
      SUM(if_like) like_cnt,
      SUM(if_retweet) retweet_cnt
    FROM tb_video_info
    LEFT JOIN tb_user_video_log USING(video_id)
    WHERE DATE(start_time) BETWEEN '2021-09-25' AND '2021-10-03'
    group by 1,2) t1   #group 1,2是第一第二列
  WINDOW w AS (PARTITION BY tag ORDER BY dt DESC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING)
) t2
GROUP BY 1, 2
HAVING dt BETWEEN '2021-10-01' AND '2021-10-03'
ORDER BY 1 DESC, 2

```
注意：

start_time = “2021-09-24 10:00:00”

date(start_time) 的查询结果是 2021-09-24


### 专题： SQL滑动窗口
只计算某些行的聚合，在两个点之间滑动计算，用以下语句指定起点和终点:
```
sum(__)   over(partition by __ order by __
               ROWS BWTWEEN <start> AND <finish> )
```

start 和 finish 关键字如下：
```
2 PRECEDING   #指定前2行
2 FOLLOWING   #指定后2行
UNBOUNDED PRECEDING  #前面所有行
YNBOUNDED FOLLOWING  #后面所有行
CURRENT ROW   #当前行
```
e.g.首行至当前行的累计
```
SUM(home_goal) OVER(ORDER BY date 
                    ROWS BETWEEN unbounded preceding AND current row) AS running_total,
AVG(home_goal) OVER(ORDER BY date  
                    ROWS BETWEEN unbounded preceding AND current row) AS running_avg
```



### SQL161 近一个月发布的视频中热度最高的top3视频
问题：找出近一个月发布的视频中热度最高的top3视频。

注：

热度=(a*视频完播率+b*点赞数+c*评论数+d*转发数)*新鲜度；

新鲜度=1/(最近无播放天数+1)；

当前配置的参数a,b,c,d分别为100、5、3、2。

最近播放日期以end_time-结束观看时间为准，假设为T，则最近一个月按[T-29, T]闭区间统计。

结果中热度保留为整数，并按 热度 降序排序。

1.先把最外层写出来


```
SELECT
  video_id,
  ROUND((100 * finished_rate
   + 5 * like_cnt
   + 3 * comment_count
   + 2 * retweet_cnt) / (unfinished_day_cnt + 1)) as hot_index
FROM 
    t1
ORDER BY 2 DESC LIMIT 3
```

2.再写t1
```
SELECT
    i.video_id,
    SUM(TIMESTAMPDIFF(second, start_time, end_time) >= duration) / COUNT(*) finished_rate,
    SUM(if_like = 1) like_cnt,
    SUM(IF(comment_id IS NOT NULL, 1, 0)) comment_count,
    SUM(if_retweet = 1) retweet_cnt,
    DATEDIFF(DATE((SELECT MAX(end_time) FROM tb_user_video_log)), MAX(DATE(end_time))) unfinished_day_cnt
FROM tb_video_info i
JOIN tb_user_video_log USING(video_id)
WHERE DATEDIFF(DATE((SELECT MAX(end_time) FROM tb_user_video_log)), DATE(release_time)) <= 29
GROUP BY 1
```

3.注意点

a. 时间窗口的筛选：最近一个月按[T-29, T]闭区间统计
```
DATEDIFF(DATE((SELECT MAX(end_time) FROM tb_user_video_log)), DATE(release_time)) <= 29
```

b. 新鲜度=1/(最近无播放天数+1)中最近无播放天数的计算

最近有播放一天，是需要被group by之后最大的那天
```
max(date(end_time))
```

最近一天:是整张表里最大的那天
```
date(select max(end_time) from tb_user_video_log)
```

通过datadiff相连接
```
DATEDIFF(DATE((SELECT MAX(end_time) FROM tb_user_video_log)), MAX(DATE(end_time))) unfinished_day_cnt
```

c. 不能直接用count(comment_id)
```
SUM(IF(comment_id IS NOT NULL, 1, 0)) comment_count
```

d. 完播率用timestampdiff
```
SUM(TIMESTAMPDIFF(second, start_time, end_time) >= duration) / COUNT(*) finished_rate,
```
这边的>=判断正确就会返回1，直接用sum去总和这个结果

### 总结
1. 时间窗口选取

滑动时间窗口
```
WINDOW w AS (PARTITION BY tag ORDER BY dt DESC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING)
```

最近无播放天数
```
DATEDIFF(DATE((SELECT MAX(end_time) FROM tb_user_video_log)), MAX(DATE(end_time))) unfinished_day_cnt
```

[T,T-29] 
```
DATEDIFF(DATE((SELECT MAX(end_time) FROM tb_user_video_log)), DATE(release_time)) <= 29
```

2. 一些数值计算

完播率
```
SUM(TIMESTAMPDIFF(second, start_time, end_time) >= duration) / COUNT(*) finished_rate
```

粉丝总数
```
sum(sum(case when if_follow=1 then 1
        when if_follow=2 then -1
        else 0 end)) over(partition by author order by date_format(start_time,'%Y-%m')) total_fans
```

评论数
```
SUM(IF(comment_id IS NOT NULL, 1, 0)) comment_count
```

平均播放率 （timestampdiff的使用）
```
IF(TIMESTAMPDIFF(SECOND, start_time, end_time) >  duration, 1,
    TIMESTAMPDIFF(SECOND, start_time, end_time) / duration)
) * 100, 2) as avg_play_progress
```




# SQL Practice 2
用户增长场景（某度信息流） 
https://www.nowcoder.com/practice/8e33da493a704d3da15432e4a0b61bb3?tpId=268&tqId=2285342&ru=/exam/oj&qru=/ta/sql-factory-interview/question-ranking&sourceUrl=%2Fexam%2Foj%3Fpage%3D1%26tab%3DSQL%25E7%25AF%2587%26topicId%3D268

### SQL162 2021年11月每天的人均浏览文章时长
问题：统计2021年11月每天的人均浏览文章时长（秒数），结果保留1位小数，并按时长由短到长排序。

正确答案：
```
select
    date(in_time) dt,
    round(sum(timestampdiff(second,in_time,out_time)) / count(distinct uid),1) avg_lensec
from tb_user_log
where date_format(in_time, "%Y-%m") = '2021-11' and artical_id != 0
group by dt
order by avg_lensec
```
注意点：
1. timestamp使用：见专题
2. count(distinct uid)



### SQL163 每篇文章同一时刻最大在看人数
问题：统计每篇文章同一时刻最大在看人数，如果同一时刻有进入也有离开时，先记录用户数增加再记录减少，结果按最大人数降序。

错误答案

错的非常离谱啊，in_time和out_time都不是一一对应的
```
select 
    artical_id,
    ((count(uid) over(partition by in_time))- 
    (count(uid) over(partition by out_time))) as max_uv
from tb_user_log
order by max_uv desc
```

题解：

计算同时在线UV：进入定义为1，离开定义为-1，并对时间进行正序排序，最后算累加实时在线UV。

***特别注意***：在累加的时候，要对uv进行排序，以用户进入的uv为优先级。比如同一秒，用户进入就闪退呢，应该优先计算他的进入数据）。


1）统计每篇文章同一时刻最大在看人数
把进来算作1，离开算作-1。用sum()over(order by time)来进行累加统计实时在线。取实时在线的最大值即为同一时刻文章再看最大值。

2）如果同一时刻有进入也有离开时,先记录用户数增加再记录减少
```
SELECT uid,artical_id,in_time,1 AS uv FROM tb_user_log
UNION ALL
SELECT uid,artical_id,out_time,-1 AS uv FROM tb_user_log
```
3）在上述联立表基础上累加uv，计算用户最大同时在线数据
```
SELECT artical_id,in_time,uv,
    SUM(uv)OVER(PARTITION BY artical_id ORDER BY in_time,uv DESC) uv_cnt
    # uv desc：先计算用户进入的uv,因为会存在用户同一秒进出的情况，这时肯定是优先统计用户进场的情况的。
FROM (SELECT uid,artical_id,in_time,1 AS uv FROM tb_user_log
    UNION ALL
    SELECT uid,artical_id,out_time,-1 AS uv FROM tb_user_log) as uv_table
WHERE artical_id<>0;   #题目有说artical_id<>0
```
4）结果按最大人数降序

***正确答案***
```
WITH t1 AS 
(SELECT artical_id,in_time,
        SUM(uv)OVER(PARTITION BY artical_id ORDER BY in_time,uv DESC) uv_cnt
FROM (SELECT uid,artical_id,in_time,1 AS uv FROM tb_user_log
    UNION ALL
    SELECT uid,artical_id,out_time,-1 AS uv FROM tb_user_log) as uv_table
WHERE artical_id<>0
)
SELECT artical_id,MAX(uv_cnt) max_uv FROM t1
GROUP BY artical_id
ORDER BY max_uv DESC
```

### SQL164 2021年11月每天新用户的次日留存率

问题：统计2021年11月每天新用户的次日留存率（保留2位小数）

注：
次日留存率为当天新增的用户数中第二天又活跃了的用户数占比。
如果in_time-进入时间和out_time-离开时间跨天了，在两天里都记为该用户活跃过，结果按日期升序。

流程：

1）先查询出每个用户第一次登陆时间（最小登陆时间）--每天新用户表
```
select uid
      ,min(date(in_time)) dt
      from tb_user_log 
      group by uid
```
2）因为涉及到跨天活跃，所以要进行并集操作，将登录时间和登出时间取并集，这里union会去重--用户活跃表
```
select uid , date(in_time) dt from tb_user_log
union
select uid , date(out_time) from tb_user_log
```

3）将每天新用户表和用户活跃表左连接，只有是同一用户并且该用户第2天依旧登陆才会保留整个记录，否则右表记录为空
```
(每天新用户表) left join (用户活跃表) on
t1.uid = t2.uid and
t1.dt = date_sub(t2.dt, INTERVAL 1 day)
```
这里是一个漏斗的过程

4）得到每天新用户第二天是否登陆表后,开始计算每天的次日留存率：根据日期分组计算，次日活跃用户个数/当天新用户个数

***正确答案***
```
select 
t1.dt,
round(count(t2.uid)/count(t1.uid),2) uv_rate
from (select uid
      ,min(date(in_time)) dt
      from tb_user_log 
      group by uid) as t1  -- 每天新用户表
left join (select uid , date(in_time) dt
           from tb_user_log
           union
           select uid , date(out_time)
           from tb_user_log) as t2 -- 用户活跃表
on t1.uid=t2.uid
and t1.dt=date_sub(t2.dt,INTERVAL 1 day)
where date_format(t1.dt,'%Y-%m') = '2021-11'
group by t1.dt
order by t1.dt
```


### SQL165 统计活跃间隔对用户分级结果
问题：统计活跃间隔对用户分级后，各活跃等级用户占比，结果保留两位小数，且按占比降序排序。

注：
用户等级标准简化为：忠实用户(近7天活跃过且非新晋用户)、新晋用户(近7天新增)、沉睡用户(近7天未活跃但更早前活跃过)、流失用户(近30天未活跃但更早前活跃过)。
假设今天就是数据中所有日期的最大值。
近7天表示包含当天T的近7天，即闭区间[T-6, T]。

1）计算每个用户最早最晚活跃日期（作为子表t_uid_first_last）：
```
按用户ID分组：GROUP BY uid
统计最早活跃：MIN(DATE(in_time)) as first_dt
统计最晚活跃：MAX(DATE(out_time)) as last_dt
```
2) 计算当前日期和总用户数（作为子表t_overall_info）：
```
获取当前日期：MAX(DATE(out_time)) as cur_dt
统计总用户数：COUNT(DISTINCT uid) as user_cnt
```
3) 左连接两表，即将全表统计信息追加到每一行上：
```
t_uid_first_last LEFT JOIN t_overall_info ON 1
```
4) 计算最早最晚活跃离当前天数差（作为子表t_user_info）：
```
最早活跃距今天数：TIMESTAMPDIFF(DAY,first_dt,cur_dt) as first_dt_diff
最晚（最近）活跃距今天数：TIMESTAMPDIFF(DAY,last_dt,cur_dt) as last_dt_diff
``` 
5) 计算每个用户的活跃等级：
```
CASE
    WHEN last_dt_diff >= 30 THEN "流失用户"
    WHEN last_dt_diff >= 7 THEN "沉睡用户"
    WHEN first_dt_diff < 7 THEN "新晋用户"
    ELSE "忠实用户"
END as user_grade
```
6) 统计每个等级的占比：
```
按用户等级分组：GROUP BY user_grade

计算占比，总人数从子表得到，非聚合列避免语法错误加了MAX：COUNT(uid) / MAX(user_cnt) as ratio

保留2位小数：ROUND(x, 2)
```

***正确答案***
```
SELECT user_grade, ROUND(COUNT(uid) / MAX(user_cnt), 2) as ratio
FROM (
    SELECT uid, user_cnt,
        CASE
            WHEN last_dt_diff >= 30 THEN "流失用户"
            WHEN last_dt_diff >= 7 THEN "沉睡用户"
            WHEN first_dt_diff < 7 THEN "新晋用户"
            ELSE "忠实用户"
        END as user_grade
    FROM (
        SELECT uid, user_cnt,
            TIMESTAMPDIFF(DAY,first_dt,cur_dt) as first_dt_diff, 
            TIMESTAMPDIFF(DAY,last_dt,cur_dt) as last_dt_diff
        FROM (
            SELECT uid, MIN(DATE(in_time)) as first_dt,
                MAX(DATE(out_time)) as last_dt
            FROM tb_user_log
            GROUP BY uid
        ) as t_uid_first_last
        LEFT JOIN (
            SELECT MAX(DATE(out_time)) as cur_dt,
                COUNT(DISTINCT uid) as user_cnt
            FROM tb_user_log
        ) as t_overall_info ON 1
    ) as t_user_info
) as t_user_grade
GROUP BY user_grade
ORDER BY ratio DESC
```


### SQL166 每天的日活数及新用户占比
一、题目理解

统计每天的日活数及新用户占比

新用户占比=当天的新用户数÷当天活跃用户数（日活数）。

如果in_time-进入时间和out_time-离开时间跨天了，在两天里都记为该用户活跃过。

新用户占比保留2位小数，结果按日期升序排序。

**1)先建立一张拥有基本信息的用户活跃基础表**

这张表要包含用户id，活跃日，成为新用户的日期。因为用户可能1天活跃N次，所以要做去重处理。

活跃日直接并联in_time和out_time

成为新用户日期，用窗口函数来取：MIN(DATE(in_time))OVER(PARTITION BY uid)  AS new_dt

```
SELECT DISTINCT uid,DATE(in_time) dt,MIN(DATE(in_time))OVER(PARTITION BY uid) new_dt FROM tb_user_log
UNION
SELECT DISTINCT uid,DATE(out_time) dt,MIN(DATE(in_time))OVER(PARTITION BY uid) new_dt FROM tb_user_log
```

**2)定义新用户**
如果dt=new_dt那这天就是用户首次登录成为新用户的日子
```
WITH t1 AS(
SELECT DISTINCT uid,DATE(in_time) dt,MIN(DATE(in_time))OVER(PARTITION BY uid) new_dt FROM tb_user_log
UNION
SELECT DISTINCT uid,DATE(out_time) dt,MIN(DATE(in_time))OVER(PARTITION BY uid) new_dt FROM tb_user_log
)
SELECT uid,dt,IF(dt=new_dt,1,0) '是否为新用户（是为1，不是为0）'
FROM t1;
```

**3）计算新用户占比，结果按照日期升序，输出结果。**
日活：COUNT(1)
新用户数：SUM（是否为新用户）
新用户占比：ROUND(SUM(新用户)/COUNT(1),2)
```
WITH t1 AS(
SELECT DISTINCT uid,DATE(in_time) dt,MIN(DATE(in_time))OVER(PARTITION BY uid) new_dt FROM tb_user_log
UNION
SELECT DISTINCT uid,DATE(out_time) dt,MIN(DATE(in_time))OVER(PARTITION BY uid) new_dt FROM tb_user_log
)
SELECT dt,COUNT(1) dau,ROUND(SUM(IF(dt=new_dt,1,0))/COUNT(1),2) uv_new_ratio
FROM t1 GROUP BY dt ORDER BY dt ASC
```

### SQL167 连续签到领金币
*场景逻辑说明：*
artical_id-文章ID代表用户浏览的文章的ID，特殊情况artical_id-文章ID为0表示用户在非文章内容页（比如App内的列表页、活动页等）。注意：只有artical_id为0时sign_in值才有效。
从2021年7月7日0点开始，用户每天签到可以领1金币，并可以开始累积签到天数，连续签到的第3、7天分别可额外领2、6金币。
每连续签到7天后重新累积签到天数（即重置签到天数：连续第8天签到时记为新的一轮签到的第一天，领1金币）

**问题：计算每个用户2021年7月以来每月获得的金币数（该活动到10月底结束，11月1日开始的签到不再获得金币）。结果按月份、ID升序排序。**

注：如果签到记录的in_time-进入时间和out_time-离开时间跨天了，也只记作in_time对应的日期签到了。

***题解***

比较好理解的思考方式是**根据需要的结果，一步一步反推自己需要什么的格式的数据**

```
WITH t1 AS( -- t1表筛选出活动期间内的数据，并且为了防止一天有多次签到活动，distinct 去重
	SELECT
		DISTINCT uid,
		DATE(in_time) dt,
		DENSE_RANK() over(PARTITION BY uid ORDER BY DATE(in_time)) rn -- 编号
	FROM
		tb_user_log
	WHERE
		DATE(in_time) BETWEEN '2021-07-07' AND '2021-10-31' AND artical_id = 0 AND sign_in = 1
)
```

1）要求活动期间的签到获得的金币总数，那我最希望的是能够获得每一天用户签到时获得的金币数，然后只需要按照ID和month分组，sum一下就可以

2）再反推，想要获得每一天用户签到时获得的金币数，那么我必须知道，用户当天签到是连续签到的第几天，得到天数以后很简单了，用case when 将天数 % 7 ，看余数。 余数是3 ，当天获得3枚。余数是 0 ，当天获得7枚 。其他为1枚。
```
SELECT
	*,
	DATE_SUB(dt,INTERVAL rn day) dt_tmp, 
	case DENSE_RANK() over(PARTITION BY DATE_SUB(dt,INTERVAL rn day),uid ORDER BY dt )%7 -- 再次编号
		WHEN 3 THEN 3
		WHEN 0 THEN 7
		ELSE 1
	END as day_coin -- 用户当天签到时应该获得的金币数
	FROM
	t1
```

3）推到这里那其实思路已经清晰了，求连续签到的天数，那无非就是**连续问题**了

连续问题核心就是**利用排序编号与签到日期的差值是相等的**。因为如果是连续的话，编号也是自增1，日期也是自增1。

***正确代码***
```
WITH t1 AS( -- t1表筛选出活动期间内的数据，并且为了防止一天有多次签到活动，distinct 去重
	SELECT
		DISTINCT uid,
		DATE(in_time) dt,
		DENSE_RANK() over(PARTITION BY uid ORDER BY DATE(in_time)) rn -- 编号
	FROM
		tb_user_log
	WHERE
		DATE(in_time) BETWEEN '2021-07-07' AND '2021-10-31' AND artical_id = 0 AND sign_in = 1
),
t2 AS (
	SELECT
	*,
	DATE_SUB(dt,INTERVAL rn day) dt_tmp, 
	case DENSE_RANK() over(PARTITION BY DATE_SUB(dt,INTERVAL rn day),uid ORDER BY dt )%7 -- 再次编号
		WHEN 3 THEN 3
		WHEN 0 THEN 7
		ELSE 1
	END as day_coin -- 用户当天签到时应该获得的金币数
	FROM
	t1
)
	SELECT
		uid,DATE_FORMAT(dt,'%Y%m') `month`, sum(day_coin) coin  -- 总金币数
	FROM
		t2
	GROUP BY
		uid,DATE_FORMAT(dt,'%Y%m')
	ORDER BY
		DATE_FORMAT(dt,'%Y%m'),uid;
```
## 电商场景（某东商城）
### SQL168 计算商城中2021年每月的GMV

**场景逻辑说明：**
用户将购物车中多件商品一起下单时，订单总表会生成一个订单（但此时未付款，status-订单状态为0，表示待付款）；
当用户支付完成时，在订单总表修改对应订单记录的status-订单状态为1，表示已付款；
若用户退货退款，在订单总表生成一条交易总金额为负值的记录（表示退款金额，订单号为退款单号，status-订单状态为2表示已退款）。

**问题：** 请计算商城中2021年每月的GMV，输出GMV大于10w的每月GMV，值保留到整数。

**注：** GMV为已付款订单和未付款订单两者之和。结果按GMV升序排序。

**问题分解：**
* 筛选满足条件的记录：
  * 退款的金额不算（付款的记录还在，已算过一次）：where status != 2
  * 2021年的记录：and YEAR(event_time) = 2021
* 按月份分组：group by DATE_FORMAT(event_time, "%Y-%m")
* 计算GMV：(sum(total_amount) as GMV
* 保留整数：ROUND(x, 0)
* (对计算结果进行筛选用having)筛选GMV大于10w的分组：having GMV > 100000


**正确答案**
```
select DATE_FORMAT(event_time, "%Y-%m") as `month`,
    ROUND(sum(total_amount), 0) as GMV
from tb_order_overall
where status != 2 and YEAR(event_time) = 2021
group by `month`
having GMV > 100000
order by GMV;
```

### SQL169 统计2021年10月每个退货率不大于0.5的商品各项指标

**问题：** 请统计2021年10月每个有展示记录的退货率不大于0.5的商品各项指标，

**注：**
商品点展比=点击数÷展示数；
加购率=加购数÷点击数；
成单率=付款数÷加购数；退货率=退款数÷付款数，
当分母为0时整体结果记为0，结果中各项指标保留3位小数，并按商品ID升序排序。

**提示**
比较简单的题，**子查询计数**，然后进行统计清晰明了，要注意**筛查分母为0**的情况

**错误答案**
```
#没有考虑分母为零的情况
select product_id,
round(sum(if_click) / count(*),3) as ctr,
round(sum(if_cart) / sum(if_click),3) as cart_rate,
round(sum(if_payment) / sum(if_cart),3) as payment_rate,
round(sum(if_refund) / sum(if_cart),3) as refund_rate
from tb_user_event
where time_format(event_time,"%Y-%m") = "2021-10"
group by product_id
having refund_rate <= 0.5
order by product_id
```

**正确答案**
```
#子查询计数
SELECT product_id,round(click/showtimes,3) as ctr,
       if(click=0,0,round(cart/click,3)),
       if(cart=0,0,round(payment/cart,3)),
       if(payment=0,0,round(refund/payment,3)) as refund_rate
FROM
(select product_id,
       count(*) as showtimes,
       sum(if_click) as click,
       sum(if_cart) as cart,sum(if_payment) as payment,
       sum(if_refund) as refund 
FROM tb_user_event
where date_format(EVENT_time,"%Y-%m")="2021-10"
group by product_id) BASE
group by product_id
having refund_rate<=0.5
order by product_id
```

### SQL170 某店铺的各商品毛利率及店铺整体毛利率


**问题：** 请计算2021年10月以来店铺901中商品毛利率大于24.9%的商品信息及店铺整体毛利率。

**注：** 
商品毛利率=(1-进价/平均单件售价)*100%
店铺毛利率=(1-总进价成本/总销售收入)*100%

***结果先输出店铺毛利率***，再按商品ID升序输出各商品毛利率，均保留1位小数。

**问题分解：**
* 统计每个被售出的商品的售价进价（生成子表t_product_in_each_order）
  * 订单明细表内连接商品信息表：
    ```
    tb_order_detail JOIN tb_product_info USING(product_id)
    ```
  * 继续内连接订单总表：
    ```
    JOIN tb_order_overall USING(order_id)
    ```
  * 筛选店铺和时间窗：
    ```
    WHERE shop_id = 901 and DATE (event_time) >= "2021-10-01"
    ```
* 按商品分组：GROUP BY product_id
* 加上汇总结果：WITH ROLLUP
* 商品ID列重整：
  ```
  IFNULL(product_id, '店铺汇总') as product_id
  ```
* 计算商品利润率：
   ```
  100 * (1 - SUM(in_price*cnt) / SUM(price*cnt)) as profit_rate
  ```
* 保留1位小数：ROUND(x, 1)
* 筛选满足条件的分组（商品）：
  ```
  HAVING profit_rate > 24.9 OR product_id IS NULL
  ```
* 格式化毛利率格式：
  ```
  CONCAT(profit_rate, "%") as profit_rate
  ```

**正确答案**
```
SELECT product_id, CONCAT(profit_rate, "%") as profit_rate
FROM (
    SELECT IFNULL(product_id, '店铺汇总') as product_id,
        ROUND(100 * (1 - SUM(in_price*cnt) / SUM(price*cnt)), 1) as profit_rate
    FROM (
        SELECT product_id, price, cnt, in_price
        FROM tb_order_detail
        JOIN tb_product_info USING(product_id)
        JOIN tb_order_overall USING(order_id)
        WHERE shop_id = 901 and DATE(event_time) >= "2021-10-01"
    ) as t_product_in_each_order
    GROUP BY product_id
    WITH ROLLUP
    HAVING profit_rate > 24.9 OR product_id IS NULL
    ORDER BY product_id
) as t1;
```

### SQL171 零食类商品中复购率top3高的商品
**问题：** 请统计零食类商品中复购率top3高的商品。

**注：** 复购率指用户在一段时间内对某商品的重复购买比例，复购率越大，则反映出消费者对品牌的忠诚度就越高，也叫回头率
此处我们定义：某商品复购率 = 近90天内购买它至少两次的人数 ÷ 购买它的总人数
近90天指包含最大日期（记为当天）在内的近90天。结果中复购率保留3位小数，并按复购率倒序、商品ID升序排序

* 计算每个用户对每个商品是否复购（生成子表t_uid_product_info）：
  * 内连接多表：
    ```
    tb_order_detail JOIN tb_order_overall USING(order_id) JOIN tb_product_info USING(product_id)
    ```
  * 筛选零食类商品：WHERE tag="零食"
  * 筛选近90天的记录：
    * 计算最小允许日期：
        ```
        DATE_SUB(MAX(event_time), INTERVAL 89 DAY)
        ```
    * 筛选：event_time >= (SELECT ... FROM tb_order_overall)
  * 按用户和商品分组：GROUP BY uid, product_id
  * 计算是否复购：
    ```
    IF(COUNT(event_time)>1, 1, 0) as repurchase
    ```
* 按商品分组：GROUP BY product_id
* 计算复购率：SUM(repurchase) / COUNT(repurchase) as repurchase_rate
* 保留3位小数：ROUND(x, 3)

**正确答案**
```
SELECT product_id,
    ROUND(SUM(repurchase) / COUNT(repurchase), 3) as repurchase_rate
FROM (
    SELECT uid, product_id, IF(COUNT(event_time)>1, 1, 0) as repurchase
    FROM tb_order_detail
    JOIN tb_order_overall USING(order_id)
    JOIN tb_product_info USING(product_id)
    WHERE tag="零食" AND event_time >= (
        SELECT DATE_SUB(MAX(event_time), INTERVAL 89 DAY)
        FROM tb_order_overall
    )
    GROUP BY uid, product_id
) as t_uid_product_info
GROUP BY product_id
ORDER BY repurchase_rate DESC, product_id
LIMIT 3;

```

### SQL172 10月的新户客单价和获客成本
**问题：** 请计算2021年10月商城里所有新用户的首单平均交易金额（客单价）和平均获客成本（保留一位小数）。
**注：** 订单的优惠金额 = 订单明细里的{该订单各商品单价×数量之和} - 订单总表里的{订单总金额} 。

**错误答案**
```
select
round(avg(price),1) as avg_amount,
round(avg(cost),1) as avg_cost
from tb_order_overall tb
left join
        (
        select 
            order_id,
            uid,
            (normal_price - total_amount) as cost
        from tb_order_overall)t1
        left join
        (select
             order_id,
             sum(price) over(partition by(order_id)) as normal_price
         from tb_order_detail)t2
        on t1.order_id = t2.order_id
        )t3 
    on tb.uid = t3.uid
where tb.uid in 
(select uid from tb_order_overall 
 where min(date_format(event_time,"%Y-%m")) = "2021-10")
```

**正确答案**
```
select round(sum(total_amount)/count(order_id),1) avg_amount,
       round(avg(cost),1) avg_cost
from (select a.order_id, 
             total_amount,
             (sum(price*cnt) - total_amount) as cost
      from tb_order_detail a
      left join tb_order_overall b
      on a.order_id = b.order_id
      where date_format(event_time,'%Y-%m') = '2021-10' 
            and (uid,event_time) in (select uid ,min(event_time)     -- 用户和其第一次购买的时间
                                     from tb_order_overall
                                     GROUP BY uid )
      GROUP BY a.order_id,  total_amount) t
```

### SQL173 店铺901国庆期间的7日动销率和滞销率
**问题：** 请计算店铺901在2021年国庆头3天的7日动销率和滞销率，结果保留3位小数，按日期升序排序。

**注：**
动销率定义为店铺中一段时间内有销量的商品占当前已上架总商品数的比例（有销量的商品/已上架总商品数)。
滞销率定义为店铺中一段时间内没有销量的商品占当前已上架总商品数的比例。（没有销量的商品/已上架总商品数)。
只要当天任一店铺有任何商品的销量就输出该天的结果，即使店铺901当天的动销率为0。

```

```


### SQL29 计算用户的平均次日留存率
细节问题：
表头重命名：as
去重：需要按照devece_id,date去重，因为一个人一天可能来多次
子查询必须全部有重命名

```
select avg(if(datediff(date2, date1)=1, 1, 0)) as avg_ret
from (
    select
        distinct device_id,
        date as date1,
        lead(date) over (partition by device_id order by date) as date2
    from (
        select distinct device_id, date
        from question_practice_detail
    ) as uniq_id_date
) as id_last_next_date
```

### SQL30 统计每种性别的人数
这里的难点是 ***字符串截取***
性别给在了profile里面，我们需要学会取出 gender
profile: 180cm,75kg,27,male
```
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

### SQL33  找出每个学校GPA最低的同学
先用min筛选出最少的，再用where in去筛选出来
```
select
device_id,
university,
gpa
from user_profile
where (device_id, gpa) in
(select device_id, min(gpa) over(partition by university) from user_profile)
order by university
```


### VQ26 查询用户刷题日期和下一次刷题日期
```
select user_id,date,lag(date) over(partition by user_id order by date desc)nextdate from questions_pass_record 
order by user_id,date,nextdate desc
```