USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_TABLES_PRE]    Script Date: 29/05/2017 15:14:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_TABLES_PRE] 
	@database as varchar(256)
	,@RW as int
	,@group as varchar(256)
	,@nameSheet as varchar(256)
	,@UpdateMeasur as bit
as

-------------------------------------------------------------------------------
-- Pretatado de las tablas para el caso de tener que agregar por rondas (AVE y HIGHWAYS)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--Inicialización de variables
--declare @database as varchar(256) = '[AGGRData4G_road]'
--declare @nameSheet as varchar(256)='4G_road'
--declare @RW as int = 4
--declare @group as varchar(256) ='road'
--declare @UpdateMeasur as bit =0

declare @typeTable as varchar(256)
declare @sheetTech as varchar(256)
declare @table varchar(256)
declare @step float
declare @N_ranges int
declare @tech as varchar(256)
declare @it as int = 1

DECLARE @SQLString nvarchar(4000)

if @database= '[AGGRData4G]' or @database= '[AGGRData4G_ROAD]'
	set @tech='_LTE'
else 
	set @tech=''

if @nameSheet like '4G%ONLY%' set @sheetTech='_4G'
		--else if @nameSheet like '4G_CA' and @nameSheet not like '4G_CAONLY' set @sheetTech='_CA'
			else if @nameSheet like '4G_CAONLY' set @sheetTech='_CA_ONLY'
				else if @nameSheet in ('4G','4G_road') set @sheetTech=''
					else if @nameSheet like '2G3G' set @sheetTech=''

if @database like '%Data%' set @typeTable='DATA'
else if @database like '%Voice%' set @typeTable='VOICE'

set @database= replace(replace(@database,'[',''),']','')

-------------------------------------------------------------------------------
-- Tablas a modificar en el pretratado
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre'
create table [Dashboard].[dbo].[lcc_dashboard_TablesPre](
	Tablename varchar(4000)
	,id int
	,typeTable varchar(256)
)

SET @SQLString =N'
		insert into Dashboard.dbo.lcc_dashboard_TablesPre
		values (''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+''',1,''DATA'')			-- Data_DL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+''',2,''DATA'')	-- Data_DL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+''',3,''DATA'')		-- Data_UL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+''',4,''DATA'')	-- Data_UL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+''',5,''DATA'')		-- Data_DL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+''',6,''DATA'')	-- Data_DL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+''',7,''DATA'')		-- Data_UL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+''',8,''DATA'')	-- Data_UL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+''',9,''DATA'')				-- Data_Latency
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Web'+@sheetTech+''',10,''DATA'')				-- Data_Web_Browsing
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube'+@sheetTech+''',11,''DATA'')			-- Data_Youtube SD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+''',12,''DATA'')		-- Data_Youtube HD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+''',1,''VOICE'')						-- Voice_calls
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheetTech+''',2,''VOICE'')	-- Voice_CST
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_PESQ'+@sheetTech+''',3,''VOICE'')							-- Voice_MOS'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Se identifican las semanas que pertenecen a la ventana de medidas
set @table =(select tableName from [Dashboard].[dbo].[lcc_dashboard_TablesPre] where id = 1 and typeTable=@typeTable)

if @group = 'ROAD'
begin 
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_rounds_step1'
	SET @SQLString =N'
					select *
						,ROW_NUMBER() over (partition by b.Entidad_SRonda order by b.Meas_Year,(1*right(b.Meas_Week,len(b.Meas_Week)-1))) as Id
					into [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1]
					from (select distinct substring(a.entidad,1,CHARINDEX(''-R'',a.entidad)-1) as Entidad_SRonda
									,(1*left(a.Meas_date,2)) as Meas_Year
									,a.Meas_date
									,a.Meas_Week
									,substring(a.entidad,CHARINDEX(''-R'',a.entidad)+1,len(a.entidad)) as Ronda
									,a.entidad as entidad_orig
									from [dashboard].[dbo].'+@table+' a
									)b
									,[AGRIDS].[dbo].lcc_dashboard_info_scopes c
					where c.entities_bbdd=b.Entidad_SRonda and c.scope=''MAIN HIGHWAYS'''
	EXECUTE sp_executesql @SQLString
end
else if @group = 'RAILWAY'
begin 
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_rounds_step1'
	SET @SQLString =N'
					select *
						,ROW_NUMBER() over (partition by b.Entidad_SRonda order by b.Meas_Year,(1*right(b.Meas_Week,len(b.Meas_Week)-1))) as Id
					into [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1]
					from (select distinct case when CHARINDEX(''-R'',a.entidad) > 0 then substring(a.entidad,1,CHARINDEX(''-R'',a.entidad)-1)
												when CHARINDEX(''-R'',a.entidad) = 0 then a.entidad 
												end as Entidad_SRonda
									,(1*left(a.Meas_date,2)) as Meas_Year
									,a.Meas_date
									,a.Meas_Week
									,substring(a.entidad,CHARINDEX(''-R'',a.entidad)+1,len(a.entidad)) as Ronda
									,a.entidad as entidad_orig
									from [dashboard].[dbo].'+@table+' a
									)b
						,[AGRIDS].[dbo].lcc_dashboard_info_scopes c
					where c.entities_bbdd=b.Entidad_SRonda and c.scope=''RAILWAYS'''
	EXECUTE sp_executesql @SQLString
end

-- Se añade una guarda de dos medidas más en la ventana de medidas a chequear invalidaciones
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_rounds'
SET @SQLString =N'
				select a.Entidad_SRonda, a.meas_year,a.meas_week,a.meas_date, a.id,a.ronda,a.entidad_orig,a.scope,b.maxid
				into [DASHBOARD].[dbo].[lcc_dashboard_rounds]
				from (select * from [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1]
					where entidad_sronda not like entidad_orig) a
					,(select b.entidad_SRonda, max(b.id) as MaxId
						from [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1] b
						group by b.entidad_SRonda) b
				where a.Entidad_SRonda=b.Entidad_SRonda and a.id > (b.MaxId - 2 - '+convert(varchar,@RW)+')'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
if @UpdateMeasur = 1 
begin
	-- Modificación de las tablas para replicar la información de las medidas invalidadas. Se toma la inmediatamente anterior.

	-- Tablas necesarias para saber las medidas y rondas existentes
	set @SQLString=N'	
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard_all_dates_step1''
						select distinct entidad,
								case when CHARINDEX(''-R'',entidad) > 0 then substring(entidad,1,CHARINDEX(''-R'',entidad)-1)
													when CHARINDEX(''-R'',entidad) = 0 then entidad 
													end as Entidad_SRonda,
								(100*substring(Meas_Date,1,2) +200000 + 1*substring(Meas_Date,4,2)) as Meas_date, 
								convert (int,replace(meas_week,''W'','''')) as week,
								convert (int,left((100*substring(Meas_Date,1,2) +200000 + 1*substring(Meas_Date,4,2)),4)) as year
						into [DASHBOARD].[dbo].lcc_entities_dashboard_all_dates_step1
						from [DASHBOARD].[dbo].['+@table+']
						order by entidad, meas_Date

						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_entities_dashboard_all_dates''	
						select a.*, row_number() over(partition by a.entidad_Sronda order by a.entidad_sronda,a.year,a.week asc) as id
						into [DASHBOARD].[dbo].lcc_entities_dashboard_all_dates
						from 
							(select * from [DASHBOARD].[dbo].lcc_entities_dashboard_all_dates_step1
								where entidad_sronda not like entidad)a'
	EXECUTE sp_executesql @SQLString
	print '[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR_ROUNDS]'+@sheetTech+' '+ @typeTable+' '+@database
	-- Llamada al procedimiento
	exec [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR_ROUNDS] @sheetTech, @typeTable,@database
end
-------------------------------------------------------------------------------
-- Se modifican las tablas para que sólo se consideren las medidas pertenecientes 
-- a la ventana de medidas
set @it = 1
while (@it <= (SELECT max(id) FROM [Dashboard].[dbo].[lcc_dashboard_TablesPre] where typeTable=@typeTable))
begin 
	set @table =(select tableName from [Dashboard].[dbo].[lcc_dashboard_TablesPre] where id = @it and typeTable=@typeTable)

	if @group = 'ROAD'
	begin
		SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_'+@group+'''
					select a.*,b.Entidad_SRonda,c.Meas_date_max,b.ronda, b.entidad_orig
					into [DASHBOARD].[dbo].['+@table+'_'+@group+']
					from [DASHBOARD].[dbo].'+@table+' a
						,(select * from [DASHBOARD].[dbo].[lcc_dashboard_rounds]
						 where id > (MaxId-'+convert(varchar,@RW)+')
						 )b
						,(select a.Entidad_SRonda, a.meas_date as Meas_date_max
							from [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1] a
								,(select b.entidad_SRonda, max(b.id) as MaxId
									from [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1] b
									group by b.entidad_SRonda) b
							where a.Entidad_SRonda=b.Entidad_SRonda and a.id = b.MaxId
						)c
					where substring(a.entidad,1,CHARINDEX(''-R'',a.entidad)-1)=b.entidad_SRonda and b.ronda=substring(a.entidad,CHARINDEX(''-R'',a.entidad)+1,len(a.entidad))
							and substring(a.entidad,1,CHARINDEX(''-R'',a.entidad)-1)=c.entidad_SRonda'
		EXECUTE sp_executesql @SQLString
	end 
	else if @group='RAILWAY'
	begin
		SET @SQLString =N'
						exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_'+@group+'''
						select a.*,c.Meas_date_max,b.entidad_orig
						into [DASHBOARD].[dbo].['+@table+'_'+@group+']
						from (select a.*,case when CHARINDEX(''-R'',a.entidad) > 0 then substring(a.entidad,1,CHARINDEX(''-R'',a.entidad)-1)
												when CHARINDEX(''-R'',a.entidad) = 0 then a.entidad 
												end as Entidad_SRonda
							,case when CHARINDEX(''-R'',a.entidad) > 0 then substring(a.entidad,CHARINDEX(''-R'',a.entidad)+1,len(a.entidad))
												when CHARINDEX(''-R'',a.entidad) = 0 then a.entidad 
												end as Ronda 
							from [DASHBOARD].[dbo].'+@table+' a )a
							,(select * from [DASHBOARD].[dbo].[lcc_dashboard_rounds]
							 where id > (MaxId-'+convert(varchar,@RW)+')
							 )b
							,(select a.Entidad_SRonda, a.meas_date as Meas_date_max
								from [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1] a
									,(select b.entidad_SRonda, max(b.id) as MaxId
										from [DASHBOARD].[dbo].[lcc_dashboard_rounds_step1] b
										group by b.entidad_SRonda) b
								where a.Entidad_SRonda=b.Entidad_SRonda and a.id = b.MaxId
							)c
						where a.Entidad_SRonda=b.entidad_SRonda and a.ronda= b.ronda
						and a.Entidad_SRonda=c.entidad_SRonda'
		EXECUTE sp_executesql @SQLString
	end

	SET @SQLString =N'
				alter table [DASHBOARD].[dbo].['+@table+'_'+@group+'] drop column Entidad,Meas_date
				use [DASHBOARD]
				exec sp_rename ''dbo.'+@table+'_'+@group+'.Entidad_SRonda'',''Entidad'',''COLUMN''
				exec sp_rename ''dbo.'+@table+'_'+@group+'.Meas_date_max'',''Meas_date'',''COLUMN''
				use [master]'
	EXECUTE sp_executesql @SQLString
	set @it=@it+1
end 

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_rounds_step1'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_rounds'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre'
