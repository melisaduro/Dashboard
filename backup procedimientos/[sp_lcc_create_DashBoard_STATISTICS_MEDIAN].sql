USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_STATISTICS_MEDIAN]    Script Date: 29/05/2017 14:12:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE [master]
--GO

ALTER procedure [dbo].[sp_lcc_create_DashBoard_STATISTICS_MEDIAN] 
	@database as varchar(256)
	,@sheetTech as varchar(256)
	,@table as varchar(256)
	,@step float
	,@N_ranges int
	,@ini_range as float
	,@Code as varchar(256)
	,@last_range as bit
as

-------------------------------------------------------------------------------
-- Definición del cálculo de la mediana para una distribución

-- Una vez establecida la clase mediana (es decir, el intervalo donde la frecuencia acumulada es mayor estricto hasta la mitad de la suma de las frecuencias absolutas):
--            Mediana= L_i + (N*0.5-F_i-1)/f_i *a_i

-- L_i = límite inferior de la clase donde se encuentra la mediana
-- N/2 = semisuma de las frecuencias absolutas
-- F_i-1 = frecuencia acumulada anterior a la clase mediana
-- f_i = frecuencia absoluta de la clase mediana 
-- a_i = amplitud de la clase

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @database as varchar(256) = '[DASHBOARD]'
--declare @sheetTech as varchar(256)	= '' -- or '_CE' '_NC' '_NC_LTE'
--declare @table as varchar(256) = 'lcc_aggr_sp_MDD_Data_Ping_step2'
--declare @step float= 5
--declare @N_ranges int=26
--declare @Code varchar (256)='Ms'
--declare @ini_range as float=0
--declare @percentil as float=0.95
--declare @last_range as bit=1

declare @i int =0
declare @field as varchar(256)
DECLARE @SQLString nvarchar(4000)
declare @aggr as varchar(256)
-------------------------------------------------------------------------------
-- Creación de la tabla transpuesta

-- Se crea la estructura de la tabla con los campos base
set @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose_step1''
				Create table [DASHBOARD].[dbo].['+@table+'_transpose_step1](
						mnc varchar(256),
						entidad varchar(256),
						Meas_Date varchar(256),
						Aggr float,
						id int,
						Range_inf float
						)'
EXECUTE sp_executesql @SQLString

-- Se insertan las filas por rangos (teniendo en cuenta el paso del histograma y el número total de rangos)
while @i< @N_ranges -1
begin
	if @step*@i = 0
		set @field=convert(varchar,@ini_range)+ '-' + convert(varchar,@step+@ini_range)
	else set @field= convert(varchar,@step*@i+@ini_range) + '-' + convert(varchar,@step*(@i+1)+@ini_range)

	if @Code in ('NB','WB')
		set @field=@field+' '
	else if @Code in ('Mbps','Ms')
		set @field= ' '+@field
	else if @Code in ('overall')
		set @field= @field+' '
	else set @field= ' '+@field+' '

	-- Para el caso de voz Aggr_overall hay que sumar dos campos
	if @Code <> 'overall'
		set @aggr ='sum(['+@field+@Code+'])'
	else 
		set @aggr ='sum(['+@field+'WB]) + sum(['+@field+'NB])'
	
	set @SQLString= N'
			declare @Code as varchar(256)=''' +@Code + '''
			insert into [DASHBOARD].[dbo].['+@table+'_transpose_step1]
			select mnc,entidad,Meas_Date
					,'+@aggr+' as Aggr
					,'+ convert(varchar,@i) + ' as id
					,' +convert(varchar,((@i*@step*1.0)+@ini_range))+' as Range_inf
			from '+ @database + '.[dbo].['+@table+']
			group by mnc,Meas_Date,entidad
			order by id'
	set @i=@i+1
	EXECUTE sp_executesql @SQLString
end

-- Se añade el último rango
if @last_range= 1
begin
	if @Code in ('Mbps','Ms')
		set @field=' >' + convert(varchar,@step*(@N_ranges-1))
	else set @field=' >' + convert(varchar,@step*(@N_ranges-1))+' '
	set @SQLString= N'
					insert into [DASHBOARD].[dbo].['+@table+'_transpose_step1]
					select mnc,entidad,Meas_Date
							,sum(['+@field+@Code+']) as Aggr
							,' + convert(varchar,@N_ranges-1) + ' as id
							,' +convert(varchar,(@ini_range+@step*1.0*(@N_ranges-1)))+' as Range_inf
					from '+ @database + '.[dbo].['+@table+']
					group by mnc,Meas_Date,entidad
					order by id'
	EXECUTE sp_executesql @SQLString
end
else
begin
	set @field= convert(varchar,@step*(@N_ranges-1)+@ini_range) + '-' + convert(varchar,@step*(@N_ranges)+@ini_range)
	if @Code in ('NB','WB')
		set @field=@field+' '
	else if @Code in ('Mbps','Ms')
		set @field= ' '+@field
	else if @Code in ('overall')
		set @field= @field+' '
	else set @field= ' '+@field+' '

	-- Para el caso de voz Aggr_overall hay que sumar dos campos
	if @Code <> 'overall'
		set @aggr ='sum(['+@field+@Code+'])'
	else 
		set @aggr ='sum(['+@field+'WB]) + sum(['+@field+'NB])'

	set @SQLString= N'
			insert into [DASHBOARD].[dbo].['+@table+'_transpose_step1]
			select mnc,entidad,Meas_Date
					,'+@aggr+' as Aggr
					,'+convert(varchar,@N_ranges-1)+' as id
					,'+convert(varchar,@ini_range+@step*(@N_ranges-1))+' as range_inf
			from '+ @database + '.[dbo].['+@table+']
			group by mnc,Meas_Date,entidad
			order by id'
	EXECUTE sp_executesql @SQLString
end

-------------------------------------------------------------------------------
-- Cálculo de la mediana
-- Se añaden los campos calculados CDF y total
set @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose''
				select a.entidad,a.mnc,a.Meas_Date,a.id,a.Range_inf,a.Aggr,
					1.0*(select sum(b.Aggr) 
						from [DASHBOARD].[dbo].['+@table+'_transpose_step1] b
						where b.entidad=a.entidad and b.mnc=a.mnc and b.Meas_Date=a.Meas_Date and b.id<=a.id) as CDF,
					nullif((select sum(b.Aggr) 
						from [DASHBOARD].[dbo].['+@table+'_transpose_step1] b
						where b.entidad=a.entidad and b.mnc=a.mnc and b.Meas_Date=a.Meas_Date),0) as total
				into [DASHBOARD].[dbo].['+@table+'_transpose]
				from [DASHBOARD].[dbo].['+@table+'_transpose_step1] a
				group by a.mnc,a.entidad,a.Meas_Date,a.id,a.Range_inf,a.Aggr
				order by a.entidad,a.mnc,a.id'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Se identifica cuál es la clase mediana
if @Code in ('Mbps')
begin
	set @SQLString= N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_MEDIAN_'+@sheetTech+'_step1''
					select a.entidad, a.mnc, a.Meas_Date,a.id
					into [DASHBOARD].[dbo].[lcc_MEDIAN_'+@sheetTech+'_step1]
					from [DASHBOARD].[dbo].['+@table+'_transpose] a,
						(select entidad,mnc,Meas_Date,id,Range_inf,total/2 as SSum,CDF	
						from [DASHBOARD].[dbo].['+@table+'_transpose]
						where CDF>total/2) b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
					group by a.entidad, a.mnc, a.Meas_Date,a.id  
					having a.id=min(b.id)'
end
else
begin
		set @SQLString= N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_MEDIAN_'+@sheetTech+'_step1''
					select a.entidad, a.mnc, a.Meas_Date,a.id
					into [DASHBOARD].[dbo].[lcc_MEDIAN_'+@sheetTech+'_step1]
					from [DASHBOARD].[dbo].['+@table+'_transpose] a,
						(select entidad,mnc,Meas_Date,id,Range_inf,total/2 as SSum,CDF	
						from [DASHBOARD].[dbo].['+@table+'_transpose]
						where CDF>=total/2) b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
					group by a.entidad, a.mnc, a.Meas_Date,a.id  
					having a.id=min(b.id)'
end
EXECUTE sp_executesql @SQLString

-- Se realiza el cáculo de la mediana
set @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_MEDIAN_'+@sheetTech+'''
				select a.*,
					a.Range_inf+((a.total*0.5)-(a.CDF-a.Aggr))*'+convert(varchar,@step)+'/a.Aggr as Median
				into [DASHBOARD].[dbo].[lcc_Statistics_MEDIAN_'+@sheetTech+']
				from [DASHBOARD].[dbo].['+@table+'_transpose] a,
					[DASHBOARD].[dbo].[lcc_MEDIAN_'+@sheetTech+'_step1] b
				where a.id=b.id and a.entidad=b.entidad and a.mnc =b.mnc and a.Meas_Date=b.Meas_Date'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
set @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_MEDIAN_'+@sheetTech+'_step1''' +
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose''' +
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose_step1'''
EXECUTE sp_executesql @SQLString
