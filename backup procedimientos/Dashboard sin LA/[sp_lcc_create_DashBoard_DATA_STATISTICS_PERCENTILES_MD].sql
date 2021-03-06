USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES_MD]    Script Date: 20/06/2017 13:12:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES_MD] 
	@sheetTech as varchar(256)
	,@table as varchar(256)
	,@nameSheet as varchar(256)
	,@database as varchar(256)
as

--PDTE!!!!!!!!!!!!!!!!
--Modificar:
-- [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL]   por   [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL]
-- [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW]   por   [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL]



-------------------------------------------------------------------------------
---- Declaración de variables
--declare @sheetTech as varchar(256)	= '' -- or '_CE' '_NC' '_NC_LTE'
--declare @table as varchar(256) = 'UPDATE_AGGRData4G_lcc_aggr_sp_MDD_Data_DL_Thput_CE_LTE_RAILWAY'
--declare @nameSheet as varchar(256) = '4G'
--declare @LAfilter as varchar(256)='(a.entorno like ''%%'' or a.entorno is null)'
--declare @database as varchar(256)='AGGRData4G'

declare @table_modif as varchar(256)
DECLARE @SQLString nvarchar(4000)
declare @step_old float
declare @N_ranges_old int
declare @step_new float
declare @N_ranges_new int

--if @LA = 1 set @LAfilter =' not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
--else set @LAfilter= 'like ''%%'' or a.entorno is null'



if @database like '%AGGRData3G%'
begin
	if CHARINDEX('DL_Thput_CE',@table)>0 or CHARINDEX('DL_Thput_NC',@table)>0
	begin
		set @step_old=1
		set @N_ranges_old=33  --Rango máximo: 32
		set @step_new=0.75
		set @N_ranges_new=45  --Rango máximo: 33
	end
	if CHARINDEX('UL_Thput_CE',@table)>0 or CHARINDEX('UL_Thput_NC',@table)>0
	begin
		set @step_old=0.5
		set @N_ranges_old=11  --Rango máximo: 5
		set @step_new=0.25
		set @N_ranges_new=21  --Rango máximo: 5
	end
end
if @database like '%AGGRData4G%'
begin
	if CHARINDEX('DL_Thput_CE',@table)>0 
	begin
		set @step_old=5
		set @N_ranges_old=31  --Rango máximo: 150
		set @step_new=2
		set @N_ranges_new=51  --Rango máximo: 100
	end
	if CHARINDEX('DL_Thput_NC',@table)>0
	begin
		set @step_old=5
		set @N_ranges_old=31  --Rango máximo: 150
		set @step_new=3.5
		set @N_ranges_new=57  --Rango máximo: 196
	end
	if CHARINDEX('UL_Thput_CE',@table)>0
	begin
		set @step_old=5
		set @N_ranges_old=11  --Rango máximo: 50
		set @step_new=0.5
		set @N_ranges_new=51  --Rango máximo: 25
	end
	if CHARINDEX('UL_Thput_NC',@table)>0
	begin
		set @step_old=5
		set @N_ranges_old=11  --Rango máximo: 50
		set @step_new=0.8
		set @N_ranges_new=66  --Rango máximo: 52
	end
end

-- Cálculo previo de la tabla, para discernir entidad-medida con rangos nuevos agregados o no
-- (en aves-roads de las rondas que se acumulan puede haber unas con rangos nuevos ya calculados pero otras que no,
-- en el momento que la combinacion mnc-Meas_Date-entidad tenga nulos, los percentiles se estiman con rangos antiguos)
-- (en este punto de la lógica el meas_date esta unficiado en todas las rondas que se acumulan)
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''
				select mnc,Meas_Date,entidad
					,sum(case when [ 0-'+convert(varchar,@step_new)+'Mbps_N] is null then 1 else 0 end) as ''Cuenta_nulos''
				into [DASHBOARD].[dbo].['+@table+'_step1]
				from [DASHBOARD].[dbo].['+@table+'] a
				group by mnc,Meas_Date,entidad'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
------ Llamadas a los procedimientos de cálculos de estadísticos con RANGOS ANTIGUOS ------
-------------------------------------------------------------------------------------------

-- Filtrado previo de la tabla
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step2''
				select a.* 
				into [DASHBOARD].[dbo].['+@table+'_step2]
				from [DASHBOARD].[dbo].['+@table+'] a
					inner join [DASHBOARD].[dbo].['+@table+'_step1] b
					on a.mnc=b.mnc and a.Meas_Date=b.Meas_Date and a.entidad=b.entidad and Cuenta_nulos>0'

EXECUTE sp_executesql @SQLString

set @table_modif = @table+'_step2'


-- Desviación típica
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_STDV] '[DASHBOARD]',@sheetTech,@table_modif,@step_old,@N_ranges_old,'Mbps',0,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_STDV' + @sheetTech +'_ALL''
				select entidad,mnc,meas_date,DESV
				into [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_ALL]
				from [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Percentil P90
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,@step_old,@N_ranges_old,0,'Mbps',0.90,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P90_Mbps''
				select entidad,mnc,meas_date,Percentil as P_90
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P90_Mbps]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Percentil P10
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,@step_old,@N_ranges_old,0,'Mbps',0.10,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P10_Mbps''
				select entidad,mnc,meas_date,Percentil as P_10
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P10_Mbps]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString


-------------------------------------------------------------------------------------------
------ Llamadas a los procedimientos de cálculos de estadísticos con RANGOS NUEVOS ------
-------------------------------------------------------------------------------------------

-- Filtrado previo de la tabla

set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step2''
				select a.* 
				into [DASHBOARD].[dbo].['+@table+'_step2]
				from [DASHBOARD].[dbo].['+@table+'] a
					inner join [DASHBOARD].[dbo].['+@table+'_step1] b
					on a.mnc=b.mnc and a.Meas_Date=b.Meas_Date and a.entidad=b.entidad and Cuenta_nulos<=0'
EXECUTE sp_executesql @SQLString

set @table_modif = @table+'_step2'

-- Desviación típica
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_STDV] '[DASHBOARD]',@sheetTech,@table_modif,@step_new,@N_ranges_new,'Mbps_N',0,1
set @SQLString=N'
				IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
						WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_ALL]'') 
						AND type in (N''U'')
					)
					insert into [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_ALL]
					select entidad,mnc,meas_date,DESV				
					from [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +']
				else
					select entidad,mnc,meas_date,DESV	
					into [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_ALL]			
					from [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Percentil P90
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW] '[DASHBOARD]',@sheetTech,@table_modif,@step_new,@N_ranges_new,0,'Mbps_N',0.90,1
set @SQLString=N'
				IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
						WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P90_Mbps]'') 
						AND type in (N''U'')
					)
					insert into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P90_Mbps]
					select entidad,mnc,meas_date,Percentil as P_90				
					from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']
				else
					select entidad,mnc,meas_date,Percentil as P_90	
					into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P90_Mbps]			
					from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Percentil P10
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW] '[DASHBOARD]',@sheetTech,@table_modif,@step_new,@N_ranges_new,0,'Mbps_N',0.10,1
set @SQLString=N'
				IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
						WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P10_Mbps]'') 
						AND type in (N''U'')
					)
					insert into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P10_Mbps]
					select entidad,mnc,meas_date,Percentil as P_10				
					from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']
				else
					select entidad,mnc,meas_date,Percentil as P_10
					into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P10_Mbps]				
					from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString



-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Creación de la tabla para almacenar todos los percentiles calculados
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''
				select distinct a.entidad,a.mnc,a.meas_date
				into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1]
				from [DASHBOARD].[dbo].['+@table+'_step1] a

				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'''
				select a.entidad,a.mnc,a.meas_date
						,b.P_90*1000 as P90,c.P_10*1000 as P10,1000*d.DESV as DESV_TH
				into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
				from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P90_Mbps] b
						on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P10_Mbps] c
						on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_ALL] d
						on a.entidad=d.entidad and a.mnc=d.mnc and a.meas_date=d.meas_date
					'
EXECUTE sp_executesql @SQLString 

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P90_Mbps''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P10_Mbps''' +
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''' +
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step2'''
EXECUTE sp_executesql @SQLString


