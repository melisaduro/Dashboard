USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_TABLES_Central_backup]    Script Date: 13/11/2017 10:13:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_TABLES_Central_backup] 
	@database as varchar(256)
	,@nameSheet as varchar(256)
	,@stats as bit
	,@LA as bit
	,@methodology as varchar(50)
as

-------------------------------------------------------------------------------
--Inicialización de variables

--declare @database as varchar(256) = '[AGGRData4G]'
--declare @nameSheet as varchar(256)	= '4G_RAILWAY'
--declare @stats  bit=1
--declare @la bit=0

declare @sheetTech as varchar (256)
declare @table varchar(256)
declare @step float
declare @N_ranges int
declare @tech as varchar(256)
DECLARE @SQLString nvarchar(4000)
declare @LAfilter as varchar(4000)
--declare @EntitiesNOLAfilter varchar(2000)

if @nameSheet like '4G_ONLY_ROAD' set @sheetTech='_4G_ROAD'
	else if @nameSheet like '4G_ROAD' set @sheetTech='_ROAD'
		else if @nameSheet like '4G_ROAD_REGION' set @sheetTech='_ROAD_REGION'
			else if	@nameSheet like '4G_ONLY_RAILWAY' set @sheetTech='_4G_RAILWAY'
					else if @nameSheet like '4G_RAILWAY' set @sheetTech='_RAILWAY'
						else if	@nameSheet like '4G_ONLY' set @sheetTech='_4G'
							--else if @nameSheet like '4G_CA' and not @nameSheet like '4G_CAONLY' set @sheetTech='_CA'
								else if @nameSheet like '4G_CAONLY' set @sheetTech='_CA_ONLY'
									else if @nameSheet like '4G' set @sheetTech=''
										else if @nameSheet like '2G3G' set @sheetTech=''

if @database not like '%AGGRData3G%'
	set @tech='_LTE'
else 
	set @tech=''
	
-- Variable para eliminar las entidades en las que no se ha medido LA y queremos destarcar
--if @nameSheet like '2G3G'
--	set @EntitiesNOLAfilter= ' and a.entidad not like ''coruna'''
--else
--	set @EntitiesNOLAfilter=' and (a.entidad not like ''alicante'' and a.entidad not like ''sevilla'' and a.entidad not like ''barcelona'')'

if @la = 1 --set @LAfilter ='a.entorno not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 

set @lafilter='((convert(int,SUBSTRING(a.meas_date,1,2))<16 and a.entorno not like ''%LA%'' and a.entorno in (''8G'',''32G''))
or (convert(int,SUBSTRING(a.meas_date,1,2))=16 and convert(int,SUBSTRING(a.meas_date,4,2))<=7 and  a.entorno not like ''%LA%'' and a.entorno in (''8G'',''32G''))
or (convert(int,SUBSTRING(a.meas_date,1,2))>16 and a.entorno like ''%%'' or a.entorno is null)
or (convert(int,SUBSTRING(a.meas_date,1,2))=16 and convert(int,SUBSTRING(a.meas_date,4,2))>7 and a.entorno like ''%%'' or a.entorno is null))'

else set @LAfilter= '(a.entorno like ''%%'' or a.entorno is null)' --+ @EntitiesNOLAfilter

set @database= replace(replace(@database,'[',''),']','')

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Data_DL_Thput_CE
set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+ @tech+ @sheetTech

if @database not like '%AGGRData3G%'
begin
	set @step=5
	set @N_ranges=31
end
else
begin
	set @step=1
	set @N_ranges=33
end

-- Cálculo de estadísticos
if @stats =1 
	exec [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES] @sheetTech,@table,@nameSheet,@LAfilter,@database

-- Cálculo del resto de parámetros
SET @SQLString =N'
			exec dashboard.dbo.sp_lcc_dropifexists ''lcc_DL_Th_CE_'+@nameSheet+'_temp1''
			select  a.entidad
					,a.mnc
					,a.Meas_date
					,sum(a.[Navegaciones]) as DL_CE_ATTEMPTS
					,sum(a.[Fallos de Acceso]) as DL_CE_ERRORS_ACCESSIBILITY
					,sum(a.[Fallos de descarga]) as DL_CE_ERRORS_RETAINABILITY
					,case when sum(a.[Count_Throughput])>0 then sum(a.[Throughput]*a.[Count_Throughput])/sum(a.[Count_Throughput]) 
							else 0 end as DL_CE_D1
					,case when sum(a.[Count_Throughput])>0 then 1.0*sum(a.[Count_Throughput_3M])/(sum(a.[Count_Throughput]))
							else 0 end as DL_CE_D2
					,sum(a.[Count_Throughput_3M]) as DL_CE_CONNECTIONS_TH_3MBPS
					,sum(a.[Count_Throughput_1M]) as DL_CE_CONNECTIONS_TH_1MBPS
					,max(a.[Throughput Max]) as DL_CE_PEAK
					,case when sum(a.[Navegaciones]) >0 
						then sum(a.[SessionTime]*a.[Navegaciones])/sum(a.[Navegaciones])
								else 0 end as DL_CE_SESSION_TIME
			into [DASHBOARD].[dbo].lcc_DL_Th_CE_'+@nameSheet+'_temp1
			from [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE' + @sheetTech +'] a
			where '+ @LAfilter +'
			group by a.mnc,a.entidad,a.Meas_date';
EXECUTE sp_executesql @SQLString

SET @SQLString =N'
			exec dashboard.dbo.sp_lcc_dropifexists ''lcc_DL_Th_CE_'+@nameSheet+'_temp''
			select  a.entidad as entidad_dl_CE
					,a.mnc as mnc_dl_CE
					,a.Meas_date as Meas_date_dl_CE
					,a.DL_CE_ATTEMPTS
					,a.DL_CE_ERRORS_ACCESSIBILITY
					,a.DL_CE_ERRORS_RETAINABILITY
					,a.DL_CE_D1
					,b.DESV_TH as DL_CE_STD_TH
					,a.DL_CE_D2
					,a.DL_CE_CONNECTIONS_TH_3MBPS
					,a.DL_CE_CONNECTIONS_TH_1MBPS
					,a.DL_CE_PEAK
					,a.DL_CE_SESSION_TIME
					,b.P10 as DL_CE_10TH
					,'''' as DL_CE_10TH_AGGR_ENTITIES
					,'''' as DL_CE_10TH_AGGR_SCOPE
					,b.P90 as DL_CE_90TH
					,'''' as DL_CE_90TH_AGGR_ENTITIES
					,'''' as DL_CE_90TH_AGGR_SCOPE
			into [DASHBOARD].[dbo].lcc_DL_Th_CE_'+@nameSheet+'_temp
			from [DASHBOARD].[dbo].lcc_DL_Th_CE_'+@nameSheet+'_temp1 a
				left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'] b
				on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date 
			exec dashboard.dbo.sp_lcc_dropifexists ''lcc_DL_Th_CE_'+@nameSheet+'_temp1'''
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Data_UL_Thput_CE
set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+ @tech+ @sheetTech

if @database not like '%AGGRData3G%'
begin
	set @step=5
	set @N_ranges=11
end
else
begin
	set @step=0.5
	set @N_ranges=11
end
	
-- Cálculo de estadísticos
if @stats =1 
	exec [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES] @sheetTech,@table,@nameSheet,@LAfilter,@database

-- Cálculo del resto de parámetros
SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_UL_Th_CE_'+@nameSheet+'_temp1''
				SELECT  a.entidad 
						,a.mnc
						,a.Meas_date
						,sum(a.[Subidas]) as UL_CE_ATTEMPTS
						,sum(a.[Fallos de Acceso]) as UL_CE_ERRORS_ACCESSIBILITY
						,sum(a.[Fallos de descarga]) as UL_CE_ERRORS_RETAINABILITY
						,case when sum(a.[Count_Throughput])>0 then sum(a.[Throughput]*a.[Count_Throughput])/sum(a.[Count_Throughput])
							else 0 end as UL_CE_D3
						,max(a.[Throughput Max]) as UL_CE_PEAK
						,case when sum(a.[Subidas]) >0 
						then sum(a.[SessionTime]*a.[Subidas])/sum(a.[Subidas])
								else 0 end as UL_CE_SESSION_TIME
				into [DASHBOARD].[dbo].lcc_UL_Th_CE_'+@nameSheet+'_temp1
				from [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE' + @sheetTech +'] a
				where '+ @LAfilter +' 
				group by a.mnc,a.entidad,a.Meas_date';
EXECUTE sp_executesql @SQLString

SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_UL_Th_CE_'+@nameSheet+'_temp''
				SELECT  a.entidad as entidad_ul_CE
						,a.mnc as mnc_ul_CE
						,a.Meas_date as Meas_date_ul_CE
						,a.UL_CE_ATTEMPTS
						,a.UL_CE_ERRORS_ACCESSIBILITY
						,a.UL_CE_ERRORS_RETAINABILITY
						,a.UL_CE_D3
						,b.DESV_TH as UL_CE_STD_TH
						,a.UL_CE_PEAK
						,a.UL_CE_SESSION_TIME
						,b.P10 as UL_CE_10TH
						, '''' as UL_CE_10TH_AGGR_ENTITIES
						,'''' as UL_CE_10TH_AGGR_SCOPE
						,b.P90 as UL_CE_90TH
						, '''' as UL_CE_90TH_AGGR_ENTITIES
						,'''' as UL_CE_90TH_AGGR_SCOPE
				into [DASHBOARD].[dbo].lcc_UL_Th_CE_'+@nameSheet+'_temp  
				from [DASHBOARD].[dbo].lcc_UL_Th_CE_'+@nameSheet+'_temp1  a
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_UL_Th_CE_'+@nameSheet+'_temp1''';
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Data_DL_Thput_NC
set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+ @tech+ @sheetTech

if @database not like '%AGGRData3G%'
begin
	set @step=5
	set @N_ranges=31
end
else
begin
	set @step=1
	set @N_ranges=33
end

-- Cálculo de estadísticos
if @stats =1 
	exec [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES] @sheetTech,@table,@nameSheet,@LAfilter,@database

-- Cálculo del resto de parámetros
SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_DL_Th_NC_'+@nameSheet+'_temp1''
				SELECT  a.entidad
						,a.mnc
						,a.Meas_date
						,sum(a.[Navegaciones]) as DL_NC_ATTEMPTS
						,sum(a.[Fallos de Acceso]) as DL_NC_ERRORS_ACCESSIBILITY
						,sum(a.[Fallos de descarga]) as DL_NC_ERRORS_RETAINABILITY
						,sum(a.[Count_Throughput_128k]) as DL_NC_CONNECTIONS_TH_128KBPS
						,case when sum(a.[Count_Throughput])>0 then sum(a.[Throughput]*a.[Count_Throughput])/sum(a.[Count_Throughput])
							else 0 end as DL_NC_MEAN
						,max(a.[Throughput Max]) as DL_NC_PEAK
						,case when sum(a.[Navegaciones]) >0 
						then sum(a.[SessionTime]*a.[Navegaciones])/sum(a.[Navegaciones])
								else 0 end as DL_NC_SESSION_TIME
				into [DASHBOARD].[dbo].lcc_DL_Th_NC_'+@nameSheet+'_temp1
				FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC' + @sheetTech +'] a
				where '+ @LAfilter +' 
				group by a.mnc,a.entidad,a.Meas_date'
EXECUTE sp_executesql @SQLString

SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_DL_Th_NC_'+@nameSheet+'_temp''
				SELECT  a.entidad as entidad_dl_NC
						,a.mnc as mnc_dl_NC
						,a.Meas_date as Meas_date_dl_NC
						,a.DL_NC_ATTEMPTS
						,a.DL_NC_ERRORS_ACCESSIBILITY
						,a.DL_NC_ERRORS_RETAINABILITY
						,a.DL_NC_CONNECTIONS_TH_128KBPS
						,a.DL_NC_MEAN
						,b.DESV_TH as DL_NC_STD_TH
						,a.DL_NC_PEAK
						,a.DL_NC_SESSION_TIME
						,b.P10 as DL_NC_10TH
						,'''' as DL_NC_10TH_AGGR_ENTITIES
						,'''' as DL_NC_10TH_AGGR_SCOPE
						,b.P90 as DL_NC_90TH
						,'''' as DL_NC_90TH_AGGR_ENTITIES
						,'''' as DL_NC_90TH_AGGR_SCOPE
				into [DASHBOARD].[dbo].lcc_DL_Th_NC_'+@nameSheet+'_temp
				FROM [DASHBOARD].[dbo].lcc_DL_Th_NC_'+@nameSheet+'_temp1 a
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_DL_Th_NC_'+@nameSheet+'_temp1'''
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Data_UL_Thput_NC
set @table ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC' + @tech+ @sheetTech
if @database not like '%AGGRData3G%'
begin
	set @step=5
	set @N_ranges=11
end
else
begin 
	set @step=0.5
	set @N_ranges=11
end

-- Cálculo de estadísticos
if @stats =1 
	exec [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES] @sheetTech,@table,@nameSheet,@LAfilter,@database

-- Cálculo del resto de parámetros
SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_UL_Th_NC_'+@nameSheet+'_temp1''
				SELECT  a.entidad
						,a.mnc
						,a.Meas_date
						,sum(a.[Subidas]) as UL_NC_ATTEMPTS
						,sum(a.[Fallos de Acceso]) as UL_NC_ERRORS_ACCESSIBILITY
						,sum(a.[Fallos de descarga]) as UL_NC_ERRORS_RETAINABILITY
						,sum(a.[Count_Throughput_64k]) as UL_NC_CONNECTIONS_TH_64KBPS
						,case when sum(a.[Count_Throughput])>0 then sum(a.[Throughput]*a.[Count_Throughput])/sum(a.[Count_Throughput])
							else 0 end as UL_NC_MEAN
						,max(a.[Throughput Max]) as UL_NC_PEAK
						,case when sum(a.[Subidas]) >0 
						then sum(a.[SessionTime]*a.[Subidas])/sum(a.[Subidas])
								else 0 end as UL_NC_SESSION_TIME
				into [DASHBOARD].[dbo].lcc_UL_Th_NC_'+@nameSheet+'_temp1
				FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC' + @sheetTech + ']  a
				where  '+ @LAfilter +'
				group by a.mnc,a.entidad,a.Meas_date'
EXECUTE sp_executesql @SQLString

SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_UL_Th_NC_'+@nameSheet+'_temp''
				SELECT  a.entidad as entidad_ul_NC
						,a.mnc as mnc_ul_NC
						,a.Meas_date as Meas_date_ul_NC
						,a.UL_NC_ATTEMPTS
						,a.UL_NC_ERRORS_ACCESSIBILITY
						,a.UL_NC_ERRORS_RETAINABILITY
						,a.UL_NC_CONNECTIONS_TH_64KBPS
						,a.UL_NC_MEAN
						,b.DESV_TH as UL_NC_STD_TH
						,a.UL_NC_PEAK
						,a.UL_NC_SESSION_TIME
						,b.P10 as UL_NC_10TH
						,'''' as UL_NC_10TH_AGGR_ENTITIES
						,'''' as UL_NC_10TH_AGGR_SCOPE
						,b.P90 as UL_NC_90TH
						,'''' as UL_NC_90TH_AGGR_ENTITIES
						,'''' as UL_NC_90TH_AGGR_SCOPE
				into [DASHBOARD].[dbo].lcc_UL_Th_NC_'+@nameSheet+'_temp
				FROM [DASHBOARD].[dbo].lcc_UL_Th_NC_'+@nameSheet+'_temp1 a
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_UL_Th_NC_'+@nameSheet+'_temp1''';	
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Data_Latency

exec [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_LATENCY] @database,@sheetTech,@nameSheet,@LAfilter

--SET @SQLString =N'
--				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Latency_'+@nameSheet+'_temp1''
--				SELECT  a.entidad
--						,a.mnc 
--						,a.Meas_date
--						,sum(a.pings) as LAT_PINGS
--						,case when sum(a.pings)> 0  then 1.0*sum(a.rtt*a.pings)/sum(a.pings)
--							else 0 end as LAT_AVG
--				into [DASHBOARD].[dbo].lcc_Latency_'+@nameSheet+'_temp1
--				FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping' + @sheetTech+']	a
--				inner join AGRIDS.dbo.lcc_dashboard_info_scopes_NEW b on b.ENTITIES_BBDD=a.entidad
--				where  '+ @LAfilter +'
--				and (a.Methodology =''D16'' or (a.Methodology=''D15'' and b.scope not in (''MAIN CITIES'',''SMALLER CITIES'')))
--				group by a.mnc,a.entidad,a.Meas_date

--				';


if @DataBase not like '%AGGRData3G%'
	
	begin

		SET @SQLString =N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Latency_'+@nameSheet+'_temp1''
						SELECT  a.entidad
								,a.mnc 
								,a.Meas_date
								,sum(a.pings) as LAT_PINGS
								,case when sum(a.pings)> 0  then 1.0*sum(a.rtt*a.pings)/sum(a.pings)
									else 0 end as LAT_AVG
						into [DASHBOARD].[dbo].lcc_Latency_'+@nameSheet+'_temp1
						FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping' + @sheetTech+']	a
						left outer join AGRIDS.dbo.lcc_dashboard_info_scopes_NEW b on b.ENTITIES_BBDD=a.entidad and b.report=''MUN''
						--inner join AGRIDS.dbo.lcc_dashboard_info_scopes_NEW b on b.ENTITIES_BBDD=a.entidad and b.report=''MUN''
						where  '+ @LAfilter +'
						and (a.Methodology =''D16'' or (a.Methodology=''D15'' and b.scope not in (''MAIN CITIES'',''SMALLER CITIES'')))
						group by a.mnc,a.entidad,a.Meas_date

						';

		print @SQLString

	end

else 
	
	begin

		SET @SQLString =N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Latency_'+@nameSheet+'_temp1''
						SELECT  a.entidad
								,a.mnc 
								,a.Meas_date
								,sum(a.pings) as LAT_PINGS
								,case when sum(a.pings)> 0  then 1.0*sum(a.rtt*a.pings)/sum(a.pings)
									else 0 end as LAT_AVG
						into [DASHBOARD].[dbo].lcc_Latency_'+@nameSheet+'_temp1
						FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping' + @sheetTech+']	a
						--inner join AGRIDS.dbo.lcc_dashboard_info_scopes_NEW b on b.ENTITIES_BBDD=a.entidad
						where  '+ @LAfilter +'
						group by a.mnc,a.entidad,a.Meas_date

						';

	end

EXECUTE sp_executesql @SQLString


SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Latency_'+@nameSheet+'_temp''
				SELECT  a.entidad as entidad_lat
						,a.mnc as mnc_lat
						,a.Meas_date as Meas_date_lat
						,a.LAT_PINGS
						,b.Median as LAT_MEDIAN
						,a.LAT_AVG
						,'''' as LAT_MEDIAN_AGGR_ENTITIES
						,'''' as LAT_MEDIAN_AGGR_SCOPE
				into [DASHBOARD].[dbo].lcc_Latency_'+@nameSheet+'_temp
				FROM [DASHBOARD].[dbo].lcc_Latency_'+@nameSheet+'_temp1	a
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_'+@nameSheet+'] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Latency_'+@nameSheet+'_temp1''';
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Data_Web_Browsing
IF @methodology = 'D15'
BEGIN 
	SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Browsing_'+@nameSheet+'_temp''
					SELECT	a.entidad as entidad_web
							,a.mnc as mnc_web
							,a.Meas_date as Meas_date_web
							,sum(a.[Navegaciones]) as WEB_ATTEMPS
							,sum(a.[NavegacionesKepler0]) as WEB_ATTEMPS_KEPLER
							,sum(a.[Fallos de acceso]) as WEB_ERRORS_ACCESSIBILITY
							,sum(a.[Navegaciones fallidas]) as WEB_ERRORS_RETAINABILITY
							,case when sum(a.[Count_SessionTime]) >0 then sum(a.[Session Time]*a.[Count_SessionTime])/sum(a.[Count_SessionTime])
								else 0 end as WEB_D5
							,case when sum(a.[Count_IPServiceSetupTime])>0 then sum(a.[IP Service Setup Time]*a.[Count_IPServiceSetupTime])/sum(a.[Count_IPServiceSetupTime]) 
								else 0 end as WEB_IP_ACCESS_TIME
							,case when sum(a.[Count_TransferTime])>0 then sum(a.[Transfer Time]*a.[Count_TransferTime])/sum(a.[Count_TransferTime])
								else 0 end as WEB_HTTP_TRANSFER_TIME
							,sum(a.[Navegaciones_16s]) as WEB_SESSIONS_16SEC
							,sum(a.[NavegacionesKepler0_10s]) as WEB_SESSIONS_10SEC
					into [DASHBOARD].[dbo].lcc_Browsing_'+@nameSheet+'_temp
					FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Web' + @sheetTech + '] a
					where '+ @LAfilter +' 
					group by a.mnc,a.entidad,a.Meas_date order by a.mnc';
END
ELSE IF
@methodology = 'D16'
BEGIN
	SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Browsing_'+@nameSheet+'_temp''
					SELECT	a.entidad as entidad_web
							,a.mnc as mnc_web
							,a.Meas_date as Meas_date_web
							,sum(a.[Navegaciones]) as WEB_ATTEMPS
							,sum(a.[Fallos de acceso]) as WEB_ERRORS_ACCESSIBILITY
							,sum(a.[Navegaciones fallidas]) as WEB_ERRORS_RETAINABILITY
							,case when sum(a.[Count_SessionTime]) >0 then sum(a.[Session Time]*a.[Count_SessionTime])/sum(a.[Count_SessionTime])
								else 0 end as WEB_D5
							,case when sum(a.[Count_IPServiceSetupTime])>0 then sum(a.[IP Service Setup Time]*a.[Count_IPServiceSetupTime])/sum(a.[Count_IPServiceSetupTime]) 
								else 0 end as WEB_IP_ACCESS_TIME
							,case when sum(a.[Count_TransferTime])>0 then sum(a.[Transfer Time]*a.[Count_TransferTime])/sum(a.[Count_TransferTime])
								else 0 end as WEB_HTTP_TRANSFER_TIME
							,sum(a.[Navegaciones HTTPS]) as WEB_ATTEMPS_HTTPS
							,sum(a.[Fallos de acceso HTTPS]) as WEB_ERRORS_ACCESSIBILITY_HTTPS
							,sum(a.[Navegaciones fallidas HTTPS]) as WEB_ERRORS_RETAINABILITY_HTTPS
							,case when sum(a.[Count_SessionTime HTTPS]) >0 then sum(a.[Session Time HTTPS]*a.[Count_SessionTime HTTPS])/sum(a.[Count_SessionTime HTTPS])
								else 0 end as WEB_D5_HTTPS
							,case when sum(a.[Count_IPServiceSetupTime HTTPS])>0 then sum(a.[IP Service Setup Time HTTPS]*a.[Count_IPServiceSetupTime HTTPS])/sum(a.[Count_IPServiceSetupTime HTTPS]) 
								else 0 end as WEB_IP_ACCESS_TIME_HTTPS
							,case when sum(a.[Count_TransferTime HTTPS])>0 then sum(a.[Transfer Time HTTPS]*a.[Count_TransferTime HTTPS])/sum(a.[Count_TransferTime HTTPS])
								else 0 end as WEB_HTTP_TRANSFER_TIME_HTTPS
					into [DASHBOARD].[dbo].lcc_Browsing_'+@nameSheet+'_temp
					FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Web' + @sheetTech + '] a
					where '+ @LAfilter +' 
					group by a.mnc,a.entidad,a.Meas_date order by a.mnc';
END 

EXECUTE sp_executesql @SQLString
-------------------------------------------------------------------------------
-- Data_Youtube SD
if @nameSheet <> '4G_CAONLY'
begin
	SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_YTB_SD_'+@nameSheet+'_temp''
					SELECT	a.entidad as entidad_ytb_sd
							,a.mnc as mnc_ytb_sd
							,a.Meas_date as Meas_date_ytb_sd
							,sum(a.[Reproducciones]) as YTB_SD_ATTEMPS
							,case when sum(a.[Reproducciones]-a.[Fails])>0 then sum(a.[Time To First Image]*(a.[Reproducciones]-a.[Fails]))/sum(a.[Reproducciones]-a.[Fails])
								else 0 end as YTB_SD_AVG_START_TIME
							,sum(a.[Fails]) as YTB_SD_FAILS 
							,case when sum(a.[Reproducciones])>0 then (1-1.0*sum(a.[Fails])/sum(a.[Reproducciones]))
								else 0 end as YTB_SD_B1
							,sum(a.[ReproduccionesSinInt]) as YTB_SD_REPR_NO_INTERRUPTIONS
							,case when sum(a.[Reproducciones])>0 then 1.0*sum(a.[ReproduccionesSinInt])/sum(a.[Reproducciones])
								else 0 end as YTB_SD_B2
							,sum(a.[Successful video download]) as YTB_SD_SUCC_DL
					into [DASHBOARD].[dbo].lcc_YTB_SD_'+@nameSheet+'_temp
					FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube' + @sheetTech +'] a
					where '+ @LAfilter +' 
					group by a.mnc,a.entidad,a.Meas_date order by a.mnc';
	EXECUTE sp_executesql @SQLString
end
-------------------------------------------------------------------------------
-- Data_Youtube HD
IF @methodology = 'D15'
BEGIN 
	SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_YTB_HD_'+@nameSheet+'_temp''
					SELECT	a.entidad as entidad_ytb_hd
							,a.mnc as mnc_ytb_hd
							,a.Meas_date as Meas_date_ytb_hd
							,sum(a.[Reproducciones]) as YTB_HD_ATTEMPS
							,case when sum(a.[Reproducciones]-a.[Fails])>0 then sum(a.[Time To First Image]*(a.[Reproducciones]-a.[Fails]))/sum(a.[Reproducciones]-a.[Fails])
								else 0 end as YTB_HD_AVG_START_TIME
							,sum(a.[Fails]) as YTB_HD_FAILS 
							,case when sum(a.[Reproducciones]) >0 then (1-1.0*sum(a.[Fails])/sum(a.[Reproducciones]))
								else 0 end as YTB_HD_B1
							,sum(a.[ReproduccionesSinInt]) as YTB_HD_REPR_NO_INTERRUPTIONS
							,sum(a.[ReproduccionesHD]) as YTB_HD_REPR_NO_COMPRESSION
							,case when sum(a.[Reproducciones])>0 then 1.0*sum(a.[ReproduccionesSinInt])/sum(a.[Reproducciones])
								else 0 end as YTB_HD_B2
							,sum(a.[Successful video download]) as YTB_HD_SUCC_DL
					into [DASHBOARD].[dbo].lcc_YTB_HD_'+@nameSheet+'_temp
					FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube_HD' + @sheetTech +'] a
					where '+ @LAfilter +'
					group by a.mnc,a.entidad,a.Meas_date order by a.mnc';
END
ELSE IF @methodology = 'D16'
BEGIN
	SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_YTB_HD_'+@nameSheet+'_temp''
					SELECT	a.entidad as entidad_ytb_hd
							,a.mnc as mnc_ytb_hd
							,a.Meas_date as Meas_date_ytb_hd
							,case when sum(a.[Count_Video_Resolucion])>0 then
								cast((sum(cast (left(a.[avg Video Resolution],3) as int)*a.[Count_Video_Resolucion])/sum(a.[Count_Video_Resolucion])) as varchar(10)) + ''p'' 
								else null end as [avg video resolution]
							,case when sum(isnull(a.[B4], 0))>0 then sum(a.[B4]) 
								when sum(a.[ReproduccionesHD])<sum(a.[Successful video download]) then sum(a.[ReproduccionesHD]) 
								else sum(a.[Successful video download]) end as [B4 hd share]
							,case when sum(a.[Count_Video_MOS])>0 then
								sum(a.[Video MOS]*a.[Count_Video_MOS])/sum(a.[Count_Video_MOS]) 
								else 0 end as [video mos]
							,sum(a.[Reproducciones]) as YTB_HD_ATTEMPS
							,case when sum(a.[Reproducciones]-a.[Fails])>0 then sum(a.[Time To First Image]*(a.[Reproducciones]-a.[Fails]))/sum(a.[Reproducciones]-a.[Fails])
								else 0 end as YTB_HD_AVG_START_TIME
							,sum(a.[Fails]) as YTB_HD_FAILS 
							,case when sum(a.[Reproducciones]) >0 then (1-1.0*sum(a.[Fails])/sum(a.[Reproducciones]))
								else 0 end as YTB_HD_B1
							,sum(a.[ReproduccionesSinInt]) as YTB_HD_REPR_NO_INTERRUPTIONS
							,sum(a.[ReproduccionesHD]) as YTB_HD_REPR_NO_COMPRESSION
							,case when sum(a.[Reproducciones])>0 then 1.0*sum(a.[ReproduccionesSinInt])/sum(a.[Reproducciones])
								else 0 end as YTB_HD_B2
							,sum(a.[Successful video download]) as YTB_HD_SUCC_DL
					into [DASHBOARD].[dbo].lcc_YTB_HD_'+@nameSheet+'_temp
					FROM [DASHBOARD].[dbo].[UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube_HD' + @sheetTech +'] a
					where '+ @LAfilter +'
					group by a.mnc,a.entidad,a.Meas_date order by a.mnc';
END
print @SQLString
EXECUTE sp_executesql @SQLString
