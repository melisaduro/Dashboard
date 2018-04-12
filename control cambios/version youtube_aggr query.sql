select d.Entidad,d.[Youtube Version modificada],d.Meas_date, d.[Database]
from AGGRData4G.dbo.lcc_aggr_sp_MDD_Data_Youtube_HD y, 
(select 'v'+MAX(s.[Youtube Version]) as [Youtube Version modificada],s.Entidad, s.Meas_date, s.[Database] 
from Dashboard.dbo.youtube_version_4G s,AGGRData4G.dbo.lcc_aggr_sp_MDD_Data_Youtube_HD t 
where s.Entidad=t.Entidad and s.Meas_date=t.meas_Date and s.[Database]=t.[Database]
and s.[Youtube Version] not in ('No encontrada')
group by s.Entidad,s.Meas_date, s.[Database] ) d
where y.Entidad=d.Entidad and y.Meas_date=d.meas_Date and y.[Database]=d.[Database]
group by d.Entidad,d.[Youtube Version modificada],d.Meas_date, d.[Database]


select d.Entidad,d.[Youtube Version modificada],d.Meas_date, d.[Database]
from-- AGGRData4G.dbo.lcc_aggr_sp_MDD_Data_Youtube_HD y, 
(select 'v'+MAX(s.[Youtube Version]) as [Youtube Version modificada],s.Entidad, s.Date_Reporting, s.[Database] 
from Dashboard.dbo.youtube_version_4G s
where s.[Youtube Version] not in ('No encontrada')
group by s.Entidad,s.Meas_date, s.[Database] ) d
left join AGGRData4G.dbo.lcc_aggr_sp_MDD_Data_Youtube_HD y
on y.Entidad=d.Entidad and y.date_reporting=d.date_reporting and y.[Database]=d.[Database]--and sreport='MUN'
--where y.entidad is null
group by d.Entidad,d.[Youtube Version modificada],d.Meas_date, d.[Database]


select * from [AGRIDS].[dbo].lcc_dashboard_info_ORDER_TABLES


select d.Entidad,d.Meas_date, d.[Database],d.date_reporting
from AGGRData4G.dbo.lcc_aggr_sp_MDD_Data_Youtube_HD d
where d.entidad like '%rincondelavictoria%'
group by d.Entidad,d.Meas_date, d.[Database], d.date_reporting
