USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_NEW_Report_20160826]    Script Date: 29/05/2017 14:00:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_NEW_Report_20160826] 
	@nameSheet as varchar(256)
	,@scope as varchar(256)
	,@LA as bit
	,@UpdateMeasur as bit
	,@Methodology as varchar(50)
	,@report as varchar(256)
as

-------------------------------------------------------------------------------
--Inicialización de variables

--declare @namesheet as varchar(255)='C&T_4G_CA_MAIN_CITIES'
--declare @scope as varchar(256)='MAIN CITIES'
--declare @output as varchar(1024) = 'F:\DASHBOARD\RESULTS\DASHBOARD_DATA.xls'
--declare @template as varchar(1014) ='F:\DASHBOARD\TEMPLATES\DASHBOARD_DATA.xls'
--declare @print as bit=1
--declare @LA as bit=1
--declare @UpdateMeasur as bit=1
--declare @Methodology as varchar(50)='D16'
--declare @report as varchar(256)='VDF'

declare @group as bit
declare @database as varchar(256)
declare @sheetTech as varchar(256)
declare @table as varchar(256)
DECLARE @SQLString nvarchar(max)
DECLARE @sheet nvarchar(256)
declare @prefix varchar(256)
declare @LAfilter varchar(2000)
declare @EntitiesNOLAfilter varchar(2000)

if @nameSheet like '%4G%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @database='[AGGRData4G]'
			else if @nameSheet like '%4G%' and @nameSheet like '%road%' set @database='[AGGRData4G_ROAD]'
				else if @nameSheet like '%4G%' and @nameSheet like '%railways%' set @database='[AGGRData4G]'
					else if @nameSheet like '%2G3G%' set @database='[AGGRData3G]'
						else set @database='NULL'
		
if @nameSheet like '%4G%ONLY%' and @nameSheet not like '%4G_CAONLY%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheetTech='_4G'
	--else if @nameSheet like '%4G_CA%' and @nameSheet not like '%4G_CAONLY%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheetTech='_CA'
		else if @nameSheet like '%4G_CAONLY%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheetTech='_CA_ONLY'
			else if @nameSheet like '%4G%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheetTech=''
				else if @nameSheet like '%2G3G%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheetTech=''
					else if @nameSheet like '%4G%ONLY%'  and @nameSheet like '%road%' and @nameSheet not like '%region%' set @sheetTech='_4G_ROAD'
						else if @nameSheet like '%4G_CA%' and @nameSheet not like '%4G_CAONLY%' and @nameSheet like '%road%' and @nameSheet not like '%region%' set @sheetTech='_CA_ROAD'
							else if @nameSheet like '%4G_CAONLY%' and @nameSheet like '%road%' and @nameSheet not like '%region%' set @sheetTech='_CA_ONLY_ROAD'
								else if @nameSheet like '%4G%'  and @nameSheet like '%road%' and @nameSheet not like '%region%' set @sheetTech='_ROAD'
									else if @nameSheet like '%4G%'  and @nameSheet like '%road%' and @nameSheet like '%region%' set @sheetTech='_ROAD_REGION'
										else if @nameSheet like '%2G3G%' and @nameSheet like '%road%' set @sheetTech='_ROAD'
											else if @nameSheet like '%4G%ONLY%' and @nameSheet like '%railway%' set @sheetTech='_4G_RAILWAY'
												else if @nameSheet like '%4G%' and @nameSheet like '%railway%'  set @sheetTech='_RAILWAY'


if @nameSheet like '%4G%ONLY%' and @nameSheet not like '%4G_CAONLY%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheet='4G_ONLY'
	--else if @nameSheet like '%4G_CA%' and @nameSheet not like '%4G_CAONLY%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheet='4G_CA'
		else if @nameSheet like '%4G_CAONLY%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheet='4G_CAONLY'
			else if @nameSheet like '%4G%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheet='4G'
				else if @nameSheet like '%2G3G%' and @nameSheet not like '%road%' and @nameSheet not like '%railway%' set @sheet='2G3G'
					else if @nameSheet like '%4G%ONLY%' and @nameSheet like '%road%' and @nameSheet not like '%region%' set @sheet='4G_ONLY_ROAD'
						else if @nameSheet like '%4G%' and @nameSheet like '%road%' and @nameSheet not like '%region%'  set @sheet='4G_ROAD'
							else if @nameSheet like '%4G%' and @nameSheet like '%road%' and @nameSheet like '%region%'  set @sheet='4G_ROAD_REGION'
								else if @nameSheet like '%4G%ONLY%' and @nameSheet like '%railway%' set @sheet='4G_ONLY_RAILWAY'
									else if @nameSheet like '%4G%' and @nameSheet like '%railway%'set @sheet='4G_RAILWAY'


set @table ='UPDATE_'+replace(replace(@database,'[',''),']','')+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+ @sheetTech
set @prefix  ='UPDATE_'+replace(replace(@database,'[',''),']','')+'_'

-- Variable para eliminar las entidades en las que no se ha medido LA y queremos destarcar
if @nameSheet like '2G3G'
	set @EntitiesNOLAfilter= ' and a.entidad not like ''coruna'''
else
	set @EntitiesNOLAfilter=' and (a.entidad not like ''alicante'' and a.entidad not like ''sevilla'' and a.entidad not like ''barcelona'')'

if @la = 1 set @LAfilter ='a.entorno  not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
else set @LAfilter= '(a.entorno like ''%%'' or a.entorno is null)' + @EntitiesNOLAfilter
-------------------------------------------------------------------------------

-- Separar por Scopes 
if @scope ='MAIN HIGHWAYS REGION' set @group=1
else set @group=0

exec [dbo].[sp_lcc_create_Dashboard_Entities_NEW_Report] @scope,'[DASHBOARD]',@table,@group,@report

-- Modificación de la tabla lcc_entities_dashboard con la información relativa a la pestaña particular
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_entities_dashboard_temp'
if @scope ='MAIN HIGHWAYS REGION' 
begin
	select e.*, '' as SHEET, '' as TECHNOLOGY, '' as CARRIER_AGGREGATION, '' as SMARTPHONE_MODEL, '' as FIRMWARE_VERSION
			,'' as HANDSET_CAPABILITY, '' as TEST_MODALITY, '' as MCC,'' as OPCOS
	into [DASHBOARD].[dbo].lcc_entities_dashboard_temp
	from [DASHBOARD].[dbo].lcc_entities_dashboard e
end
else
begin 
	select e.*, i.SHEET, i.TECHNOLOGY, i.CARRIER_AGGREGATION, i.SMARTPHONE_MODEL, i.FIRMWARE_VERSION
			,i.HANDSET_CAPABILITY,i.TEST_MODALITY,i.MCC,i.OPCOS
	into [DASHBOARD].[dbo].lcc_entities_dashboard_temp
	from [DASHBOARD].[dbo].lcc_entities_dashboard e,
		[AGRIDS].[dbo].lcc_dashboard_info_data i
	where e.scope=i.scope and i.sheet=@nameSheet
end

-------------------------------------------------------------------------------
if @UpdateMeasur = 1
begin 
	-- Modificación de las tablas para replicar la información de las medidas invalidadas. Se toma la inmediatamente anterior.
	if @scope not like '%HIGHWAYS%' and @scope not like '%RAILWAY%'
	exec [dbo].[sp_lcc_create_Dashboard_Entities_NEW_Report] @scope,'[DASHBOARD]',@table,1,@report
	exec [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR] @Sheet, 'DATA',@database
end

-------------------------------------------------------------------------------
-- Se generan los estadísticos por scope

-- Cálculos de las medianas para obtener las latencias
exec [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_LATENCY_SCOPE_NEW_Report] @database,@sheetTech,@scope,@LAfilter,@report

-- Cálculos de los percentiles para los test DL y UL (tanto NC como CE)
exec [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES_SCOPE]  @database,@sheetTech,@scope,@LAfilter

-- Cálculo de las extensiones medidas
exec [dbo].[sp_lcc_km2_medidos_v2_NEW_Report] @prefix,@sheetTech,@LA,@report
-------------------------------------------------------------------------------

-- Lincado de las tablas temporales [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_Scope]
SET @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_data_'+ @sheet + '_step1''
				declare @typeMeasur as varchar(256)=''' +@sheet + '''
				select	d.entidad as entidad_1
						,d.mnc as mnc_1
						,d.Meas_date as Meas_date_1
						,d.type_scope as SCOPE
						,d.TECHNOLOGY as TECHNOLOGY
						,d.CARRIER_AGGREGATION as CARRIER
						,d.SCOPE as [TARGET ON SCOPE]
						,d.ENTITIES_DASHBOARD
						,dl_CE.DL_CE_ATTEMPTS
						,dl_CE.DL_CE_ERRORS_ACCESSIBILITY
						,dl_CE.DL_CE_ERRORS_RETAINABILITY
						,dl_CE.DL_CE_D1
						,dl_CE.DL_CE_STD_TH
						,dl_CE.DL_CE_D2
						,dl_CE.DL_CE_CONNECTIONS_TH_3MBPS
						,dl_CE.DL_CE_CONNECTIONS_TH_1MBPS
						,dl_CE.DL_CE_PEAK
						,dl_CE.DL_CE_10TH
						,w.P10_DL_CE as DL_CE_10TH_AGGR_ENTITIES
						,w.P10_DL_CE_MS as DL_CE_10TH_AGGR_SCOPE
						,dl_CE.DL_CE_90TH
						,w.P90_DL_CE as DL_CE_90TH_AGGR_ENTITIES
						,w.P90_DL_CE_MS as DL_CE_90TH_AGGR_SCOPE
						,ul_CE.UL_CE_ATTEMPTS
						,ul_CE.UL_CE_ERRORS_ACCESSIBILITY
						,ul_CE.UL_CE_ERRORS_RETAINABILITY
						,ul_CE.UL_CE_D3
						,ul_CE.UL_CE_STD_TH
						,ul_CE.UL_CE_PEAK
						,ul_CE.UL_CE_10TH
						,w.P10_UL_CE as UL_CE_10TH_AGGR_ENTITIES
						,w.P10_UL_CE_MS as UL_CE_10TH_AGGR_SCOPE
						,ul_CE.UL_CE_90TH
						,w.P90_UL_CE as UL_CE_90TH_AGGR_ENTITIES
						,w.P90_UL_CE_MS as UL_CE_90TH_AGGR_SCOPE
						,dl_NC.DL_NC_ATTEMPTS
						,dl_NC.DL_NC_ERRORS_ACCESSIBILITY
						,dl_NC.DL_NC_ERRORS_RETAINABILITY
						,dl_NC.DL_NC_CONNECTIONS_TH_128KBPS
						,dl_NC.DL_NC_MEAN
						,dl_NC.DL_NC_STD_TH
						,dl_NC.DL_NC_PEAK
						,dl_NC.DL_NC_10TH
						,w.P10_DL_NC as DL_NC_10TH_AGGR_ENTITIES
						,w.P10_DL_NC_MS as DL_NC_10TH_AGGR_SCOPE
						,dl_NC.DL_NC_90TH
						,w.P90_DL_NC as DL_NC_90TH_AGGR_ENTITIES
						,w.P90_DL_NC_MS as DL_NC_90TH_AGGR_SCOPE
						,ul_NC.UL_NC_ATTEMPTS
						,ul_NC.UL_NC_ERRORS_ACCESSIBILITY
						,ul_NC.UL_NC_ERRORS_RETAINABILITY
						,ul_NC.UL_NC_CONNECTIONS_TH_64KBPS
						,ul_NC.UL_NC_MEAN
						,ul_NC.UL_NC_STD_TH
						,ul_NC.UL_NC_PEAK
						,ul_NC.UL_NC_10TH
						,w.P10_UL_NC as UL_NC_10TH_AGGR_ENTITIES
						,w.P10_UL_NC_MS as UL_NC_10TH_AGGR_SCOPE
						,ul_NC.UL_NC_90TH
						,w.P90_UL_NC as UL_NC_90TH_AGGR_ENTITIES
						,w.P90_UL_NC_MS as UL_NC_90TH_AGGR_SCOPE
				into [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + '_step1]
				from [DASHBOARD].[dbo].[lcc_entities_dashboard_temp] d
				left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope] w
					on d.mnc=w.mnc
				left outer join [DASHBOARD].[dbo].[lcc_DL_Th_CE_'+@sheet+'_temp] dl_CE 
					on d.mnc=dl_CE.mnc_dl_CE and d.entidad=dl_CE.entidad_dl_CE and d.Meas_date=dl_CE.Meas_date_dl_CE
				left outer join [DASHBOARD].[dbo].[lcc_UL_Th_CE_'+ @sheet + '_temp] ul_CE
					on d.mnc=ul_CE.mnc_ul_CE and d.entidad=ul_CE.entidad_ul_CE and d.Meas_date=ul_CE.Meas_date_ul_CE
				left outer join [DASHBOARD].[dbo].[lcc_DL_Th_NC_'+ @sheet + '_temp] dl_NC
					on d.mnc=dl_NC.mnc_dl_NC and d.entidad=dl_NC.entidad_dl_NC and d.Meas_date=dl_NC.Meas_date_dl_NC
				left outer join [DASHBOARD].[dbo].[lcc_UL_Th_NC_'+ @sheet + '_temp] ul_NC
					on d.mnc=ul_NC.mnc_ul_NC and d.entidad=ul_NC.entidad_ul_NC and d.Meas_date=ul_NC.Meas_date_ul_NC';
EXECUTE sp_executesql @SQLString

IF @Methodology = 'D15'
BEGIN
	if @nameSheet <> '4G_CAONLY'
	begin	
		SET @SQLString= N'
						declare @typeMeasur as varchar(256)=''' +@sheet + '''
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_data_'+ @sheet + '''
						select a.*
								,lat.LAT_PINGS
								,convert(int,lat.LAT_MEDIAN) as LAT_MEDIAN
								,convert(int,lat.LAT_AVG) as LAT_AVG
								,convert(int,w.Median_Scope) as LAT_MEDIAN_AGGR_ENTITIES
								,case when w.Median_MS = 0 then ''''
										when w.Median_MS <> 0 then convert(int, w.Median_MS)
										end as LAT_MEDIAN_AGGR_SCOPE
								,web.*
								,ytb_sd.*
								,ytb_hd.*
								,pm.[AreaTotal(km2)] as URBAN_EXTENSION
								,d.POPULATION as POPULATION_COVERED
								,case when @typeMeasur like ''%REGION%'' then null
									else convert(float,pm.Porcentaje_medido)/100 
									end as SAMPLED_URBAN
								,case	when @typeMeasur like ''%REGION%'' then null
										else convert(float,dl_CE.DL_CE_ATTEMPTS)/convert(float,pm.[AreaTotal(km2)])/(convert(float,pm.Porcentaje_medido)/100)
										end  as NUMBER_TEST_KM 
								,'''' as ROUTE
								,d.SMARTPHONE_MODEL as PHONE_MODEL
								,d.FIRMWARE_VERSION as FIRM_V
								,d.HANDSET_CAPABILITY as HANDSET_CAP
								,d.TEST_MODALITY as TEST
								, ''20'' + d.Meas_date as LAST_ACQUISITION
								,d.OPERATOR
								,d.MCC as MCC
								,d.MNC
								,d.OPCOS as OPCOS
								,d.RAN_VENDOR as RAN_VENDOR
						into [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + ']
						from [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + '_step1] a
						left outer join [DASHBOARD].[dbo].[lcc_entities_dashboard_temp] d
							on d.mnc=a.mnc_1 and d.entidad=a.entidad_1 and d.Meas_date=a.Meas_date_1
						left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_Scope] w
							on a.mnc_1=w.mnc
						left outer join [DASHBOARD].[dbo].[lcc_Latency_'+ @sheet + '_temp] lat
							on d.mnc=lat.mnc_lat and d.entidad=lat.entidad_lat and d.Meas_date=lat.Meas_date_lat
						left outer join [DASHBOARD].[dbo].[lcc_Browsing_'+ @sheet + '_temp] web
							on d.mnc=web.mnc_web and d.entidad=web.entidad_web and d.Meas_date=web.Meas_date_web
						left outer join [DASHBOARD].[dbo].[lcc_YTB_SD_'+ @sheet + '_temp] ytb_sd
							on d.mnc=ytb_sd.mnc_ytb_sd and d.entidad=ytb_sd.entidad_ytb_sd and d.Meas_date=ytb_sd.Meas_date_ytb_sd
						left outer join [DASHBOARD].[dbo].[lcc_YTB_HD_'+ @sheet + '_temp] ytb_hd
							on d.mnc=ytb_hd.mnc_ytb_hd and d.entidad=ytb_hd.entidad_ytb_hd and d.Meas_date=ytb_hd.Meas_date_ytb_hd
						left outer join [DASHBOARD].[dbo].[lcc_DL_Th_CE_'+@sheet+'_temp] dl_CE 
							on d.mnc=dl_CE.mnc_dl_CE and d.entidad=dl_CE.entidad_dl_CE and d.Meas_date=dl_CE.Meas_date_dl_CE
						left outer join dashboard.dbo.lcc_km2_chequeo_mallado pm
							on d.entidad=pm.entidad and d.meas_date=pm.meas_date';
	end
	if @nameSheet = '4G_CAONLY'
	begin	
		SET @SQLString= N'
						declare @typeMeasur as varchar(256)=''' +@sheet + '''
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_data_'+ @sheet + '''
						select a.*
								,lat.LAT_PINGS
								,convert(int,lat.LAT_MEDIAN) as LAT_MEDIAN
								,convert(int,lat.LAT_AVG) as LAT_AVG
								,convert(int,w.Median_Scope) as LAT_MEDIAN_AGGR_ENTITIES
								,case when w.Median_MS = 0 then ''''
										when w.Median_MS <> 0 then convert(int, w.Median_MS)
										end as LAT_MEDIAN_AGGR_SCOPE
								,web.*
								,ytb_hd.*
								,pm.[AreaTotal(km2)] as URBAN_EXTENSION
								,d.POPULATION as POPULATION_COVERED
								,case when @typeMeasur like ''%REGION%'' then null
									else convert(float,pm.Porcentaje_medido)/100 
									end as SAMPLED_URBAN
								,case	when @typeMeasur like ''%REGION%'' then null
										else convert(float,dl_CE.DL_CE_ATTEMPTS)/convert(float,pm.[AreaTotal(km2)])/(convert(float,pm.Porcentaje_medido)/100)
										end  as NUMBER_TEST_KM 
								,'''' as ROUTE
								,d.SMARTPHONE_MODEL as PHONE_MODEL
								,d.FIRMWARE_VERSION as FIRM_V
								,d.HANDSET_CAPABILITY as HANDSET_CAP
								,d.TEST_MODALITY as TEST
								, ''20'' + d.Meas_date as LAST_ACQUISITION
								,d.OPERATOR
								,d.MCC as MCC
								,d.MNC
								,d.OPCOS as OPCOS
								,d.RAN_VENDOR as RAN_VENDOR
						into [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + ']
						from [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + '_step1] a
						left outer join [DASHBOARD].[dbo].[lcc_entities_dashboard_temp] d
							on d.mnc=a.mnc_1 and d.entidad=a.entidad_1 and d.Meas_date=a.Meas_date_1
						left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_Scope] w
							on a.mnc_1=w.mnc
						left outer join [DASHBOARD].[dbo].[lcc_Latency_'+ @sheet + '_temp] lat
							on d.mnc=lat.mnc_lat and d.entidad=lat.entidad_lat and d.Meas_date=lat.Meas_date_lat
						left outer join [DASHBOARD].[dbo].[lcc_Browsing_'+ @sheet + '_temp] web
							on d.mnc=web.mnc_web and d.entidad=web.entidad_web and d.Meas_date=web.Meas_date_web
						left outer join [DASHBOARD].[dbo].[lcc_YTB_HD_'+ @sheet + '_temp] ytb_hd
							on d.mnc=ytb_hd.mnc_ytb_hd and d.entidad=ytb_hd.entidad_ytb_hd and d.Meas_date=ytb_hd.Meas_date_ytb_hd
						left outer join [DASHBOARD].[dbo].[lcc_DL_Th_CE_'+@sheet+'_temp] dl_CE 
							on d.mnc=dl_CE.mnc_dl_CE and d.entidad=dl_CE.entidad_dl_CE and d.Meas_date=dl_CE.Meas_date_dl_CE
						left outer join dashboard.dbo.lcc_km2_chequeo_mallado pm
							on d.entidad=pm.entidad and d.meas_date=pm.meas_date';
	end
END
ELSE IF @Methodology = 'D16'
BEGIN
		SET @SQLString= N'
					declare @typeMeasur as varchar(256)=''' +@sheet + '''
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_data_'+ @sheet + '''
					select a.*
							,lat.LAT_PINGS
							,convert(int,lat.LAT_MEDIAN) as LAT_MEDIAN
							,convert(int,lat.LAT_AVG) as LAT_AVG
							,convert(int,w.Median_Scope) as LAT_MEDIAN_AGGR_ENTITIES
							,case when w.Median_MS = 0 then ''''
									when w.Median_MS <> 0 then convert(int, w.Median_MS)
									end as LAT_MEDIAN_AGGR_SCOPE
							,web.*
							,ytb_hd.*
							,pm.[AreaTotal(km2)] as URBAN_EXTENSION
							,d.POPULATION as POPULATION_COVERED
							,case when @typeMeasur like ''%REGION%'' then null
								else convert(float,pm.Porcentaje_medido)/100 
								end as SAMPLED_URBAN
							,case	when @typeMeasur like ''%REGION%'' then null
									else convert(float,dl_CE.DL_CE_ATTEMPTS)/convert(float,pm.[AreaTotal(km2)])/(convert(float,pm.Porcentaje_medido)/100)
									end  as NUMBER_TEST_KM 
							,'''' as ROUTE
							,d.SMARTPHONE_MODEL as PHONE_MODEL
							,d.FIRMWARE_VERSION as FIRM_V
							,d.HANDSET_CAPABILITY as HANDSET_CAP
							,d.TEST_MODALITY as TEST
							, ''20'' + d.Meas_date as LAST_ACQUISITION
							,d.OPERATOR
							,d.MCC as MCC
							,d.MNC
							,d.OPCOS as OPCOS
							,d.RAN_VENDOR as RAN_VENDOR
					into [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + ']
					from [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + '_step1] a
					left outer join [DASHBOARD].[dbo].[lcc_entities_dashboard_temp] d
						on d.mnc=a.mnc_1 and d.entidad=a.entidad_1 and d.Meas_date=a.Meas_date_1
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_Scope] w
						on a.mnc_1=w.mnc
					left outer join [DASHBOARD].[dbo].[lcc_Latency_'+ @sheet + '_temp] lat
						on d.mnc=lat.mnc_lat and d.entidad=lat.entidad_lat and d.Meas_date=lat.Meas_date_lat
					left outer join [DASHBOARD].[dbo].[lcc_Browsing_'+ @sheet + '_temp] web
						on d.mnc=web.mnc_web and d.entidad=web.entidad_web and d.Meas_date=web.Meas_date_web
					left outer join [DASHBOARD].[dbo].[lcc_YTB_HD_'+ @sheet + '_temp] ytb_hd
						on d.mnc=ytb_hd.mnc_ytb_hd and d.entidad=ytb_hd.entidad_ytb_hd and d.Meas_date=ytb_hd.Meas_date_ytb_hd
					left outer join [DASHBOARD].[dbo].[lcc_DL_Th_CE_'+@sheet+'_temp] dl_CE 
						on d.mnc=dl_CE.mnc_dl_CE and d.entidad=dl_CE.entidad_dl_CE and d.Meas_date=dl_CE.Meas_date_dl_CE
					left outer join dashboard.dbo.lcc_km2_chequeo_mallado pm
						on d.entidad=pm.entidad and d.meas_date=pm.meas_date';
END

EXECUTE sp_executesql @SQLString

-- Limpieza de tablas temporales
SET @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_dashboard_results_data_'+ @sheet + '_step1'''
EXECUTE sp_executesql @SQLString	


IF @Methodology = 'D15'
BEGIN
SET @SQLString= N'
				alter table [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + '] drop column  entidad_1, mnc_1, Meas_date_1,
																										entidad_web, mnc_web, Meas_date_web,
																										entidad_ytb_sd, mnc_ytb_sd, Meas_date_ytb_sd,
																										entidad_ytb_hd, mnc_ytb_hd, Meas_date_ytb_hd';


END
ELSE IF @Methodology = 'D16'
BEGIN

SET @SQLString= N'
				alter table [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @sheet + '] drop column  entidad_1, mnc_1, Meas_date_1,
																										entidad_web, mnc_web, Meas_date_web,
																										entidad_ytb_hd, mnc_ytb_hd, Meas_date_ytb_hd';
END

EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Muestra de resultados
SET @SQLString= N'
			select a.*
			from [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @Sheet + '] a
				,[DASHBOARD].[dbo].lcc_entities_dashboard_temp b
			where a.entities_dashboard=b.entities_dashboard and a.mnc=b.mnc and a.LAST_ACQUISITION= ''20''+ b.Meas_date 
			order by convert(int,b.order_dashboard),convert(int,b.order_operator)'

EXECUTE sp_executesql @SQLString

--SET @SQLString= N'
--			select a.*,
--			(a.YTB_SD_SUCC_DL/a.YTB_SD_ATTEMPS) as SUCC_SD_DL_P3,
--			(a.YTB_HD_SUCC_DL/a.YTB_HD_ATTEMPS) as SUCC_HD_DL_P3,
--			(1-1.0*(a.DL_CE_ERRORS_RETAINABILITY + a.DL_CE_ERRORS_ACCESSIBILITY)/a.DL_CE_ATTEMPTS) as D1S,
--			(1-1.0*(a.WEB_ERRORS_RETAINABILITY + a.WEB_ERRORS_ACCESSIBILITY)/a.WEB_ATTEMPS) as D5S,
--			(1-1.0*(a.UL_CE_ERRORS_RETAINABILITY + a.UL_CE_ERRORS_ACCESSIBILITY)/a.UL_CE_ATTEMPTS) as D3S
--			from [DASHBOARD].[dbo].[lcc_dashboard_results_data_'+ @Sheet + '] a
--				,[DASHBOARD].[dbo].lcc_entities_dashboard_temp b
--			where a.entities_dashboard=b.entities_dashboard and a.mnc=b.mnc and a.LAST_ACQUISITION= ''20''+ b.Meas_date 
--			order by convert(int,b.order_dashboard),convert(int,b.order_operator)'

--EXECUTE sp_executesql @SQLString