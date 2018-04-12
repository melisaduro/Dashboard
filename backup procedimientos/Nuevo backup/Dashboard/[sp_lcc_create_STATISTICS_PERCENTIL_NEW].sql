USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_STATISTICS_PERCENTIL_NEW]    Script Date: 13/11/2017 10:57:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_STATISTICS_PERCENTIL_NEW] 
	@table as varchar(256)
	,@tableRdo as varchar(256)
	,@step as float
	,@N_ranges as int
	,@ini_range as float
	,@percentil as float
as

-------------------------------------------------------------------------------
-- Definición del cálculo del percentil para una distribución

-- Una vez establecida la clase en la que se encuentra el percentil (es decir, 
-- el intervalo cuya frecuencia acumulado es mayor estricto que K*N/100, siendo K=1,2..99 el percentil a calcular):
--            Percentil= L_i + (K*N/100-F_i-1)/f_i *a_i

-- L_i = límite inferior de la clase donde se encuentra el percentil
-- N = suma de las frecuencias absolutas
-- F_i-1 = frecuencia acumulada anterior a la clase donde se encuentra el percentil
-- f_i = frecuencia absoluta de la clase percentil
-- a_i = amplitud de la clase
-- K = percentil a calcular

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @table as varchar(256) = '_tmp_Percentiles'
--declare @step float= 5
--declare @N_ranges int=41
--declare @ini_range as float=0
--declare @percentil as float=0.5



declare @i int =0
declare @field as varchar(256)
DECLARE @SQLString nvarchar(4000)
declare @aggr as varchar(256)

-------------------------------------------------------------------------------
-- Creación de la tabla transpuesta

-- Se crea la estructura de la tabla con los campos base, sacamos el percentil por cada agrupacion de:
-- mnc=operador
-- entidad= entidad o scope de entidades
-- report_type= tipo de reporte
set @SQLString= N'
				exec sp_lcc_dropifexists '''+@table+'_transpose_step1''
				Create table ['+@table+'_transpose_step1](
						mnc varchar(256), 
						entidad varchar(256),
						[Database] varchar(256),
						Test_type [varchar](255),
						Aggr float,
						id int,
						range_inf float
						)'
EXECUTE sp_executesql @SQLString

-- Se insertan las filas por rangos (teniendo en cuenta el paso del histograma y el número total de rangos)
while @i<= @N_ranges -1
begin	
	set @SQLString= N'
			insert into ['+@table+'_transpose_step1]
			select mnc,entity_name,[Database],Testtype
					,sum(['+convert(varchar,(@i+1))+']) as Aggr
					,'+convert(varchar,@i)+' as id
					,'+convert(varchar,@ini_range+@step*@i)+' as range_inf
			from ['+@table+']
			group by mnc,entity_name,[Database],Testtype
			order by id'
	
	set @i=@i+1
	--print @SQLString
	EXECUTE sp_executesql @SQLString
end

---------------------------------------------------------------------------------
-- Cálculo de percentiles
-- Se añaden los campos calculados CDF y total
set @SQLString= N'			
				exec sp_lcc_dropifexists '''+@table+'_transpose''
				select a.entidad,a.mnc,a.[Database],a.Test_type,a.id,a.range_inf, a.aggr,
					1.0*(select sum(b.aggr) 
						from ['+@table+'_transpose_step1] b
						where b.entidad=a.entidad and b.mnc=a.mnc and b.[Database]=a.[Database] and b.Test_type=a.Test_type and b.id<=a.id
					) as CDF,
					nullif((select sum(b.aggr) 
						from ['+@table+'_transpose_step1] b
						where b.entidad=a.entidad and b.mnc=a.mnc and b.[Database]=a.[Database] and b.Test_type=a.Test_type
					),0) as total
				into ['+@table+'_transpose]
				from ['+@table+'_transpose_step1] a
				group by a.mnc,a.entidad,a.[Database],a.Test_type,a.id,a.range_inf,a.aggr
				order by a.entidad,a.mnc,a.id'
EXECUTE sp_executesql @SQLString
exec ('select * from ['+@table+'_transpose]')
-- Se identifica el percentil a calcular
set @SQLString= N'		
				exec sp_lcc_dropifexists ''lcc_PERCENTIL_step1''
				select a.entidad, a.mnc, a.[Database],a.Test_type,a.id
				into [lcc_PERCENTIL_step1]
				from ['+@table+'_transpose] a,
					(select entidad,mnc,[Database],Test_type,id,range_inf,total*'+convert(varchar,@percentil)+' as SSum,CDF	
						from ['+@table+'_transpose]
						where CDF>=total*'+convert(varchar,@percentil)+'
					) b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.[Database]=b.[Database] and b.Test_type=a.Test_type
				group by a.entidad, a.mnc, a.[Database],a.Test_type,a.id  
				having a.id=min(b.id)'
EXECUTE sp_executesql @SQLString
exec ('select * from [lcc_PERCENTIL_step1]')
-- Se calculan el percentil correspondiente
set @SQLString= N'
				insert into '+@tableRdo+'
				select a.entidad, a.mnc, a.[Database],a.Test_type
					,'+convert(varchar,@percentil)+'
					,a.range_inf+((a.total*'+convert(varchar,@percentil)+')-(a.CDF-a.Aggr))*'+convert(varchar,@step*1)+'/a.Aggr as Resultado_Percentil
				from ['+@table+'_transpose] a,
					[lcc_PERCENTIL_step1] b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.[Database]=b.[Database] and b.Test_type=a.Test_type and a.id=b.id'
EXECUTE sp_executesql @SQLString


--set @SQLString= N'
--			select * from  ['+@table+'_transpose_step1]'
--EXECUTE sp_executesql @SQLString
--set @SQLString= N'
--			select * from  ['+@table+'_transpose]'
--EXECUTE sp_executesql @SQLString
--set @SQLString= N'
--			select * from  lcc_PERCENTIL_step1'
--EXECUTE sp_executesql @SQLString
---------------------------------------------------------------------------------
-- Limpieza de tablas temporales
set @SQLString= N'
				exec sp_lcc_dropifexists '''+@table+'_transpose_step1''' +
				' exec sp_lcc_dropifexists '''+@table+'_transpose'''	+
				' exec sp_lcc_dropifexists ''lcc_PERCENTIL_step1'''
EXECUTE sp_executesql @SQLString


--truncate table _tmp_Resultados_Percentiles
--select * from _tmp_Resultados_Percentiles
